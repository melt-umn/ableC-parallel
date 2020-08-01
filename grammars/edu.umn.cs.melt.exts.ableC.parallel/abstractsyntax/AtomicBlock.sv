grammar edu:umn:cs:melt:exts:ableC:parallel:abstractsyntax;

abstract production atomicStmt
top::Stmt ::= locks::[Name] body::Stmt
{
  forwards to nullStmt();
}
