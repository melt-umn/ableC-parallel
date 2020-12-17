grammar edu:umn:cs:melt:exts:ableC:parallel:concretesyntax;

concrete productions top::Stmt_c
| 'spawn' ex::Expr_c ';' annts::SpawnAnnotations_c {
    top.ast = spawnTask(ex.ast, annts.ast);
  }

closed nonterminal SpawnAnnotations_c with ast<SpawnAnnotations>, location;
closed nonterminal SpawnAnnotation_c with ast<SpawnAnnotation>, location;

concrete productions top::SpawnAnnotations_c
| { top.ast = nilSpawnAnnotations(); }
| hd::SpawnAnnotation_c ';' tl::SpawnAnnotations_c { top.ast = consSpawnAnnotations(hd.ast, tl.ast); }

concrete productions top::SpawnAnnotation_c
| 'by' sys::Expr_c {
    top.ast = spawnByAnnotation(sys.ast, location=top.location);
  }
| 'as' nm::Expr_c {
    top.ast = spawnAsAnnotation(nm.ast, location=top.location);
  }
| 'in' nm::Expr_c {
    top.ast = spawnInAnnotation(nm.ast, location=top.location);
  }
| 'private' nm::Identifier_c {
    top.ast = spawnPrivateAnnotation(nm.ast, location=top.location);
  }
| 'public' nm::Identifier_c {
    top.ast = spawnPublicAnnotation(nm.ast, location=top.location);
  }
| 'global' nm::Identifier_c {
    top.ast = spawnGlobalAnnotation(nm.ast, location=top.location);
  }
