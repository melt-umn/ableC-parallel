grammar edu:umn:cs:melt:exts:ableC:parallel:concretesyntax;

nonterminal NamesList_c with ast<[Name]>;

concrete productions top::NamesList_c
| nm::Identifier_t {
    top.ast = name(nm.lexeme, location=nm.location) :: [];
  }
| nm::Identifier_t ',' lst::NamesList_c {
    top.ast = name(nm.lexeme, location=nm.location) :: lst.ast;
  }

