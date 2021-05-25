grammar edu:umn:cs:melt:exts:ableC:parallel:impl:workstlr:func;

aspect production syncTask
top::Stmt ::= tasks::Exprs
{
  -- A Workstlr sync does not have any tasks
  local fwrd :: Stmt = new(top.forward);
  fwrd.workstlrParFuncName = top.workstlrParFuncName;
  fwrd.workstlrParInitState = top.workstlrParInitState;
  fwrd.controlStmtContext = top.controlStmtContext;
  fwrd.env = top.env;
  
  top.workstlrParNeedStates = if tasks.count > 0 then fwrd.workstlrParNeedStates else 1;

  top.workstlrParFastClone =
    if tasks.count > 0
    then fwrd.workstlrParFastClone -- Regular result of propagate
    -- Otherwise this is a Workstlr-style sync
    else
      ableC_Stmt { { ; } }; -- This is the fast clone, no synchronization needed
  top.workstlrParSlowClone =
    if tasks.count > 0
    then fwrd.workstlrParSlowClone
    else
      ableC_Stmt {{
        __closure->state = $intLiteralExpr{top.workstlrParInitState};
        $name{s"__${top.workstlrParFuncName}_slow_state${toString(top.workstlrParInitState)}"}: ;

        if (__closure->joinCounter != 0) {
          if (--(__closure->joinCounter) >= 0) {
            return; // To the scheduler
          }
        }

        $Stmt{loadVariables(top.env)}
        __closure->joinCounter = 0;
      }};
}
