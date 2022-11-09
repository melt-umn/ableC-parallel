grammar edu:umn:cs:melt:exts:ableC:parallel:exts:mapReduce;

synthesized attribute arrayLength :: Expr;
synthesized attribute arrayResult :: Expr;
synthesized attribute shouldFree :: Boolean;
synthesized attribute elemType :: Type;
synthesized attribute fusionResult :: MapReduceArray;

-- Top-level map/reduce will actually evaluate the bound and store it into
-- a variable, others will just use that bound since maps do not change
-- the length of the array
inherited attribute emitBound :: Boolean;

nonterminal MapReduceArray with location, errors, env, controlStmtContext,
  arrayLength, arrayResult, shouldFree, elemType, emitBound, fusionResult, pp;

abstract production arrayExpr
top::MapReduceArray ::= arr::Name len::Expr
{
  top.pp = ppConcat([arr.pp, brackets(len.pp)]);

  propagate controlStmtContext, env;

  top.errors := len.errors ++
    case arr.valueLookupCheck of
    | [] ->
      case arr.valueItem.typerep of
      | pointerType(_, _) -> []
      | arrayType(_, _, _, _) -> []
      | errorType() -> []
      | _ -> [err(arr.location, "Map-reduce only works with array or pointer types")]
      end
    | lst -> lst
    end;
  
  top.arrayLength = len;
  top.arrayResult = ableC_Expr { $Name{arr} };
  top.shouldFree = false;
  top.elemType = 
    case arr.valueItem.typerep of
    | pointerType(_, t) -> t
    | arrayType(t, _, _, _) -> t
    | _ -> error("Other types reported via errors attribute")
    end;

  top.fusionResult = top;
}

abstract production mapExpr
top::MapReduceArray ::= arr::MapReduceArray var::Name body::Expr annts::MapReduceAnnts
{
  top.pp = parens(ppConcat([text("map"), brackets(annts.pp), space(), arr.pp,
                          space(), text("by"), space(), text("\\"), var.pp,
                          space(), text("->"), space(), body.pp]));

  arr.env = top.env;
  annts.env = top.env;

  local cscx :: ControlStmtContext = initialControlStmtContext;
  arr.controlStmtContext = cscx;
  var.controlStmtContext = cscx;
  body.controlStmtContext = cscx;
  annts.controlStmtContext = cscx;

  local funcEnv :: Decorated Env =
    addEnv(
      valueDef(
        var.name,
        declaratorValueItem(
          decorate
            declarator(var, baseTypeExpr(), nilAttribute(), nothingInitializer())
          with {
            env=top.env; baseType=arr.elemType; typeModifierIn=baseTypeExpr();
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

  top.errors := arr.errors ++ annts.errors ++ body.errors ++
    case annts.fusion of
    | nothing() -> []
    | just(_) ->
      case mapFusion of
      | left(_) -> []
      | right(errs) -> errs
      end
    end
    ++
    case annts.bySystem, annts.syncBy of
    | nothing(), nothing() -> []
    | just(byEx), just(syQual) ->
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
    | _, _ -> [err(top.location, "On a map, both the by and sync-by annotations must be provided or neither can be provided")]
    end;

  top.arrayLength = arr.arrayLength;
  top.shouldFree = true;
  top.elemType = body.typerep;
 
  local replacedBody :: Expr =
    replaceExprVariable(body, var, ableC_Expr{__src[__idx]}, top.env,
                    cscx);

  -- Add __src and __res as private variables to the annotations
  local parallelize :: Boolean =
    case annts.bySystem of
    | nothing() -> false
    | just(_) -> true
    end;
  local parAnnts :: ParallelAnnotations =
    consParallelAnnotations(
      parallelInAnnotation(ableC_Expr{__group}, location=top.location),
      consParallelAnnotations(
        parallelPrivateAnnotation(
          name("__src", location=top.location) ::
          name("__res", location=top.location) ::
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
        consParallelAnnotations(
          parallelGlobalAnnotation(
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
          toParallelAnnotations(annts)
        )
      )
    );
  local parSystem :: ParallelSystem =
    case annts.bySystem of
    | just(e) ->
      case (decorate e with {env=top.env; controlStmtContext=cscx;}).typerep of
      | extType(_, parallelType(s)) -> s
      | _ -> error("Bad type should be caught by errors attribute")
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

  local resultLoop :: Stmt =
    ableC_Stmt {
      for (unsigned long __idx = 0; __idx < __mapReduceLength; __idx++) {
        __res[__idx] = $Expr{replacedBody};
      }
    };

  top.arrayResult =
    ableC_Expr {
      ({
        $Stmt{if top.emitBound
              then ableC_Stmt {const unsigned long __mapReduceLength = $Expr{arr.arrayLength};} 
              else nullStmt()}
        $directTypeExpr{arr.elemType}* __src = $Expr{fusedArr.arrayResult};
        $directTypeExpr{top.elemType}* __res =
          malloc(sizeof($directTypeExpr{top.elemType}) * __mapReduceLength);

        // The actual loop (either sequential or parallelized)
        $Stmt{
          if !parallelize
          then resultLoop
          else 
            ableC_Stmt {
              $directTypeExpr{extType(nilQualifier(), groupType(syncSystem))} __group;
              $Expr{syncSystem.initializeGroup(
                ableC_Expr{ __group },
                nilExpr(), top.location)};

              $Stmt{parSystem.fFor(resultLoop, top.location, parAnnts)}
              
              $Stmt{syncSystem.syncGroups}
              $Stmt{case syncSystem.groupDeleteProd of
                    | nothing() -> nullStmt()
                    | just(f) -> f(ableC_Expr{__group})
                    end}
            }
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
  fusion.mapSpec = (var, new(body));

  local mapFusion :: Either<MapReduceArray [Message]> = fusion.mapFusion;

  top.fusionResult =
    case annts.fusion of
    | nothing() -> top
    | just(_) -> mapFusion.fromLeft
    end;
}
