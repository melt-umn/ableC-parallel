grammar edu:umn:cs:melt:exts:ableC:parallel:concretesyntax;

concrete productions top::Stmt_c
| 'spawn' ex::Expr_c ';' annts::SpawnAnnotations_c {
    --top.ast = spawnTask(ex.ast, annts.ast);
    top.ast = exprStmt(ex.ast);
  }
| 'sync' ';' {
    top.ast = nullStmt();
  }
| 'parallel' 'for' '(' init::Declaration_c cond::ExprStmt_c iter::Expr_c ')'
      body::Stmt_c {
    --top.ast = nullStmt();
    top.ast = forDeclStmt(init.ast, cond.asMaybeExpr, justExpr(iter.ast), body.ast);
  }
| 'parallel' 'for' '(' init::Declaration_c cond::ExprStmt_c iter::Expr_c ')'
      annts::NonEmptySpawnAnnotations_c body::Stmt_c {
    --top.ast = nullStmt();
    top.ast = forDeclStmt(init.ast, cond.asMaybeExpr, justExpr(iter.ast), body.ast);
  }
| 'parallel' 'for' '(' init::Declaration_c cond::ExprStmt_c iter::Expr_c ')'
      '{' annts::NonEmptySpawnAnnotations_c body::BlockItemList_c '}' {
    --top.ast = nullStmt();
    top.ast = forDeclStmt(init.ast, cond.asMaybeExpr, justExpr(iter.ast), 
      compoundStmt(foldStmt(body.ast)));
  }

nonterminal SpawnAnnotations_c with ast<SpawnAnnotations>, location;
nonterminal NonEmptySpawnAnnotations_c with ast<SpawnAnnotations>, location;

concrete productions top::SpawnAnnotations_c
| { top.ast = emptyAnnotations(); }
| annts::NonEmptySpawnAnnotations_c { top.ast = annts.ast; }

concrete productions top::NonEmptySpawnAnnotations_c
| 'by' sys::Identifier_t rest::SpawnAnnotations_c {
    top.ast = fakeAnnotations(sys.lexeme, rest.ast);
  }
| 'as' nm::Identifier_t rest::SpawnAnnotations_c {
    top.ast = fakeAnnotations(nm.lexeme, rest.ast);
  }
| 'in' nm::Identifier_t rest::SpawnAnnotations_c {
    top.ast = fakeAnnotations(nm.lexeme, rest.ast);
  }
