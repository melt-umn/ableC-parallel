grammar edu:umn:cs:melt:exts:ableC:parallel:concretesyntax;

concrete productions top::Stmt_c
| 'sync' lst::ExprList_c ';' {
    top.ast = syncTask(foldExpr(lst.ast));
  }

concrete productions top::TypeSpecifier_c
| 'thread' {
    top.realTypeSpecifiers = [threadTypeExpr(top.givenQualifiers)];
    top.preTypeSpecifiers = [];
  }
| 'group' {
    top.realTypeSpecifiers = [groupTypeExpr(top.givenQualifiers)];
    top.preTypeSpecifiers = [];
  }
