grammar edu:umn:cs:melt:exts:ableC:parallel:impl:cilk:func;

aspect production syncTask
top::Stmt ::= tasks::Exprs
{
  -- A Cilk sync does not have any tasks
  local fwrd :: Stmt = new(top.forward);
  fwrd.cilkParFuncName = top.cilkParFuncName;
  fwrd.cilkParInitState = top.cilkParInitState;
  fwrd.controlStmtContext = top.controlStmtContext;
  fwrd.env = top.env;
  
  top.cilkParNeedStates = if tasks.count > 0 then fwrd.cilkParNeedStates else 1;

  top.cilkParFastClone =
    if tasks.count > 0
    then fwrd.cilkParFastClone -- Regular result of propagate
    -- Otherwise this is a Cilk-style sync
    else
      ableC_Stmt { { ; } }; -- This is the fast clone, no synchronization needed
  top.cilkParSlowClone =
    if tasks.count > 0
    then fwrd.cilkParSlowClone
    else
      ableC_Stmt {{
        __closure->state = $intLiteralExpr{top.cilkParInitState};
        $name{s"__${top.cilkParFuncName}_slow_state${toString(top.cilkParInitState)}"}: ;

        if (__closure->joinCounter != 0) {
          if (--(__closure->joinCounter) >= 0) {
            return; // To the scheduler
          }
        }

        $Stmt{loadVariables(top.env)}
        __closure->joinCounter = 0;
      }};
}
