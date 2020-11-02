grammar edu:umn:cs:melt:exts:ableC:parallel:abstractsyntax:parallel:loop;

synthesized attribute amount :: Expr;
nonterminal LoopUpdate with amount;

abstract production add
top::LoopUpdate ::= amount::Expr {top.amount = amount;}

abstract production subtract
top::LoopUpdate ::= amount::Expr {top.amount = amount;}
