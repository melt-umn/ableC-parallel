grammar edu:umn:cs:melt:exts:ableC:parallel:impl:cilk:func;

aspect production syncTask
top::Stmt ::= tasks::Exprs
{
  -- A cilk sync does not have any tasks
  local fwrd :: Stmt = new(top.forward);
  fwrd.controlStmtContext = top.controlStmtContext;
  fwrd.env = top.env;
 
  top.cilkVersion =
    if tasks.count > 0
    then fwrd.cilkVersion
    else cilk_syncStmt(loc("fake(ableC-parallel-cilk)", genIntT(), 0, 0, 0, 0, 0));
}
