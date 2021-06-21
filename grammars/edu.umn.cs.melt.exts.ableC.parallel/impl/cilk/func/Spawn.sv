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
    | callExpr(declRefExpr(_), _) -> true
    | eqExpr(_, directCallExpr(_, _)) -> true
    | eqExpr(_, callExpr(declRefExpr(_), _)) -> true
    | _ -> false
    end;
  local hasLhs :: Boolean =
    case expr of
    | eqExpr(_,  _) -> true
    | _ -> false
    end;

  local lhs :: Expr = 
    case expr of
    | eqExpr(l, _) -> l
    | _ -> error("Invalid forms reported via errors attribute")
    end;
  local fname:: String = 
    case expr of
    | eqExpr(_, directCallExpr(n, _)) -> n.name
    | eqExpr(_, callExpr(declRefExpr(n), _)) -> n.name
    | directCallExpr(n, _) -> n.name
    | callExpr(declRefExpr(n), _) -> n.name
    | _ -> error("Invalid forms reported via errors attribute")
    end;
  local args :: Exprs =
    case expr of
    | eqExpr(_, directCallExpr(_, a)) -> a
    | eqExpr(_, callExpr(_, a)) -> a
    | directCallExpr(_, a) -> a
    | callExpr(_, a) -> a
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
