grammar edu:umn:cs:melt:exts:ableC:parallel:abstractsyntax;

abstract production spawnTask
top::Stmt ::= expr::Expr annts::[SpawnAnnotation]
{
  forwards to exprStmt(expr);
}

closed nonterminal SpawnAnnotation;

abstract production fakeSpawnAnnotation
top::SpawnAnnotation ::= expr::Expr
{
}
