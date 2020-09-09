grammar edu:umn:cs:melt:exts:ableC:parallel:concretesyntax;

--concrete productions top::Declaration_c
--| 'parallel' nm::Identifier_c ':' 'new' decl::ParallelSystem_c ';' {
--    top.ast = systemDeclaration(nm.ast, decl.ast);
--  }


concrete productions top::Stmt_c
| 'parallel' 'delete' nm::Identifier_c ';' {
    top.ast = stopSystem(nm.ast);
  }

closed nonterminal ParallelSystem_c with ast<ParallelSystem>, location;
