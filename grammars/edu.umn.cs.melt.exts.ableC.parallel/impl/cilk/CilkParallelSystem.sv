grammar edu:umn:cs:melt:exts:ableC:parallel:impl:cilk;

abstract production cilkParallelSystem
top::ParallelSystem ::= 
{
  top.parName = "cilk";

  top.fSpawn = cilkSpawn;
  top.fFor = cilkParFor;
  top.newProd = just(\a::Exprs l::Location -> cilkParallelNew(a, location=l));
  top.deleteProd = just(cilkParallelDelete);
}

aspect production systemNumbering
top::SystemNumbering ::=
{
  systems <- [cilkParallelSystem()];
}

abstract production cilkSpawn
top::Stmt ::= e::Expr loc::Location annts::SpawnAnnotations
{
  top.pp = ppConcat([text("spawn"), e.pp, semi()]);
  top.functionDefs := [];
  top.labelDefs := [];

  local sys :: Expr = annts.bySystem.fromJust;
  sys.env = top.env;
  sys.controlStmtContext = top.controlStmtContext;

  local threads :: [Expr] = annts.asThreads;
  local groups :: [Expr] = annts.inGroups;

  local localErrors :: [Message] = annts.errors ++ e.errors ++ 
    (if !validForm
    then [err(e.location, "Cilk spawns do not currently support this type of expression")]
    else 
      let lookupErrs :: [Message] =
        (decorate name(s"__${fName}_fast", location=loc) with {env=top.env;}).valueLookupCheck
      in
      if !null(lookupErrs)
      then lookupErrs
      else case valType of 
        | functionType(_, _, _) -> 
          if retVoid && hasLhs
          then [err(loc, "Cannot assign the result of a void function")]
          else if !retVoid && !hasLhs
          then [err(loc, "Cilk spawns cannot currently ignroe the result of the function")]
          else []
        | _ -> [err(e.location, "Attempted to call a value of non-function type")]
        end
      end)
    ++
    (if !null(annts.privates) || !null(annts.publics) || !null(annts.globals)
    then [err(e.location, "Cilk spawns do not currently support public/private/global annotations")]
    else []);

  local validForm :: Boolean =
    case e of
    | directCallExpr(_, _) -> true
    | ovrld:eqExpr(_, directCallExpr(_, _)) -> true
    | ovrld:addEqExpr(_, directCallExpr(_, _)) -> true
    | ovrld:subEqExpr(_, directCallExpr(_, _)) -> true
    | ovrld:mulEqExpr(_, directCallExpr(_, _)) -> true
    | ovrld:divEqExpr(_, directCallExpr(_, _)) -> true
    | ovrld:modEqExpr(_, directCallExpr(_, _)) -> true
    | _ -> false
    end;

  local fName :: String =
    case e of
    | directCallExpr(nm, _) -> nm.name
    | ovrld:eqExpr(_, directCallExpr(nm, _)) -> nm.name
    | ovrld:addEqExpr(_, directCallExpr(nm, _)) -> nm.name
    | ovrld:subEqExpr(_, directCallExpr(nm, _)) -> nm.name
    | ovrld:mulEqExpr(_, directCallExpr(nm, _)) -> nm.name
    | ovrld:divEqExpr(_, directCallExpr(nm, _)) -> nm.name
    | ovrld:modEqExpr(_, directCallExpr(nm, _)) -> nm.name
    | _ -> error("Invalid forms reported via errors attribute")
    end;

  local valType :: Type = 
    (decorate ableC_Expr{$name{s"__${fName}_fast"}} 
      with {env=top.env; controlStmtContext=initialControlStmtContext;}).typerep;

  local funcReturnType :: Type =
    case valType of
    | functionType(res, _, _) -> res
    | _ -> error("Bad types report via errors attributes")
    end;
  local retVoid :: Boolean = 
    case funcReturnType of 
    | builtinType(_, voidType()) -> true 
    | _ -> false
    end;

  local hasLhs :: Boolean =
    case e of
    | directCallExpr(_, _) -> false
    | ovrld:eqExpr(_, _) -> true
    | ovrld:addEqExpr(_, _) -> true
    | ovrld:subEqExpr(_, _) -> true
    | ovrld:mulEqExpr(_, _) -> true
    | ovrld:divEqExpr(_, _) -> true
    | ovrld:modEqExpr(_, _) -> true
    | _ -> error("Invalid forms reported via errors attribute")
    end;
  local lhs :: Expr =
    case e of
    | ovrld:eqExpr(lhs, _) -> lhs
    | ovrld:addEqExpr(lhs, _) -> lhs
    | ovrld:subEqExpr(lhs, _) -> lhs
    | ovrld:mulEqExpr(lhs, _) -> lhs
    | ovrld:divEqExpr(lhs, _) -> lhs
    | ovrld:modEqExpr(lhs, _) -> lhs
    | _ -> error("To referenced if does not have lhs")
    end;

  local args :: Exprs =
    case e of
    | directCallExpr(_, a) -> a
    | ovrld:eqExpr(_, directCallExpr(_, a)) -> a
    | ovrld:addEqExpr(_, directCallExpr(_, a)) -> a
    | ovrld:subEqExpr(_, directCallExpr(_, a)) -> a
    | ovrld:mulEqExpr(_, directCallExpr(_, a)) -> a
    | ovrld:divEqExpr(_, directCallExpr(_, a)) -> a
    | ovrld:modEqExpr(_, directCallExpr(_, a)) -> a
    | _ -> error("Invalid forms reported via errors attribute")
    end;

  local funcArgTypes :: [Type] =
    case valType of
    | functionType(_, protoFunctionType(ts, false), _) -> ts
    | functionType(_, noProtoFunctionType(), _) -> []
    | _ -> error("Invalid forms reported via errors attribute")
    end;
    
  -- If the return type is void we don't have the __ret pointer and so only 
  -- have the __parent pointer
  local realArgTypes :: [Type] =
    take(length(funcArgTypes) - (if retVoid then 1 else 2), funcArgTypes);
  
  local inputStructNames :: [Name] =
    (if retVoid
    then []
    else [name("__returnTo", location=loc)])
    ++
    map(\i::Integer -> name(s"__arg_${toString(i)}", location=loc),
      range(0, length(realArgTypes)))
    ++ 
    map(\i::Integer -> name(s"__thread_${toString(i)}", location=loc),
      range(0, length(threads)))
    ++
    map(\i::Integer -> name(s"__group_${toString(i)}", location=loc),
      range(0, length(groups)));
  local inputStructTypes :: [Type] =
    (if retVoid
    then []
    else [pointerType(nilQualifier(), funcReturnType)])
    ++
    realArgTypes
    ++
    map(
      \e::Expr ->
        getPointerType(
          (decorate e with {env=top.env;
                          controlStmtContext=initialControlStmtContext;}).typerep
        ),
      threads ++ groups);
  local inputStructInits :: [Expr] =
    (if retVoid
    then []
    else [ableC_Expr { &($Expr{lhs}) }] )
    ++
    args.exprList
    ++
    map(\e::Expr ->
      getReference(decorate e with {env=top.env;
                  controlStmtContext=initialControlStmtContext;}),
      threads ++ groups);

  local inputStructItems :: StructItemList =
    foldr(consStructItem, nilStructItem(),
      map(\p::Pair<Name Type> ->
        structItem(nilAttribute(), p.snd.baseTypeExpr,
          consStructDeclarator(
            structField(p.fst, p.snd.typeModifierExpr, nilAttribute()),
            nilStructDeclarator()
          )
        ),
        zipWith(pair, inputStructNames, inputStructTypes)
      )
    );

  local liftedName :: String =
    s"__${fName}_interface_${substitute(":", "_", substitute(".", "_", loc.unparse))}";

  local closureDecl :: Decl =
    ableC_Decl {
      struct $name{liftedName ++ "_closure"} {
        void (*func)(void*);
        _Atomic int joinCounter;
        int state;
        struct $name{liftedName ++ "_closure_input"} {
          $StructItemList{inputStructItems}
        } input;
        struct $name{liftedName ++ "_closure_frame"} {
          $StructItemList{if retVoid then nilStructItem()
            else consStructItem(
              structItem(nilAttribute(), funcReturnType.baseTypeExpr,
                consStructDeclarator(
                  structField(name("res", location=loc),
                    funcReturnType.typeModifierExpr, nilAttribute()),
                  nilStructDeclarator()
                )
              ),
              nilStructItem()
            )}
        } frame;
      };
    };
  closureDecl.controlStmtContext = initialControlStmtContext;
  closureDecl.isTopLevel = true;
  closureDecl.env = globalEnv(top.env);

  local globalEnvStruct :: Decorated Env =
    addEnv(closureDecl.defs, globalEnv(top.env));
  local interfaceEnv :: Decorated Env =
    addEnv(
      valueDef("__closure",
        declaratorValueItem(
          decorate declarator(
            name("__closure", location=loc),
            pointerTypeExpr(nilQualifier(), baseTypeExpr()),
            nilAttribute(),
            nothingInitializer()
          ) with {
            typeModifierIn = baseTypeExpr();
            controlStmtContext = initialControlStmtContext;  
            isTypedef = false;
            isTopLevel = false;
            givenStorageClasses = nilStorageClass();
            givenAttributes = nilAttribute();
            baseType =
              (decorate ableC_Expr { ({ struct $name{liftedName ++ "_closure"} res; res; }) }
                with {env=globalEnvStruct; controlStmtContext=initialControlStmtContext;
                    }).typerep;
            env = globalEnvStruct;
          }
        )
      ) :: [],
      openScopeEnv(
        globalEnvStruct
      )
    );

  local callArgs :: Exprs =
    foldr(consExpr, nilExpr(), 
      map(\i::Integer -> ableC_Expr{__closure->input.$name{s"__arg_${toString(i)}"}},
        range(0, length(realArgTypes)))
      ++
      if retVoid then ableC_Expr { (struct cilk_closure*) __closure } :: []
        else (ableC_Expr { &(__closure->frame.res) }
          :: ableC_Expr { (struct cilk_closure*) __closure } :: [])
    );

  local writeBackStmt :: Stmt =
    case e of
    | directCallExpr(_, _) -> nullStmt()
    | ovrld:eqExpr(_, directCallExpr(_, _)) -> ableC_Stmt{ *(__closure->input.__returnTo)=res;}
    | ovrld:addEqExpr(_, directCallExpr(_, _)) -> ableC_Stmt{ *(__closure->input.__returnTo)+=res;}
    | ovrld:subEqExpr(_, directCallExpr(_, _)) -> ableC_Stmt{ *(__closure->input.__returnTo)-=res;}
    | ovrld:mulEqExpr(_, directCallExpr(_, _)) -> ableC_Stmt{ *(__closure->input.__returnTo)*=res;}
    | ovrld:divEqExpr(_, directCallExpr(_, _)) -> ableC_Stmt{ *(__closure->input.__returnTo)/=res;}
    | ovrld:modEqExpr(_, directCallExpr(_, _)) -> ableC_Stmt{ *(__closure->input.__returnTo)%=res;}
    | _ -> error("Invalid forms reported via errors attribute")
    end;

  {- The interface function is equivalent to:
   - Setup (for threads and groups)
   - T res = spawn func(args);
   - sync;
   - Return value
   - Cleanup (for threads and groups)
   -}
  local interfaceDecl :: Decl =
    ableC_Decl {
      void $name{liftedName}(void* arg) {
        struct $name{liftedName ++ "_closure"}* __closure = arg;
        
        switch (__closure->state) {
          case 0: goto $name{liftedName ++ "_state0"};
          case 1: goto $name{liftedName ++ "_state1"};
          case 2: goto $name{liftedName ++ "_state2"};
          default: exit(100);
        }

        $name{liftedName ++ "_state0"}: ;
        
        // Setup
        $Stmt{foldStmt(
          map(
            \p::Pair<Integer Expr> ->
              case decorate p.snd with {env=top.env;
                      controlStmtContext=initialControlStmtContext;}.typerep of
              | extType(_, threadType(s)) -> 
                  (decorate s with {env=interfaceEnv; 
                    threads=[ableC_Expr{__closure->input.$name{s"__thread_${toString(p.fst)}"}}];
                  }).threadThrdOps
              | _ -> error("Invalid forms reported via errors attribute")
              end,
            zipWith(pair, range(0, length(threads)), threads)
          )
          ++
          map(
            \p::Pair<Integer Expr> ->
              case decorate p.snd with {env=top.env;
                      controlStmtContext=initialControlStmtContext;}.typerep of
              | extType(_, groupType(s)) ->
                  (decorate s with {env=interfaceEnv;
                    groups=[ableC_Expr{__closure->input.$name{s"__group_${toString(p.fst)}"}}];
                  }).groupThrdOps
              | _ -> error("Invalid forms reported via errors attribute")
              end,
            zipWith(pair, range(0, length(groups)), groups)
          )
        )}

        // T res;
        $Stmt{if retVoid then nullStmt() else ableC_Stmt{ $BaseTypeExpr{directTypeExpr(funcReturnType)} res; } }

        { // res = spawn func(args);
          __closure->joinCounter++;
          __closure->state = 1;
          cilk_push_head(cilk_thread_deque, __closure);
          $Stmt{if retVoid
            then ableC_Stmt { $name{s"__${fName}_fast"}($Exprs{callArgs}); }
            else ableC_Stmt {
              res = $name{s"__${fName}_fast"}($Exprs{callArgs});
              __closure->frame.res = res;
            } }
          int counter = --(__closure->joinCounter);

          if (cilk_verify_pop_head(cilk_thread_deque, __closure) == 0) {
            if (counter < 0) {
              cilk_push_head(cilk_thread_deque, __closure);
            }
            return;
          }

          if (0) {
            $name{liftedName ++ "_state1"}: ;
          }
        }
        { // sync;
          __closure->state = 2;
          $name{liftedName ++ "_state2"}: ;

          if (__closure->joinCounter != 0) {
            if (--(__closure->joinCounter) >= 0) {
              return; // to the scheduler
            }
          }

          $Stmt{if retVoid then nullStmt() else ableC_Stmt{res = __closure->frame.res;}}
          __closure->joinCounter = 0;
        }

        // write-back
        $Stmt{writeBackStmt}

        // tear down
        $Stmt{foldStmt(
          map(
            \p::Pair<Integer Expr> ->
              case decorate p.snd with {env=top.env;
                  controlStmtContext=initialControlStmtContext;}.typerep of
              | extType(_, threadType(s)) -> 
                  (decorate s with {env=interfaceEnv; 
                    threads=[ableC_Expr{__closure->input.$name{s"__thread_${toString(p.fst)}"}}];
                  }).threadPostOps
              | _ -> error("Invalid forms reported via errors attribute")
              end,
            zipWith(pair, range(0, length(threads)), threads)
          )
          ++
          map(
            \p::Pair<Integer Expr> ->
              case decorate p.snd with {env=top.env;
                  controlStmtContext=initialControlStmtContext;}.typerep of
              | extType(_, groupType(s)) ->
                  (decorate s with {env=interfaceEnv;
                    groups=[ableC_Expr{__closure->input.$name{s"__group_${toString(p.fst)}"}}];
                  }).groupPostOps
              | _ -> error("Invalid forms reported via errors attribute")
              end,
            zipWith(pair, range(0, length(groups)), groups)
          )
        )}

        free(__closure);
        return; // To the scheduler
      }
    };

  local fwrdStmt :: Stmt =
    ableC_Stmt {
      {
        struct $name{liftedName ++ "_closure"}* __closure =
          malloc(sizeof(struct $name{liftedName ++ "_closure"}));
        __closure->func = $name{liftedName};
        __closure->joinCounter = 0;
        __closure->state = 0;

        $Stmt{foldStmt(map(
            \p::Pair<Name Expr> ->
              ableC_Stmt {
                __closure->input.$Name{p.fst} = $Expr{p.snd};
              },
            zipWith(pair, inputStructNames, inputStructInits)))}

        $Stmt{foldStmt(
          map(
            \p::Pair<Integer Expr> -> 
              case decorate p.snd with {env=top.env;
                controlStmtContext=initialControlStmtContext;}.typerep of  
              | extType(_, threadType(s)) -> 
                  (decorate s with {env=interfaceEnv;
                    threads=[ableC_Expr{__closure->input.$name{s"__thread_${toString(p.fst)}"}}];
                  }).threadBefrOps
              | _ -> error("Invalid forms reported via errors attribute")
              end,
            zipWith(pair, range(0, length(threads)), threads)
          ) 
          ++ 
          map(
            \p::Pair<Integer Expr> -> 
              case decorate p.snd with {env=top.env;
                controlStmtContext=initialControlStmtContext;}.typerep of  
              | extType(_, groupType(s)) ->
                  (decorate s with {env=interfaceEnv;
                    groups=[ableC_Expr{__closure->input.$name{s"__group_${toString(p.fst)}"}}];
                  }).groupBefrOps
              | _ -> error("Invalid forms reported via errors attribute")
              end,
            zipWith(pair, range(0, length(groups)), groups)
          )
        )}

        struct __ableC_system_info* _sys_info =
          (struct __ableC_system_info*) $Expr{sys};
        struct cilk_system* _cilk_info =
          (struct cilk_system*) _sys_info->system_data;

        // TODO: Can we choose a deque in some better way?
        cilk_push_tail(&(_cilk_info->deques[0]), __closure);
      }
    };

  forwards to 
    if !null(localErrors)
    then warnStmt(localErrors)
    else
      injectGlobalDeclsStmt(
        consDecl(closureDecl, consDecl(interfaceDecl, nilDecl())),
        fwrdStmt
      );
}

