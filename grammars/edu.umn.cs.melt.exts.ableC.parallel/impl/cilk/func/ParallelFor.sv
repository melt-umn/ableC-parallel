grammar edu:umn:cs:melt:exts:ableC:parallel:impl:cilk:func;

aspect production parallelFor
top::Stmt ::= init::Decl cond::MaybeExpr iter::Expr body::Stmt
              annts::ParallelAnnotations
{
  -- A Cilk for-loop does not have a by ...; annotation and also shouldn't have
  -- any other annotations on it
  
  local fwrd :: Stmt = new(top.forward);
  fwrd.cilkParFuncName = top.cilkParFuncName;
  fwrd.cilkParInitState = top.cilkParInitState;
  fwrd.controlStmtContext = top.controlStmtContext;
  fwrd.env = top.env;
  
  -- Not sure if this is actually correct for non-Cilk for-loop. Depends on
  -- lifting behavior
  top.cilkParNeedStates = if annts.bySystem.isJust
    then fwrd.cilkParNeedStates else 0;
  
  local anyAnnotations :: Boolean =
    case annts of
    | nilParallelAnnotations() -> false
    | _ -> true
    end;

  top.cilkParFastClone =
    if annts.bySystem.isJust
    then fwrd.cilkParFastClone
    else if anyAnnotations
    then warnStmt([err(iter.location, "Annotations not currently supported on cilk-style parallel loops.")])
    else warnStmt([err(iter.location, "Cilk parallel for-loops not currently supported")]);
  top.cilkParSlowClone =
    if annts.bySystem.isJust
    then fwrd.cilkParSlowClone
    else if anyAnnotations
    then warnStmt([err(iter.location, "Annotations not currently supported on cilk-style parallel loops.")])
    else warnStmt([err(iter.location, "Cilk parallel for-loops not currently supported")]);
}
