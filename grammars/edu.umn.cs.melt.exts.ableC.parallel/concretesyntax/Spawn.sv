grammar edu:umn:cs:melt:exts:ableC:parallel:concretesyntax;

concrete productions top::Stmt_c
| 'spawn' ex::Expr_c ';' annts::SpawnAnnotations_c {
    top.ast = spawnTask(ex.ast, annts.ast);
  }
| 'sync' lst::ExprList_c ';' {
    top.ast = syncTask(foldExpr(lst.ast));
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
    top.ast = fakeSpawnAnnotation(nm.ast, location=top.location);
  }
| 'in' nm::Expr_c {
    top.ast = fakeSpawnAnnotation(nm.ast, location=top.location);
  }

closed nonterminal ExprList_c with ast<[Expr]>, location;
concrete productions top::ExprList_c
| { top.ast = []; }
| e::AssignExpr_c { top.ast = e.ast :: []; }
| e::AssignExpr_c ',' tl::ExprList_c { top.ast = e.ast :: tl.ast; }
