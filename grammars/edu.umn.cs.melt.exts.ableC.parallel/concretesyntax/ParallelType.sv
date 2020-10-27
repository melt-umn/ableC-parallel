grammar edu:umn:cs:melt:exts:ableC:parallel:concretesyntax;

concrete productions top::TypeSpecifier_c
| 'parallel' {
    top.realTypeSpecifiers = [parallelTypeExpr(top.givenQualifiers)];
    top.preTypeSpecifiers = [];
  }
