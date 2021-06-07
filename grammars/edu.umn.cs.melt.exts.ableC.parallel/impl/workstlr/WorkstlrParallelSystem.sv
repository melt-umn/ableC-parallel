grammar edu:umn:cs:melt:exts:ableC:parallel:impl:workstlr;

abstract production workstlrParallelSystem
top::ParallelSystem ::= 
{
  top.parName = "workstlr";

  top.fSpawn = workstlrSpawn;
  top.fFor = workstlrParFor;
  top.newProd = just(\a::Exprs l::Location -> workstlrParallelNew(a, location=l));
  top.deleteProd = just(workstlrParallelDelete);
}

aspect production systemNumbering
top::SystemNumbering ::=
{
  systems <- [workstlrParallelSystem()];
}

abstract production workstlrSpawn
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
    then [err(e.location, "Workstlr spawns do not currently support this type of expression")]
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
          then [err(loc, "Workstlr spawns cannot currently ignore the result of the function")]
          else []
        | _ -> [err(e.location, "Attempted to call a value of non-function type")]
        end
      end);
  
  local anntWarnings :: [Message] =
    if !null(annts.privates) || !null(annts.publics) || !null(annts.globals)
    then [wrn(loc, "public/private/global annotations on workstlr spawn ignored")]
    else [];

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
    s"__${fName}_interface_${substitute(":", "_", substitute(".", "_", loc.unparse))}_u${toString(genInt())}";

  local closureDecl :: Decl =
    maybeValueDecl(liftedName ++ "_closure",
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
    });
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
      if retVoid then ableC_Expr { (struct workstlr_closure*) __closure } :: []
        else (ableC_Expr { &(__closure->frame.res) }
          :: ableC_Expr { (struct workstlr_closure*) __closure } :: [])
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
    maybeValueDecl(liftedName ++ "_closure",
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
          workstlr_push_head(workstlr_thread_deque, __closure);
          $Stmt{if retVoid
            then ableC_Stmt { $name{s"__${fName}_fast"}($Exprs{callArgs}); }
            else ableC_Stmt {
              res = $name{s"__${fName}_fast"}($Exprs{callArgs});
              __closure->frame.res = res;
            } }
          int counter = --(__closure->joinCounter);

          if (workstlr_verify_pop_head(workstlr_thread_deque, __closure) == 0) {
            if (counter < 0) {
              workstlr_push_head(workstlr_thread_deque, __closure);
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
    });

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
        struct workstlr_system* _workstlr_info =
          (struct workstlr_system*) _sys_info->system_data;

        // TODO: Can we choose a deque in some better way?
        workstlr_push_tail(&(_workstlr_info->deques[0]), __closure);
      }
    };

  forwards to 
    if !null(localErrors)
    then warnStmt(localErrors)
    else
      injectGlobalDeclsStmt(
        consDecl(closureDecl, consDecl(interfaceDecl, nilDecl())),
        seqStmt(warnStmt(anntWarnings), fwrdStmt)
      );
}

