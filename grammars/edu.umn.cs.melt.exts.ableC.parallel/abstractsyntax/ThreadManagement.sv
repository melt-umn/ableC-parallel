grammar edu:umn:cs:melt:exts:ableC:parallel:abstractsyntax;

abstract production thisExpr
top::Expr ::=
{
  forwards to mkIntConst(0, top.location);
}

abstract production parentExpr
top::Expr ::=
{
  forwards to mkIntConst(0, top.location);
}

abstract production finishStmt
top::Stmt ::=
{
  forwards to nullStmt();
}
