grammar edu:umn:cs:melt:exts:ableC:parallel:concretesyntax;

concrete productions top::Stmt_c
| 'spawn' ex::Expr_c ';' annts::SpawnAnnotations_c {
    top.ast = spawnTask(ex.ast, annts.ast);
  }
| 'sync' ';' {
    top.ast = nullStmt();
  }

closed nonterminal SpawnAnnotations_c with ast<[SpawnAnnotation]>, location;
closed nonterminal SpawnAnnotation_c with ast<SpawnAnnotation>, location;

concrete productions top::SpawnAnnotations_c
| { top.ast = []; }
| hd::SpawnAnnotation_c ';' tl::SpawnAnnotations_c { top.ast = hd.ast :: tl.ast; }

concrete productions top::SpawnAnnotation_c
| 'by' sys::Expr_c {
    top.ast = fakeSpawnAnnotation(sys.ast);
  }
| 'as' nm::Expr_c {
    top.ast = fakeSpawnAnnotation(nm.ast);
  }
| 'in' nm::Expr_c {
    top.ast = fakeSpawnAnnotation(nm.ast);
  }
