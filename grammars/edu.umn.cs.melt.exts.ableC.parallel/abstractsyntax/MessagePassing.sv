grammar edu:umn:cs:melt:exts:ableC:parallel:abstractsyntax;

abstract production sendExpr
top::Expr ::= val::Expr sentTo::Name
{
  forwards to mkIntConst(0, top.location);
}

abstract production receiveExpr
top::Expr ::= source::Maybe<Name>
{
  forwards to mkIntConst(0, top.location);
}
