grammar edu:umn:cs:melt:exts:ableC:parallel:abstractsyntax:loop;

synthesized attribute bound :: Expr;
nonterminal LoopBound with bound;

abstract production lessThan
top::LoopBound ::= bound::Expr {top.bound = bound;}

abstract production lessThanOrEqual
top::LoopBound ::= bound::Expr {top.bound = bound;}

abstract production greaterThan
top::LoopBound ::= bound::Expr {top.bound = bound;}

abstract production greaterThanOrEqual
top::LoopBound ::= bound::Expr {top.bound = bound;}

abstract production notEqual
top::LoopBound ::= bound::Expr {top.bound = bound;}

