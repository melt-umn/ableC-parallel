grammar edu:umn:cs:melt:exts:ableC:parallel:impl:cilk:func;

aspect production parallelFor
top::Stmt ::= init::Decl cond::MaybeExpr iter::Expr body::Stmt
              annts::ParallelAnnotations
{
  -- A cilk for-loop does not have a by ...; annotation and also shouldn't have
  -- any other annotations on it
  
  local fwrd :: Stmt = new(top.forward);
  fwrd.controlStmtContext = top.controlStmtContext;
  fwrd.env = top.env;
  
  local anyAnnotations :: Boolean =
    case annts of
    | nilParallelAnnotations() -> false
    | _ -> true
    end;

  local cleanBody :: Stmt = cleanStmt(body, top.env);
  cleanBody.env = top.env;
  cleanBody.controlStmtContext = top.controlStmtContext;

  local form :: Maybe<(Expr, Exprs)> =
    case cleanBody of
    | exprStmt(directCallExpr(f, args)) ->
          just((ableC_Expr{$name{s"_cilk_${f.name}"}}, new(args)))
    | exprStmt(callExpr(declRefExpr(f), args)) ->
          just((ableC_Expr{$name{s"_cilk_${f.name}"}}, new(args)))
    | _ -> nothing()
    end;

  top.cilkVersion =
    if annts.bySystem.isJust
    then fwrd
    else if form.isJust
    then cilkForDeclStmt(init, cond, justExpr(iter),
            cilkForBody(form.fromJust.fst, form.fromJust.snd))
    else if canLift
    then liftedBody.cilkVersion
    else warnStmt([err(iter.location, "This form of parallel for-loop is not allowed in Cilk")]);

  local canLift :: Boolean =
    case cleanBody of
    | exprStmt(eqExpr(_, directCallExpr(_, _))) -> funcType.isJust
    | exprStmt(eqExpr(_, callExpr(declRefExpr(_), _))) -> funcType.isJust
    | _ -> false
    end;
  
  local liftingInfo :: (Expr, Name, Exprs) =
    case cleanBody of
    | exprStmt(eqExpr(lhs, directCallExpr(f, args))) -> (lhs, f, new(args))
    | exprStmt(eqExpr(lhs, callExpr(declRefExpr(f), args))) -> (lhs, f, new(args))
    | _ -> error("Not used when body is not in liftable form")
    end;
  
  local funcType :: Maybe<(Type, [Type])> =
    case lookupValue(liftingInfo.2.name, top.env) of
    | [] -> nothing()
    | v::_ ->
      case v.typerep of
      | functionType(res, protoFunctionType(args, _), _) -> just((res, args))
      | _ -> nothing()
      end
    end;
  local funcArgs :: [(Name, Type)] =
    foldl(\p::([(Name, Type)], Integer) t::Type ->
      (
        (name(s"arg${toString(p.2)}", location=iter.location), t) :: p.1,
        p.2+1
      ),
      ([], 0),
      funcType.fromJust.2).1;
  local parameters :: Parameters =
    consParameters(
      parameterDecl(nilStorageClass(),
        funcType.fromJust.1.baseTypeExpr,
        pointerTypeExpr(nilQualifier(), funcType.fromJust.1.typeModifierExpr),
        justName(name("ret", location=iter.location)), nilAttribute()),
      foldr(\arg::(Name, Type) pars::Parameters
        -> consParameters(
            parameterDecl(nilStorageClass(),
              arg.2.baseTypeExpr, arg.2.typeModifierExpr, justName(arg.1),
              nilAttribute()
            ),
            pars),
        nilParameters(),
        funcArgs)
      );
  local spawnArgs :: Exprs =
    foldr(\ar::(Name, Type) ex::Exprs -> consExpr(ableC_Expr{$Name{ar.1}}, ex),
      nilExpr(), funcArgs);
 
  local cilkFunction :: Decl =
    cilkParFunctionConverter(
      cilkFunctionDecl(
        nilStorageClass(), nilSpecialSpecifier(),
        builtinTypeExpr(nilQualifier(), signedType(intType())),
        functionTypeExprWithArgs(
          baseTypeExpr(),
          parameters,
          false, nilQualifier()
        ),
        name(liftedName, location=iter.location),
        nilAttribute(),
        nilDecl(),
        ableC_Stmt {
          {
            $directTypeExpr{funcType.fromJust.1} res;
            $Stmt{spawnTask(ableC_Expr{res = $Name{liftingInfo.2}($Exprs{spawnArgs})},
                      nilSpawnAnnotations())}
            $Stmt{syncTask(nilExpr())}

            *ret = res;
            return 0;
          }
        }
      )
    );
  cilkFunction.env = globalEnv(top.env);
  cilkFunction.controlStmtContext = initialControlStmtContext;
  cilkFunction.isTopLevel = true;

  local liftedName :: String =
    s"__lifted_cilk_parFor_${cleanLocName(iter.location.unparse)}_u${toString(genInt())}";

  top.globalDecls <-
    if !annts.bySystem.isJust && !form.isJust && canLift
    then [cilkFunction]
    else [];

  local liftedBody :: Stmt =
    {-injectGlobalDeclsStmt(
      consDecl(cilkFunction, nilDecl()),
      parallelFor(init, cond, iter,
        ableC_Stmt {
          $name{liftedName}(&($Expr{liftingInfo.1}), $Exprs{liftingInfo.3}); 
        },
      annts)
    );-}
    parallelFor(init, cond, iter,
      ableC_Stmt {
        $name{liftedName}(&($Expr{liftingInfo.1}), $Exprs{liftingInfo.3});
      },
      annts);
  liftedBody.env = top.env;
  liftedBody.controlStmtContext = initialControlStmtContext;
}
