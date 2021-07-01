grammar edu:umn:cs:melt:exts:ableC:parallel:concretesyntax;

concrete productions top::TypeSpecifier_c
| 'balancer' {
    top.realTypeSpecifiers = [balancerTypeExpr(top.givenQualifiers)];
    top.preTypeSpecifiers = [];
  }
