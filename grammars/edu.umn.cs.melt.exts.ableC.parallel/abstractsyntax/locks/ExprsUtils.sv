grammar edu:umn:cs:melt:exts:ableC:parallel:abstractsyntax:locks;

synthesized attribute exprList :: [Expr] occurs on Exprs;

aspect production consExpr
top::Exprs ::= h::Expr tl::Exprs
{
  top.exprList = h :: tl.exprList;
}

aspect production nilExpr
top::Exprs ::= 
{
  top.exprList = [];
}

aspect production decExprs
top::Exprs ::= e::Decorated Exprs
{
  top.exprList = e.exprList;
}
