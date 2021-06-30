grammar edu:umn:cs:melt:exts:ableC:parallel:exts:balancer:base;

marking terminal Balancer_t 'balancer' lexer classes {Keyword, Type, Reserved};

concrete productions top::TypeSpecifier_c
| 'balancer' {
    top.realTypeSpecifiers = [balancerTypeExpr(top.givenQualifiers)];
    top.preTypeSpecifiers = [];
  }
