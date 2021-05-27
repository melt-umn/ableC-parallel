grammar edu:umn:cs:melt:exts:ableC:parallel:impl:cilk:func;

aspect production returnStmt
top::Stmt ::= e::MaybeExpr
{
  top.cilkVersion = cilk_returnStmt(e);
}
