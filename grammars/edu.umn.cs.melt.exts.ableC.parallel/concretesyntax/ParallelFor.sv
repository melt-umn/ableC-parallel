grammar edu:umn:cs:melt:exts:ableC:parallel:concretesyntax;

concrete productions top::Stmt_c
| 'parallel' 'for' '(' init::Declaration_c cond::ExprStmt_c iter::Expr_c ')'
      body::Stmt_c {
    top.ast = parallelFor(init.ast, cond.asMaybeExpr, iter.ast,
                          body.ast, nilParallelAnnotations());
  }
| 'parallel' 'for' '(' init::Declaration_c cond::ExprStmt_c iter::Expr_c ')'
      annts::ParallelAnnotations_c body::Stmt_c {
    top.ast = parallelFor(init.ast, cond.asMaybeExpr, iter.ast,
                          body.ast, annts.ast);
  }
| 'parallel' 'for' '(' init::Declaration_c cond::ExprStmt_c iter::Expr_c ')'
      '{' annts::ParallelAnnotations_c body::BlockItemList_c '}' {
    top.ast = parallelFor(init.ast, cond.asMaybeExpr, iter.ast,
                          compoundStmt(foldStmt(body.ast)), annts.ast);
  }

closed nonterminal ParallelAnnotations_c with ast<ParallelAnnotations>, location;
closed nonterminal ParallelAnnotationsTail_c with ast<ParallelAnnotations>, location;
closed nonterminal ParallelAnnotation_c with ast<ParallelAnnotation>, location;

concrete productions top::ParallelAnnotations_c
| hd::ParallelAnnotation_c ';' tl::ParallelAnnotationsTail_c {
    top.ast = consParallelAnnotations(hd.ast, tl.ast);
  }

concrete productions top::ParallelAnnotationsTail_c
| { top.ast = nilParallelAnnotations(); }
| hd::ParallelAnnotation_c ';' tl::ParallelAnnotationsTail_c { 
  top.ast = consParallelAnnotations(hd.ast, tl.ast); 
}

concrete productions top::ParallelAnnotation_c
| 'by' sys::Expr_c {
    top.ast = parallelByAnnotation(sys.ast, location=top.location);
  }
