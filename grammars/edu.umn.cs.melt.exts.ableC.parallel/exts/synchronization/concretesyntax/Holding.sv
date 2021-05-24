grammar edu:umn:cs:melt:exts:ableC:parallel:exts:synchronization:concretesyntax;

concrete productions top::Stmt_c
| 'holding' '(' e::Expr_c ')' 'as' nm::Identifier_t body::Stmt_c {
  top.ast = holdingStmt(e.ast, name(nm.lexeme, location=top.location), body.ast); 
}
