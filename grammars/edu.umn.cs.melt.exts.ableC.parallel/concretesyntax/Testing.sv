grammar edu:umn:cs:melt:exts:ableC:parallel:concretesyntax;

imports edu:umn:cs:melt:exts:ableC:parallel:abstractsyntax:testing;

marking terminal Test_t 'testing' lexer classes {Keyword, Reserved};

concrete productions top::TypeQualifier_c
| 'testing' {
    top.typeQualifiers = foldQualifier([testParallelQualifier(location=top.location)]);
    top.mutateTypeSpecifiers = [];
  }
