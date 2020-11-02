grammar edu:umn:cs:melt:exts:ableC:parallel:concretesyntax;

concrete productions top::Stmt_c
| 'acquire' lst::ExprList_c ';' { top.ast = acquireLock(foldExpr(lst.ast)); }
| 'release' lst::ExprList_c ';' { top.ast = releaseLock(foldExpr(lst.ast)); }

concrete productions top::TypeSpecifier_c
| 'lock' {
    top.realTypeSpecifiers = [lockTypeExpr(top.givenQualifiers)];
    top.preTypeSpecifiers = [];
  }
