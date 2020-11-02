grammar edu:umn:cs:melt:exts:ableC:parallel:concretesyntax;

closed nonterminal ExprList_c with ast<[Expr]>, location;
concrete productions top::ExprList_c
| { top.ast = []; }
| e::AssignExpr_c { top.ast = e.ast :: []; }
| e::AssignExpr_c ',' tl::ExprList_c { top.ast = e.ast :: tl.ast; }
