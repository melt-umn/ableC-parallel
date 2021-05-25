grammar edu:umn:cs:melt:exts:ableC:parallel:impl:workstlr:func;

aspect production parallelFor
top::Stmt ::= init::Decl cond::MaybeExpr iter::Expr body::Stmt
              annts::ParallelAnnotations
{
  -- A Workstlr for-loop does not have a by ...; annotation and also shouldn't have
  -- any other annotations on it
  
  local fwrd :: Stmt = new(top.forward);
  fwrd.workstlrParFuncName = top.workstlrParFuncName;
  fwrd.workstlrParInitState = top.workstlrParInitState;
  fwrd.controlStmtContext = top.controlStmtContext;
  fwrd.env = top.env;
  
  -- Not sure if this is actually correct for non-Workstlr for-loop. Depends on
  -- lifting behavior
  top.workstlrParNeedStates = if annts.bySystem.isJust
    then fwrd.workstlrParNeedStates else 0;
  
  local anyAnnotations :: Boolean =
    case annts of
    | nilParallelAnnotations() -> false
    | _ -> true
    end;

  top.workstlrParFastClone =
    if annts.bySystem.isJust
    then fwrd.workstlrParFastClone
    else if anyAnnotations
    then warnStmt([err(iter.location, "Annotations not currently supported on workstlr-style parallel loops.")])
    else warnStmt([err(iter.location, "Workstlr parallel for-loops not currently supported")]);
  top.workstlrParSlowClone =
    if annts.bySystem.isJust
    then fwrd.workstlrParSlowClone
    else if anyAnnotations
    then warnStmt([err(iter.location, "Annotations not currently supported on workstlr-style parallel loops.")])
    else warnStmt([err(iter.location, "Workstlr parallel for-loops not currently supported")]);
}
