grammar edu:umn:cs:melt:exts:ableC:parallel:exts:synchronization:concretesyntax;

concrete productions top::Stmt_c
| 'wait' 'while' ex::Expr_c ';' { top.ast = waitWhile(ex.ast); }
| 'wait' 'until' ex::Expr_c ';' { top.ast = waitUntil(ex.ast); }
