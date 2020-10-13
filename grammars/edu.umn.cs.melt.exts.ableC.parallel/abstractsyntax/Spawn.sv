grammar edu:umn:cs:melt:exts:ableC:parallel:abstractsyntax;

abstract production spawnTask
top::Stmt ::= expr::Expr annts::SpawnAnnotations
{
  forwards to nullStmt();
}

nonterminal SpawnAnnotations;

abstract production emptyAnnotations
top::SpawnAnnotations ::= 
{
}

abstract production fakeAnnotations
top::SpawnAnnotations ::= name::String tl::SpawnAnnotations
{
}