abstract production cilkParFor
top::Stmt ::= l::Stmt loc::Location annts::ParallelAnnotations
{
  forwards to
    warnStmt([err(loc, "The Cilk system does not currently support parallel for loops")]);
}

abstract production cilkParallelNew
top::Expr ::= args::Exprs
{
  local localErrors :: [Message] =
    args.errors
    ++
    case args of
    | consExpr(e, nilExpr()) when e.typerep.isIntegerType -> []
    | _ -> [err(top.location, "Cilk Parallel system should be initialized with one integer argument")]
    end;
  
  top.pp = ppConcat([text("new cilk parallel"), 
    parens(ppImplode(text(", "), args.pps))]);

  local nmbrg::SystemNumbering = systemNumbering();
  nmbrg.lookupParName = "cilk";

  local numThreads :: Expr = case args of consExpr(e, nilExpr()) -> e 
                                | _ -> error("Invalid args reported via errors") end;
  local sysIndex :: Integer = nmbrg.parNameIndex;

  forwards to
    if !null(localErrors)
    then errorExpr(localErrors, location=top.location)
    else ableC_Expr {
      ({
        int _num_threads = $Expr{numThreads};

        if (__builtin_expect(_num_threads < 1, 0)) {
          fprintf(stderr, 
            $stringLiteralExpr{s"Attempted to create a cilk system with a non-positive number of threads (${top.location.unparse})\n"});
          exit(-1);
        }

        struct __ableC_system_info* _res =
          start_cilk_system(_num_threads, $intLiteralExpr{sysIndex});

        if (__builtin_expect(_res == (void*) 0, 0)) {
          fprintf(stderr, 
            $stringLiteralExpr{s"Failed to start a cilk system (${top.location.unparse})\n"});
          exit(-1);
        }

        _res;
      })
    };
}

abstract production cilkParallelDelete
top::Stmt ::= e::Expr
{
  top.pp = ppConcat([text("delete"), e.pp]);
  top.functionDefs := [];
  top.labelDefs := [];

  forwards to
    if !null(e.errors)
    then warnStmt(e.errors)
    else ableC_Stmt {
        {
          struct __ableC_system_info* _sys =
            (struct __ableC_system_info*) $Expr{e};
          stop_cilk_system(_sys);
        }
      };
}
