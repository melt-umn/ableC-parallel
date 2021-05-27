grammar edu:umn:cs:melt:exts:ableC:parallel:impl:cilk:func;

aspect production spawnTask
top::Stmt ::= expr::Expr annts::SpawnAnnotations
{
  local fwrd :: Stmt = new(top.forward);
  fwrd.controlStmtContext = initialControlStmtContext;
  fwrd.env = top.env;

  local anyAnnotations :: Boolean =
    case annts of
    | nilSpawnAnnotations() -> false
    | _ -> true
    end;

  -- TODO: Add support for implicit inlets for += / -= / ...
  local validForm :: Boolean =
    case expr of
    | directCallExpr(_, _) -> true
    | ovrld:eqExpr(_, directCallExpr(_, _)) -> true
    | _ -> false
    end;
  local hasLhs :: Boolean =
    case expr of
    | directCallExpr(_, _) -> false
    | ovrld:eqExpr(_, directCallExpr(_, _)) -> true
    | _ -> false
    end;

  local lhs :: Expr = 
    case expr of
    | ovrld:eqExpr(l, directCallExpr(_, _)) -> l
    | _ -> error("Invalid forms reported via errors attribute")
    end;
  local fname:: String = 
    case expr of
    | ovrld:eqExpr(_, directCallExpr(n, _)) -> n.name
    | directCallExpr(n, _) -> n.name
    | _ -> error("Invalid forms reported via errors attribute")
    end;
  local args :: Exprs =
    case expr of
    | ovrld:eqExpr(_, directCallExpr(_, a)) -> a
    | directCallExpr(_, a) -> a
    | _ -> error("Invalid forms reported via errors attribute")
    end;

  top.cilkVersion =
    if annts.bySystem.isJust
    then fwrd
    else if anyAnnotations
    then warnStmt([err(expr.location, "Annotations not currently supported on cilk-sytle spawns.")])
    else if !validForm
    then warnStmt([err(expr.location, "This type of expression is not currently supported for cilk-style spawns: " ++ hackUnparse(expr))])
    else if !hasLhs
    then cilkSpawnStmtNoEqOp(ableC_Expr{$name{s"_cilk_${fname}"}}, args)
    else cilkSpawnStmt(lhs, ableC_Expr{$name{s"_cilk_${fname}"}}, args);
}
