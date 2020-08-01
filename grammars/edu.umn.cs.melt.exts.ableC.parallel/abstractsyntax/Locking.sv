grammar edu:umn:cs:melt:exts:ableC:parallel:abstractsyntax;

abstract production acquireLocks
top::Stmt ::= locks::[Name]
{
  forwards to nullStmt();
}

abstract production releaseLocks
top::Stmt ::= locks::[Name]
{
  forwards to nullStmt();
}
