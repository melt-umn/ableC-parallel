grammar edu:umn:cs:melt:exts:ableC:parallel:concretesyntax;

concrete productions top::Expr_c
| 'this' { top.ast = thisExpr(location=top.location); }
| 'parent' { top.ast = parentExpr(location=top.location); }

concrete productions top::Stmt_c
| 'finish' ';' { top.ast = finishStmt(); }
