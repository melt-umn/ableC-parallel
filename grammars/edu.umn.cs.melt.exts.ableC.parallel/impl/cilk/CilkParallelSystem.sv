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

-- Spawn from outside of cilk functions
abstract production cilkSpawn
top::Stmt ::= e::Expr loc::Location annts::SpawnAnnotations
{
  top.pp = ppConcat([text("spawn"), space(), e.pp, semi()]);
  top.functionDefs := [];
  top.labelDefs := [];

  local sys :: Expr = annts.bySystem.fromJust;
  sys.env = top.env;
  sys.controlStmtContext = top.controlStmtContext;

  local threads :: [Expr] = annts.asThreads;
  local groups :: [Expr] = annts.inGroups;
  
  local validForm :: Boolean =
    case e of
    | directCallExpr(_, _) -> true
    | ovrld:eqExpr(_, directCallExpr(_, _)) -> true
    | _ -> false
    end;

  local fName :: String =
    case e of
    | directCallExpr(nm, _) -> nm.name
    | ovrld:eqExpr(_, directCallExpr(nm, _)) -> nm.name
    | _ -> error("Invalid forms reported via errors attribute")
    end;
  
  local valType :: Type =
    (decorate ableC_Expr{$name{fName}}
      with {env=top.env; controlStmtContext=initialControlStmtContext;}).typerep;

  local funcReturnType :: Type =
    case valType of
    | functionType(res, _, _) -> res
    | _ -> error("Bad types reported via errors attribute")
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
    | _ -> error("Invalid forms reported via errors attribute")
    end;
  local lhs :: Expr =
    case e of
    | ovrld:eqExpr(l, _) -> l
    | _ -> error("Only accessed when the expression has a left-hand side")
    end;
 
  local args :: Exprs =
    case e of
    | directCallExpr(_, a) -> a
    | ovrld:eqExpr(_, directCallExpr(_, a)) -> a
    | _ -> error("Only accessed when the expression has arguments")
    end;

  local localErrors :: [Message] = annts.errors ++ e.errors ++ 
    (if !validForm
    then [err(e.location, "Cilk spawns do not currently support this type of expression")]
    else 
      let lookupErrs :: [Message] =
        (decorate name(fName, location=loc) with {env=top.env;}).valueLookupCheck
      in
      if !null(lookupErrs)
      then lookupErrs
      else case valType of 
        | functionType(_, _, _) -> 
          if retVoid && hasLhs
          then [err(loc, "Cannot assign the result of a void function")]
          else if !retVoid && !hasLhs
          then [err(loc, "Cilk spawns cannot currently ignore the result of the function")]
          else []
        | _ -> [err(e.location, "Attempted to call a value of non-function type")]
        end
      end);

  local anntWarnings :: [Message] =
    if !null(annts.privates) || !null(annts.publics) || !null(annts.globals)
    then [wrn(loc, "public/private/global annotations on cilk spawn ignored")]
    else [];

  local liftedName :: String =
    s"__${fName}_interface_${substitute(":", "_", substitute(".", "_", loc.unparse))}_u${toString(genInt())}";

  local funcArgTypes :: [Type] =
    case valType of
    | functionType(_, protoFunctionType(ts, false), _) -> ts
    | functionType(_, noProtoFunctionType(), _) -> []
    | _ -> error("Invalid forms reported via errors attribute")
    end;

  local inputStructNames :: [Name] =
    name("header", location=loc) ::
    (if retVoid then []
      else name("ret", location=loc) :: name("res", location=loc) :: [])
    ++
    map(\i::Integer -> name(s"__arg_${toString(i)}", location=loc),
      range(0, length(funcArgTypes)))
    ++
    map(\i::Integer -> name(s"__thread_${toString(i)}", location=loc),
      range(0, length(threads)))
    ++
    map(\i::Integer -> name(s"__group_${toString(i)}", location=loc),
      range(0, length(groups)));
  local inputStructTypes :: [Type] =
    (decorate typedefTypeExpr(nilQualifier(), name("CilkStackFrame", location=loc))
      with {env=top.env; controlStmtContext=initialControlStmtContext;
      givenRefId=nothing();}).typerep
    ::
    (if retVoid then []
      else pointerType(nilQualifier(), funcReturnType) :: funcReturnType :: [])
    ++
    funcArgTypes
    ++
    map(\e::Expr ->
      getPointerType(
        (decorate e with {env=top.env;
                      controlStmtContext=initialControlStmtContext;}).typerep
      ),
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
  local structDecl :: Decl =
    ableC_Decl {
      struct $name{liftedName ++ "_struct"} {
        $StructItemList{inputStructItems}
      };
    };
  structDecl.isTopLevel = true;
  structDecl.controlStmtContext = initialControlStmtContext;
  structDecl.env = globalEnv(top.env);

  local callArgs :: Exprs =
    foldr(consExpr, nilExpr(),
      map(\i::Integer -> ableC_Expr{_cilk_frame->$name{s"__arg_${toString(i)}"}},
        range(0, length(funcArgTypes))));
  local call::Expr =
    directCallExpr(name(s"_cilk_${fName}", location=loc),
      consExpr(ableC_Expr { _cilk_ws }, callArgs), location=loc);
 
  local globalEnvStruct :: Decorated Env =
    addEnv(structDecl.defs, globalEnv(top.env));
  local interfaceEnv :: Decorated Env =
    addEnv(
      valueDef("_cilk_frame",
        declaratorValueItem(
          decorate declarator(
            name("_cilk_frame", location=loc),
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
              (decorate ableC_Expr { ({ struct $name{liftedName ++ "_struct"} res; res; }) }
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

  local funcBody :: Stmt =
    ableC_Stmt {
      Cilk_cilk2c_start_thread_slow_cp(_cilk_ws, &(_cilk_frame->header));
      Cilk_cilk2c_start_thread_slow(_cilk_ws, &(_cilk_frame->header));
      switch(_cilk_frame->header.entry) {
        case 1:
          goto _cilk_sync1;
        case 2:
          goto _cilk_sync2;
        case 3:
          goto _cilk_sync3;
      }
      
      // Setup (marking threads and groups as ready)
      $Stmt{foldStmt(
        map(
          \p::(Integer, Expr) ->
            case decorate p.snd with {env=top.env;
                    controlStmtContext=initialControlStmtContext;}.typerep of
            | extType(_, threadType(s)) ->
                (decorate s with {env=interfaceEnv;
                    threads=[ableC_Expr{_cilk_frame->$name{s"__thread_${toString(p.fst)}"}}];
                }).threadThrdOps
            | _ -> error("Invalid forms reported via errors attribute")
            end,
          zipWith(pair, range(0, length(threads)), threads)
        )
        ++
        map(
          \p::(Integer, Expr) ->
            case decorate p.snd with {env=top.env;
                  controlStmtContext=initialControlStmtContext;}.typerep of
            | extType(_, groupType(s)) ->
                (decorate s with {env=interfaceEnv;
                    groups=[ableC_Expr{_cilk_frame->$name{s"__group_${toString(p.fst)}"}}];
                }).groupThrdOps
            | _ -> error("Invalid forms reported via errors attribute")
            end,
          zipWith(pair, range(0, length(groups)), groups)
        )
      )}

      _cilk_frame->header.entry = 1;
      Cilk_cilk2c_before_spawn_slow_cp(_cilk_ws, &(_cilk_frame->header));
      Cilk_cilk2c_push_frame(_cilk_ws, &(_cilk_frame->header));

      $Stmt{
        if retVoid then exprStmt(call)
        else ableC_Stmt {
          $directTypeExpr{funcReturnType} res = $Expr{call};
          _cilk_frame->res = res;
        }
      }

      if (Cilk_cilk2c_pop_check(_cilk_ws)) {
        if (Cilk_exception_handler($Exprs{
            foldExpr(ableC_Expr{_cilk_ws} ::
              if retVoid
              then ableC_Expr{(void*) 0} :: ableC_Expr{0} :: []
              else ableC_Expr{&res} :: ableC_Expr{sizeof($directTypeExpr{funcReturnType})} :: []
            )
          })) {
            Cilk_cilk2c_pop(_cilk_ws);
            return;
        }
      }

      Cilk_cilk2c_after_spawn_slow_cp(_cilk_ws, &(_cilk_frame->header));

    _cilk_sync1: ;
      Cilk_cilk2c_at_thread_boundary_slow_cp(_cilk_ws, &(_cilk_frame->header));
      Cilk_cilk2c_event_new_thread_maybe(_cilk_ws);
      Cilk_cilk2c_before_sync_slow_cp(_cilk_ws, &(_cilk_frame->header));
      
      _cilk_frame->header.entry = 2;
      if (Cilk_sync(_cilk_ws)) {
        return;
    _cilk_sync2: ;
      }

      Cilk_cilk2c_after_sync_slow_cp(_cilk_ws, &(_cilk_frame->header));
      Cilk_cilk2c_at_thread_boundary_slow_cp(_cilk_ws, &(_cilk_frame->header));
      Cilk_cilk2c_event_new_thread_maybe(_cilk_ws);

      // Copy value
      $Stmt{if retVoid then nullStmt()
          else ableC_Stmt {
              if (_cilk_frame->ret) {
                *(_cilk_frame->ret) = _cilk_frame->res;
              }
            }
      }
      // Tear down (marking threads and groups as done)
      $Stmt{foldStmt(
        map(
          \p::(Integer, Expr) ->
            case decorate p.snd with {env=top.env;
                  controlStmtContext=initialControlStmtContext;}.typerep of
            | extType(_, threadType(s)) ->
                (decorate s with {env=interfaceEnv;
                  threads=[ableC_Expr{_cilk_frame->$name{s"__thread_${toString(p.fst)}"}}];
                }).threadPostOps
            | _ -> error("Invalid form reported via errors attribute")
            end,
          zipWith(pair, range(0, length(threads)), threads)
        )
        ++
        map(
          \p::(Integer, Expr) ->
            case decorate p.snd with {env=top.env;
                  controlStmtContext=initialControlStmtContext;}.typerep of
            | extType(_, groupType(s)) ->
                (decorate s with {env=interfaceEnv;
                  groups=[ableC_Expr{_cilk_frame->$name{s"__group_${toString(p.fst)}"}}];
                }).groupPostOps
            | _ -> error("Invalid forms reported via errors attribute")
            end,
          zipWith(pair, range(0, length(groups)), groups)
        )
      )}

      Cilk_remove_and_free_closure_and_frame(_cilk_ws, &(_cilk_frame->header),
          _cilk_ws->self);
      return ;

    _cilk_sync3: ;
      Cilk_cilk2c_after_sync_slow_cp(_cilk_ws, &(_cilk_frame->header));
      Cilk_cilk2c_at_thread_boundary_slow_cp(_cilk_ws, &(_cilk_frame->header));
      Cilk_cilk2c_event_new_thread_maybe(_cilk_ws);
    };

  local functionDecl :: Decl =
    ableC_Decl {
      proto_typedef CilkWorkerState;
      static void $name{liftedName}(CilkWorkerState* const _cilk_ws,
                      struct $name{liftedName ++ "_struct"}* _cilk_frame) {
        $Stmt{funcBody}
      }
    };

  local returnSizeExpr :: Expr =
    if retVoid then ableC_Expr{0}
      else ableC_Expr{sizeof($directTypeExpr{funcReturnType})};
  local sigDecl :: Decl =
    ableC_Decl {
      proto_typedef CilkProcInfo, size_t;
      CilkProcInfo $name{liftedName ++ "_sig"}[] =
        {
          {
            $Expr{returnSizeExpr},
            sizeof(struct $name{liftedName ++ "_struct"}),
            $name{liftedName},
            0,
            0
          },
          {
            $Expr{returnSizeExpr},
            $Expr{if retVoid then ableC_Expr{0}
                  else ableC_Expr {
                    (size_t) &(((struct $name{liftedName ++ "_struct"}*) 0)->res)
                  }},
            0,
            0,
            0
          },
          {
            0,
            0,
            0,
            0,
            0
          },
          {
            0,
            0,
            0,
            0,
            0
          }
        };
    };

  local fwrdStmt :: Stmt =
    ableC_Stmt {
      proto_typedef CilkContext, CilkStackFrame;
      {
        struct $name{liftedName ++ "_struct"}* _cilk_frame;
        _cilk_frame = Cilk_malloc(sizeof(struct $name{liftedName ++ "_struct"}));
        
        $Stmt{if retVoid then nullStmt()
          else ableC_Stmt { _cilk_frame->ret = &($Expr{lhs}); }}
        $Stmt{foldStmt(
          map(\p::(Integer, Expr) ->
            ableC_Stmt {
              _cilk_frame->$name{s"__arg_${toString(p.fst)}"} = $Expr{p.snd};
            },
            zipWith(pair, range(0, length(args.exprList)), args.exprList)
          )
        )}
        $Stmt{foldStmt(
          map(\p::(Integer, Expr) ->
            ableC_Stmt {
              _cilk_frame->$name{s"__thread_${toString(p.fst)}"} =
                $Expr{getReference(decorate p.snd with {env=top.env;
                                controlStmtContext=initialControlStmtContext;})};
              $Stmt{case decorate p.snd with {env=top.env;
                      controlStmtContext=initialControlStmtContext;}.typerep of
                    | extType(_, threadType(s)) ->
                        (decorate s with {env=interfaceEnv;
                          threads=[ableC_Expr{_cilk_frame->$name{s"__thread_${toString(p.fst)}"}}];
                        }).threadBefrOps
                    | _ -> error("Invalid forms repoted via errors attribute")
                    end}
            },
            zipWith(pair, range(0, length(threads)), threads)
          )
        )}
        $Stmt{foldStmt(
          map(\p::(Integer, Expr) ->
            ableC_Stmt {
              _cilk_frame->$name{s"__group_${toString(p.fst)}"} =
                $Expr{getReference(decorate p.snd with {env=top.env;
                                controlStmtContext=initialControlStmtContext;})};
              $Stmt{case decorate p.snd with {env=top.env;
                      controlStmtContext=initialControlStmtContext;}.typerep of
                    | extType(_, groupType(s)) ->
                        (decorate s with {env=interfaceEnv;
                          groups=[ableC_Expr{_cilk_frame->$name{s"__group_${toString(p.fst)}"}}];
                        }).groupBefrOps
                    | _ -> error("Invalid forms reported via errors attribute")
                    end}
            },
            zipWith(pair, range(0, length(groups)), groups)
          )
        )}

        struct __ableC_system_info* _sys_info =
          (struct __ableC_system_info*) $Expr{sys};
        CilkContext* _sys_context = (CilkContext*) _sys_info->system_data;

        ableC_parallel_cilk_spawn(_sys_context, $name{liftedName ++ "_sig"},
              (CilkStackFrame*) _cilk_frame);
      }
    };

  forwards to
    if !null(localErrors)
    then warnStmt(localErrors)
    else
        injectGlobalDeclsStmt(
          consDecl(structDecl, consDecl(functionDecl, consDecl(sigDecl, nilDecl()))),
          seqStmt(warnStmt(anntWarnings), fwrdStmt));
}

abstract production cilkParFor
top::Stmt ::= loop::Stmt loc::Location annts::ParallelAnnotations
{
  top.pp = ppConcat([text("parallel"), space(), loop.pp]);
  top.functionDefs := [];
  top.labelDefs := [];

  local privateVars :: [Name] = nub(annts.privates);
  local publicVars  :: [Name] = nub(annts.publics);
  local globalVars  :: [Name] = nub(annts.globals);

  local localErrors :: [Message] =
    loop.errors ++ annts.errors ++ missingVars ++
    case annts.numParallelThreads of
    | nothing() -> [err(loc, "Parallel for-loop is missing a num-threads annotation")]
    | _ -> []
    end;

  local liftedName :: String =
    s"__lifted_cilk_parallel_${substitute(":", "_", substitute(".", "_", loc.unparse))}_u${toString(genInt())}";

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

  -- Var type, var name, upper bound, loop body
  local loopInfo :: (BaseTypeExpr, Name, Expr, Stmt) =
    case loop of
    | ableC_Stmt { for($BaseTypeExpr{bt} $Name{i1} = host::(0); host::$Name{_} host::< $Expr{bound}; host::$Name{_} host::++) $Stmt{bd} }
      -> (bt, i1, bound, new(bd))
    | _ -> error("Bad for-loop should be caught by ableC-parallel's invocation of cilkParFor")
    end;
  local varType :: Type =
    (decorate loopInfo.1 with 
      {env=top.env; controlStmtContext=top.controlStmtContext; givenRefId=nothing();}
    ).typerep;

  local structItemNames :: [Name] =
    name("__init", location=loc) ::
    name("__bound", location=loc) ::
    freePublic ++ freePrivate;
  local structItemTypes :: [Type] =
    varType :: varType ::
    publicVarTypes ++ privateVarTypes;
  local structItemInits :: [Expr] =
    ableC_Expr { _first_iter} ::
    ableC_Expr { _num_iters + _first_iter } ::
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
                mkStringConst("edu:umn:cs:melt:exts:ableC:parallel:impl:cilk:input" ++ liftedName, loc),
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
                  "edu:umn:cs:melt:exts:ableC:parallel:impl:cilk:input" ++ liftedName
                )
              );
            env = globalEnvStruct;
          }
        )
      )
      ::
      valueDef(loopInfo.2.name, -- Loop variable
        declaratorValueItem(
          decorate declarator(
            loopInfo.2,
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
            baseType = varType;
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

  local transformedBody :: Stmt =
    (decorate loopInfo.4 with {env=transformedEnv;
                controlStmtContext=initialControlStmtContext;}).forLift;
  transformedBody.env = transformedEnv;
  transformedBody.controlStmtContext = initialControlStmtContext;

  local spawnedBody :: Stmt =
    spawnTask(
      case 
        decorate cleanStmt(transformedBody, transformedEnv)
        with {env=top.env; controlStmtContext=initialControlStmtContext;}
      of
      | exprStmt(e) -> e
      | _ -> errorExpr([err(loc, "Invalid body of cilk parallel for-loop")], location=loc)
      end,
      nilSpawnAnnotations());

  local cilkFunction :: Decl =
    cilkParFunctionConverter(
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
                  "edu:umn:cs:melt:exts:ableC:parallel:impl:cilk:input" ++ liftedName
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
          $BaseTypeExpr{loopInfo.1} __init = args->__init;
          $BaseTypeExpr{loopInfo.1} __bound = args->__bound;
          
          $Stmt{parallelFor(ableC_Decl { $BaseTypeExpr{loopInfo.1} $Name{loopInfo.2} = __init; },
            justExpr(ableC_Expr{$Name{loopInfo.2} < __bound}),
            ableC_Expr{$Name{loopInfo.2}++},
            transformedBody, nilParallelAnnotations())}
          /*for ($BaseTypeExpr{loopInfo.1} $Name{loopInfo.2} = __init;
                $Name{loopInfo.2} < __bound;
                $Name{loopInfo.2}++) {
            $Stmt{spawnedBody}
            $Stmt{syncTask(nilExpr())}
          }*/
          $Stmt{syncTask(nilExpr())}

          free(args);
          return 0;
        }
      )
    );
  
  local spawnAnnts :: SpawnAnnotations =
    consSpawnAnnotations(
      spawnPrivateAnnotation(name("args", location=loc) :: [], location=loc),
      annts.parToSpawnAnnts
    );
  local fwrdStmt :: Stmt =
    ableC_Stmt {
      {
        const int _n_threads = $Expr{annts.numParallelThreads.fromJust};
        if (__builtin_expect(_n_threads < 1, 0)) {
          fprintf(stderr,
            $stringLiteralExpr{s"Parallel for-loop must have a positive number of threads (${loc.unparse})"});
          exit(-1);
        }

        const $BaseTypeExpr{loopInfo.1} _n_iters = $Expr{loopInfo.3};
        const $BaseTypeExpr{loopInfo.1} _n_iters_per_thread = _n_iters / _n_threads;
        const $BaseTypeExpr{loopInfo.1} _n_iters_extra = _n_iters % _n_threads;

        for (int _thread_num = 0; _thread_num < _n_threads; _thread_num++) {
          const $BaseTypeExpr{loopInfo.1} _first_iter = _n_iters_per_thread * _thread_num
            + (_thread_num < _n_iters_extra ? _thread_num : _n_iters_extra);
          const $BaseTypeExpr{loopInfo.1} _num_iters = _n_iters_per_thread
            + (_thread_num < _n_iters_extra ? 1 : 0);

          struct $name{liftedName ++ "_struct"}* args =
            malloc(sizeof(struct $name{liftedName ++ "_struct"}));
          $Stmt{foldStmt(map(
            \p::Pair<Name Expr> ->
              ableC_Stmt {
                args->$Name{p.fst} = $Expr{p.snd};
              },
            zipWith(pair, structItemNames, structItemInits)))}

          int __tmp;
          $Stmt{cilkSpawn(
            ableC_Expr {
              __tmp = $name{liftedName}(args)
            },
            loc,
            spawnAnnts
          )}
        }
      }
    };

  forwards to
    if !null(localErrors)
    then warnStmt(localErrors)
    else
      injectGlobalDeclsStmt(
        consDecl(structDcl, consDecl(cilkFunction, nilDecl())),
        fwrdStmt
      );
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
          init_ableC_parallel_cilk(_num_threads, $intLiteralExpr{sysIndex});

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
          stop_ableC_parallel_cilk(_sys);
        }
      };
}
