grammar edu:umn:cs:melt:exts:ableC:parallel:impl:cilk:func;

functor attribute cilkVersion occurs on AsmArgument, AsmOperand,
  AsmOperands, AsmStatement, Decl, Declarator, Declarators,
  Decls, Expr, Exprs, Init, Initializer, InitList, MaybeExpr,
  MaybeInitializer, Stmt;
propagate cilkVersion on AsmArgument, AsmOperand,
  AsmOperands, AsmStatement, Decl, Declarator, Declarators,
  Decls, Expr, Exprs, Init, Initializer, InitList, MaybeExpr,
  MaybeInitializer, Stmt 
  excluding returnStmt, injectGlobalDeclsExpr, injectGlobalDeclsStmt,
    injectGlobalDeclsDecl, injectFunctionDeclsDecl;

aspect production injectGlobalDeclsExpr
top::Expr ::= decls::Decls lifted::Expr
{
  top.cilkVersion = injectGlobalDeclsExpr(decls, lifted.cilkVersion, location=top.location);
}

aspect production injectGlobalDeclsStmt
top::Stmt ::= decls::Decls lifted::Stmt
{
  top.cilkVersion = injectGlobalDeclsStmt(decls, lifted.cilkVersion);
}

aspect production injectGlobalDeclsDecl
top::Decl ::= decls::Decls
{
  top.cilkVersion = injectGlobalDeclsDecl(decls);
}

aspect production injectFunctionDeclsDecl
top::Decl ::= decls::Decls
{
  top.cilkVersion = injectFunctionDeclsDecl(decls);
}
