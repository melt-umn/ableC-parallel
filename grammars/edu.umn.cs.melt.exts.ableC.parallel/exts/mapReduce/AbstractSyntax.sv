grammar edu:umn:cs:melt:exts:ableC:parallel:exts:mapReduce;

abstract production reduceExpr
top::Expr ::= arr::MapReduceArray init::Expr arrVar::Name accumVar::Name
              body::Expr annts::MapReduceAnnts
{
  top.pp = ppConcat([text("reduce"), brackets(annts.pp), space(), arr.pp,
                    text("from"), parens(init.pp), space(), text("by"), space(),
                    text("\\"), arrVar.pp, space(), accumVar.pp, space(),
                    text("->"), space(), body.pp]);
  
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
    end;

  local replacedBody :: Expr =
    replaceExprVariable(
      replaceExprVariable(body, arrVar, ableC_Expr { __src[__idx] },
        top.env, cscx),
      accumVar, ableC_Expr { __res }, top.env, cscx);

  -- TODO: Parallelism
  local fwrd :: Expr =
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

  local fused :: MapReduceArray = exp.fusionResult;
  fused.emitBound = true;
  fused.controlStmtContext = initialControlStmtContext;
  fused.env = top.env;

  forwards to
    if !null(exp.errors)
    then errorExpr(exp.errors, location=top.location)
    else fused.arrayResult;
}
