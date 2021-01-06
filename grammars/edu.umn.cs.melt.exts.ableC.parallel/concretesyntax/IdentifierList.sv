grammar edu:umn:cs:melt:exts:ableC:parallel:concretesyntax;

nonterminal IdentifierList_c with ast<[Name]>, location;

concrete productions top::IdentifierList_c
| nm::Identifier_c { top.ast = nm.ast :: []; }
| nm::Identifier_c ',' tl::IdentifierList_c { 
    top.ast = nm.ast :: tl.ast;
  }
