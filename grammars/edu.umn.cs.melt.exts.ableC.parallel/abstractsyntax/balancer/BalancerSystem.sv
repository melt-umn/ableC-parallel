grammar edu:umn:cs:melt:exts:ableC:parallel:abstractsyntax:balancer;

closed nonterminal BalancerSystem with parName, newProd, deleteProd;

synthesized attribute balancerSystem::Maybe<BalancerSystem> occurs on Qualifier;

aspect default production
top::Qualifier ::=
{
  top.balancerSystem = nothing();
}
