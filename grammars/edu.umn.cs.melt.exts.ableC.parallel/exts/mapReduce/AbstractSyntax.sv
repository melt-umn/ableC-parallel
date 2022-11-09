grammar edu:umn:cs:melt:exts:ableC:parallel:exts:mapReduce;

abstract production reduceExpr
top::Expr ::= arr::MapReduceArray init::Expr arrVar::Name accumVar::Name
              body::Expr annts::MapReduceAnnts
{
  top.pp = ppConcat([text("reduce"), brackets(annts.pp), space(), arr.pp,
                    text("from"), parens(init.pp), space(), text("by"), space(),
                    text("\\"), arrVar.pp, space(), accumVar.pp, space(),
                    text("->"), space(), body.pp]);
  
  arr.env = top.env;
  init.env = top.env;
  annts.env = top.env;

  local cscx :: ControlStmtContext = initialControlStmtContext;
  arr.controlStmtContext = cscx;
  arrVar.controlStmtContext = cscx;
  init.controlStmtContext = cscx;
  accumVar.controlStmtContext = cscx;
  body.controlStmtContext = cscx;
  annts.controlStmtContext = cscx;

  local funcEnv :: Decorated Env =
    addEnv(
      valueDef(
        arrVar.name,
        declaratorValueItem(
          decorate
            declarator(arrVar, baseTypeExpr(), nilAttribute(), nothingInitializer())
          with {
            env=top.env; baseType=arr.elemType; typeModifierIn=baseTypeExpr();
            givenStorageClasses=nilStorageClass(); givenAttributes=nilAttribute();
            isTopLevel=false; isTypedef=false;
            controlStmtContext=cscx;
          }
        )
      ) ::
      valueDef(
        accumVar.name,
        declaratorValueItem(
          decorate
            declarator(accumVar, baseTypeExpr(), nilAttribute(), nothingInitializer())
          with {
            env=top.env; baseType=init.typerep; typeModifierIn=baseTypeExpr();
            givenStorageClasses=nilStorageClass(); givenAttributes=nilAttribute();
            isTopLevel=false; isTypedef=false;
            controlStmtContext=cscx;
          }
        )
      ) :: [],
      top.env
    );
  body.env = funcEnv;

  local fusedArr :: MapReduceArray = arr.fusionResult;
  fusedArr.emitBound = false;
  fusedArr.controlStmtContext = cscx;
  fusedArr.env = top.env;

  local localErrors :: [Message] =
    arr.errors ++ annts.errors ++ body.errors ++
    (if !typeAssignableTo(init.typerep, body.typerep)
    then [err(body.location, "Return type of the reduction function must match the type of the initial value")]
    else [])
    ++
    case annts.fusion of
    | nothing() -> []
    | just(_) ->
      case reduceFusion of
      | left(_) -> []
      | right(errs) -> errs
      end
    end
    ++
    case annts.bySystem, annts.numParallelThreads, annts.syncBy, annts.parComb of
    | nothing(), nothing(), nothing(), nothing() -> []
    | just(byEx), just(numPar), just(syQual), just((v1, v2, bd)) ->
      -- TODO: Missing a check that if v1, v2 have type of init, bd has type of init
      case (decorate byEx with {env=top.env; controlStmtContext=cscx;}).typerep of
      | extType(_, parallelType(_)) -> []
      | _ -> [err(top.location, "The argument to the by annotation must be a parallel interface")]
      end
      ++
      case syQual of
      | consQualifier(q, nilQualifier()) ->
        case q.syncSystem of
        | just(_) -> []
        | nothing() -> [err(q.location, "The qualifier given to sync-by must specify a sync system")]
        end
      | _ -> [err(top.location, "The argument to the sync-by annotation must be a single qualifier")]
      end
      ++
      (if (decorate numPar with {env=top.env; controlStmtContext=cscx;}).typerep.isIntegerType
      then []
      else [err(top.location, "The argument to num-threads must be an integrer value")])
    | _, _, _, _ -> [err(top.location, "On a reduce, all four of by, num-threads, sync-by, and par-comb must be provided to parallelize the reduce; otherwise none are allowed")]
    end;

  local replacedBody :: Expr =
    replaceExprVariable(
      replaceExprVariable(body, arrVar, ableC_Expr { __src[__idx] },
        top.env, cscx),
      accumVar, ableC_Expr { __res }, top.env, cscx);

  local parallelize :: Boolean =
    case annts.bySystem of
    | just(_) -> true
    | nothing() -> false
    end;
  local parAnnts :: SpawnAnnotations =
    consSpawnAnnotations(
      spawnInAnnotation(ableC_Expr{__group}, location=top.location),
      consSpawnAnnotations(
        spawnPrivateAnnotation(
          name("__src", location=top.location) ::
          name("__threadId", location=top.location) ::
          name("__res", location=top.location) ::
          name("__results", location=top.location) ::
          name("__itersPerThread", location=top.location) ::
          name("__nItersExtra", location=top.location) ::
          {- add non-global free variables from body -}
          filter(\n::Name ->
              case (decorate n with {env=nonGlobalEnv(top.env);}).valueItem of
              | errorValueItem() -> false
              | _ -> true
              end,
            body.freeVariables
          ),
          location=top.location
        ),
        consSpawnAnnotations(
          spawnGlobalAnnotation(
            {- add global free variables from body -}
            filter(\n::Name ->
                case (decorate n with {env=nonGlobalEnv(top.env);}).valueItem of
                | errorValueItem() -> true
                | _ -> false
                end,
              body.freeVariables
            ),
            location=top.location
          ),
          toParallelAnnotations(annts).parToSpawnAnnts
        )
      )
    );
  local parSystem :: ParallelSystem =
    case annts.bySystem of
    | just(e) ->
      case (decorate e with {env=top.env; controlStmtContext=cscx;}).typerep of
      | extType(_, parallelType(s)) -> s
      | _ -> error("Bad type is caught by errors attribute")
      end
    | _ -> error("This local is not used in this case")
    end;
  local syncSystem :: SyncSystem =
    case annts.syncBy of
    | just(consQualifier(q, nilQualifier())) -> q.syncSystem.fromJust
    | _ -> error("This local is not used in this case")
    end;
  syncSystem.groups = [ableC_Expr{__group}];
  syncSystem.env =
    addEnv(
      valueDef("__group", 
        declaratorValueItem(
          decorate
            declarator(
              name("__group", location=top.location),
              baseTypeExpr(), nilAttribute(), nothingInitializer()
            )
          with {
            env=top.env; baseType=extType(nilQualifier(), groupType(syncSystem));
            typeModifierIn=baseTypeExpr(); givenAttributes=nilAttribute();
            isTopLevel=false; isTypedef=false;
            controlStmtContext=cscx; givenStorageClasses=nilStorageClass();
          }
        )
      ) :: [],
      top.env
    );
  
  local spawnBody :: Expr =
    ableC_Expr {
      ({
        const unsigned long __firstIter = __itersPerThread * __threadId
          + (__threadId < __nItersExtra ? __threadId : __nItersExtra);
        const unsigned long __numIters  = __itersPerThread
          + (__threadId < __nItersExtra ? 1 : 0);

        for (unsigned long __idx = __firstIter; 
            __idx < __firstIter + __numIters; __idx++) {
          __res = $Expr{replacedBody};
        }

        __results[__threadId] = __res;
      })
    };
  local spawnStmt :: Stmt = spawnTask(spawnBody, parAnnts);

  local comb :: (Name, Name, Expr) = annts.parComb.fromJust;
  local fwrd :: Expr =
    if parallelize
    then
      ableC_Expr {
        ({
          const unsigned long __mapReduceLength = $Expr{arr.arrayLength};
          
          $directTypeExpr{extType(nilQualifier(), groupType(syncSystem))} __group;
          $Expr{syncSystem.initializeGroup(ableC_Expr{__group}, nilExpr(), top.location)};

          $directTypeExpr{arr.elemType}* __src = $Expr{fusedArr.arrayResult};
          $directTypeExpr{init.typerep} __res = $Expr{init};

          const unsigned long __nThreads = $Expr{annts.numParallelThreads.fromJust};
          if (__builtin_expect(__nThreads < 1, 0)) {
            fprintf(stderr, 
              $stringLiteralExpr{s"Reduce requires positive number of threads (${top.location.unparse})"});
            exit(-1);
          }

          unsigned long __itersPerThread = __mapReduceLength / __nThreads;
          unsigned long __nItersExtra = __mapReduceLength % __nThreads;
          
          $directTypeExpr{init.typerep}* __results =
            malloc(sizeof($directTypeExpr{init.typerep}) * __nThreads);
          for (unsigned int __threadId = 0; __threadId < __nThreads; __threadId++) {
            $Stmt{spawnStmt}
          }

          $Stmt{syncSystem.syncGroups}
          $Stmt{case syncSystem.groupDeleteProd of
                | nothing() -> nullStmt()
                | just(f) -> f(ableC_Expr{__group})
                end}

          $Stmt{if arr.shouldFree
                then ableC_Stmt{ free(__src); }
                else nullStmt()}

          for (unsigned int __threadId = 0; __threadId < __nThreads; __threadId++) {
            __res = $Expr{replaceExprVariable(
              replaceExprVariable(comb.3, comb.1, ableC_Expr{__results[__threadId]},
                top.env, cscx),
              comb.2, ableC_Expr{__res}, top.env, cscx)};
          }
          free(__results);

          __res;
        })
      }
    else
      ableC_Expr {
        ({
          const unsigned long __mapReduceLength = $Expr{arr.arrayLength};

          $directTypeExpr{arr.elemType}* __src = $Expr{fusedArr.arrayResult};
          $directTypeExpr{init.typerep} __res = $Expr{init};

          // From left (index 0) to right
          for (unsigned long __idx = 0; __idx < __mapReduceLength; __idx++) {
            __res = $Expr{replacedBody};
          }

          $Stmt{if arr.shouldFree
                then ableC_Stmt { free(__src); }
                else nullStmt()}
          __res;
        })
      };

  local fusion :: Fusion = annts.fusion.fromJust;
  fusion.env = top.env;
  fusion.controlStmtContext = cscx;
  fusion.annts = annts;
  fusion.innerArray = fusedArr;
  fusion.reduceSpec = (init, arrVar, accumVar, new(body));

  local reduceFusion :: Either<Expr [Message]> = fusion.reduceFusion;

  forwards to
    if !null(localErrors)
    then errorExpr(localErrors, location=top.location)
    else
      case annts.fusion of
      | nothing() -> fwrd
      | just(_) -> reduceFusion.fromLeft
      end;
}

abstract production mapExprBridge
top::Expr ::= exp::MapReduceArray
{
  top.pp = exp.pp;

  propagate controlStmtContext, env;

  local fused :: MapReduceArray = exp.fusionResult;
  fused.emitBound = true;
  fused.controlStmtContext = initialControlStmtContext;
  fused.env = top.env;

  forwards to
    if !null(exp.errors)
    then errorExpr(exp.errors, location=top.location)
    else fused.arrayResult;
}
