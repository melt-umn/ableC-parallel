grammar edu:umn:cs:melt:exts:ableC:parallel:abstractsyntax;

abstract production syncStmt
top::Stmt ::= names::[Name]
{
  forwards to nullStmt();
}