abstract production workstlrParFor
top::Stmt ::= loop::Stmt loc::Location annts::ParallelAnnotations
{
  top.pp = ppConcat([text("parallel"), space(), loop.pp]);
  top.functionDefs := [];
  top.labelDefs := [];

  local privateVars :: [Name] = nub(annts.privates);
  local publicVars  :: [Name] = nub(annts.publics);
  local globalVars  :: [Name] = nub(annts.globals);

  local localErrors :: [Message] = loop.errors ++ annts.errors ++ missingVars;

  local liftedName :: String =
    s"__lifted_workstlr_parallel_${substitute(":", "_", substitute(".", "_", loc.unparse))}_u${toString(genInt())}";
  
  local freeVars :: [Name] = nub(loop.freeVariables);

  local freePublic  :: [Name] = intersect(freeVars, publicVars);
  local freePrivate :: [Name] = intersect(freeVars, privateVars);
  local freeGlobal  :: [Name] = intersect(freeVars, globalVars);

  -- It's an error if any of the elements in freeGlobal is NOT a global
  -- variable
  local globalenvr :: Decorated Env = globalEnv(top.env);
  local missingVars :: [Message] =
    flatMap(
      \n :: Name ->
        if contains(n, freePublic) || contains(n, freePrivate)
        then []
        else if contains(n, freeGlobal)
        then
          if null((decorate n with {env=globalenvr;}).valueLookupCheck)
          then []
          else [err(loc, s"Variable '${n.name}' used in parallel-for is given a global annotation but is not a global variable")]
        else [err(loc, s"Variable '${n.name}' used in parallel-for not given a public/private/global annotation")],
      freeVars);

  local publicVarTypes :: [Type] = map(
    \n::Name ->
      pointerType(
        nilQualifier(),
        (decorate n with {env=top.env;}).valueItem.typerep
      ),
    freePublic);
  local privateVarTypes :: [Type] = map(
    \n::Name ->
      (decorate n with {env=top.env;}).valueItem.typerep,
    freePrivate);

  local structItemNames :: [Name] = freePublic ++ freePrivate;
  local structItemTypes :: [Type] = publicVarTypes ++ privateVarTypes;
  local structItemInits :: [Expr] =
    map(\n::Name -> ableC_Expr{&$Name{n}}, freePublic)
    ++ map(\n::Name -> ableC_Expr{$Name{n}}, freePrivate);

  local structItems :: [StructItem] =
    map(\p::Pair<Name Type> ->
        structItem(nilAttribute(), p.snd.baseTypeExpr,
          consStructDeclarator(
            structField(p.fst, p.snd.typeModifierExpr, nilAttribute()),
            nilStructDeclarator()
          )
        ),
      zipWith(pair, structItemNames, structItemTypes));
  local struct :: StructDecl =
    structDecl(
      consAttribute(
        gccAttribute(
          consAttrib(
            appliedAttrib(
              attribName(name("refId", location=loc)),
              consExpr(
                mkStringConst("edu:umn:cs:melt:exts:ableC:parallel:impl:workstlr:input" ++ liftedName, loc),
                nilExpr()
              )
            ),
            nilAttrib()
          )
        ),
        nilAttribute()),
      justName(name(liftedName ++ "_struct", location=loc)),
      foldStructItem(structItems), location=loc);
  local structDcl :: Decl =
    typeExprDecl(nilAttribute(), structTypeExpr(nilQualifier(), struct));

  structDcl.controlStmtContext = initialControlStmtContext;
  structDcl.isTopLevel = true;
  structDcl.env = globalEnv(top.env);

  local globalEnvStruct :: Decorated Env =
    addEnv(
      structDcl.defs,
      globalEnv(top.env)
    );
  local transformedEnv :: Decorated Env =
    addEnv(
      valueDef("args",
        declaratorValueItem(
          decorate declarator(
            name("args", location=loc),
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
              extType(nilQualifier(),
                refIdExtType(
                  structSEU(),
                  just(liftedName ++ "_struct"),
                  "edu:umn:cs:melt:exts:ableC:parallel:impl:workstlr:input" ++ liftedName
                )
              );
            env = globalEnvStruct;
          }
        )
      )
      ::
      map(
        \n::Name ->
          valueDef(n.name,
            declaratorValueItem(
              decorate declarator(
                n,
                baseTypeExpr(),
                nilAttribute(),
                nothingInitializer()
              ) with {
                typeModifierIn = baseTypeExpr();
                controlStmtContext = initialControlStmtContext;
                isTypedef = false;
                isTopLevel = false;
                givenStorageClasses = nilStorageClass();
                givenAttributes = nilAttribute();
                baseType = extType(nilQualifier(), fakePublicForLift());
                env = globalEnvStruct;
              }
            )
          ),
        freePublic
      )
      ++
      map(
        \n::Name ->
          valueDef(n.name,
            declaratorValueItem(
              decorate declarator(
                n,
                baseTypeExpr(),
                nilAttribute(),
                nothingInitializer()
              ) with {
                typeModifierIn = baseTypeExpr();
                controlStmtContext = initialControlStmtContext;
                isTypedef = false;
                isTopLevel = false;
                givenStorageClasses = nilStorageClass();
                givenAttributes = nilAttribute();
                baseType = extType(nilQualifier(), fakePrivateForLift());
                env = globalEnvStruct;
              }
            )
          ),
        freePrivate
      ),
      openScopeEnv(
        globalEnvStruct
      )
    );

  local transformedLoop :: Stmt =
    (decorate loop with {env=transformedEnv;
                controlStmtContext=initialControlStmtContext;}).forLift;
  transformedLoop.env = transformedEnv;
  transformedLoop.controlStmtContext = initialControlStmtContext;

  local loopDesc :: (Decl, MaybeExpr, Expr, Stmt) =
    case transformedLoop of
    | ableC_Stmt { for ($Decl{decl} $Expr{cond}; $Expr{iter}) $Stmt{body} }
        -> (decl, justExpr(cond), iter, cleanStmt(body, transformedEnv))
    | _ -> error("Only invoked when the loop is of this form")
    end;
  local workstlrFunction :: Decl =
    workstlrParFunctionConverter(
      cilkFunctionDecl(
        nilStorageClass(), nilSpecialSpecifier(),
        builtinTypeExpr(nilQualifier(), signedType(intType())),
        functionTypeExprWithArgs(
          baseTypeExpr(),
          consParameters(
            parameterDecl(
              nilStorageClass(),
              extTypeExpr(nilQualifier(),
                refIdExtType(
                  structSEU(),
                  just(liftedName ++ "_struct"),
                  "edu:umn:cs:melt:exts:ableC:parallel:impl:workstlr:input" ++ liftedName
                )
              ),
              pointerTypeExpr(nilQualifier(), baseTypeExpr()),
              justName(name("args", location=loc)),
              nilAttribute()
            ),
            nilParameters()
          ),
          false,
          nilQualifier()
        ),
        name(liftedName, location=loc),
        nilAttribute(),
        nilDecl(),
        ableC_Stmt {
          // Loop
          $Stmt{parallelFor(loopDesc.1, loopDesc.2, loopDesc.3, loopDesc.4, 
            nilParallelAnnotations())}

          // Sync
          $Stmt{syncTask(nilExpr())}

          free(args);
          return 0;
        }
      )
    );
  
  local spawnAnnts :: SpawnAnnotations =
    annts.parToSpawnAnnts.dropShareAnnotations;
  local fwrdStmt :: Stmt =
    ableC_Stmt {
      {
        struct $name{liftedName ++ "_struct"}* args =
          malloc(sizeof(struct $name{liftedName ++ "_struct"}));
        $Stmt{foldStmt(map(
          \p::Pair<Name Expr> ->
            ableC_Stmt {
              args->$Name{p.fst} = $Expr{p.snd};
            },
          zipWith(pair, structItemNames, structItemInits)))}

        int __tmp;
        $Stmt{workstlrSpawn(
          ableC_Expr {
            __tmp = $name{liftedName}(args)
          },
          loc,
          spawnAnnts
        )}
      }
    };

  forwards to
    if !null(localErrors)
    then warnStmt(localErrors)
    else
      injectGlobalDeclsStmt(
        consDecl(structDcl, consDecl(workstlrFunction, nilDecl())),
        fwrdStmt
      );
}

abstract production workstlrParallelNew
top::Expr ::= args::Exprs
{
  local localErrors :: [Message] =
    args.errors
    ++
    case args of
    | consExpr(e, nilExpr()) when e.typerep.isIntegerType -> []
    | _ -> [err(top.location, "Workstlr Parallel system should be initialized with one integer argument")]
    end;
  
  top.pp = ppConcat([text("new workstlr parallel"), 
    parens(ppImplode(text(", "), args.pps))]);

  local nmbrg::SystemNumbering = systemNumbering();
  nmbrg.lookupParName = "workstlr";

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
            $stringLiteralExpr{s"Attempted to create a workstlr system with a non-positive number of threads (${top.location.unparse})\n"});
          exit(-1);
        }

        struct __ableC_system_info* _res =
          start_workstlr_system(_num_threads, $intLiteralExpr{sysIndex});

        if (__builtin_expect(_res == (void*) 0, 0)) {
          fprintf(stderr, 
            $stringLiteralExpr{s"Failed to start a workstlr system (${top.location.unparse})\n"});
          exit(-1);
        }

        _res;
      })
    };
}

abstract production workstlrParallelDelete
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
          stop_workstlr_system(_sys);
        }
      };
}
