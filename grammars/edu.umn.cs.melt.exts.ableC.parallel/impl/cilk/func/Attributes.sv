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
  top.cilkVersion = lifted.cilkVersion;
}

aspect production injectGlobalDeclsStmt
top::Stmt ::= decls::Decls lifted::Stmt
{
  top.cilkVersion = lifted.cilkVersion;
}

aspect production injectGlobalDeclsDecl
top::Decl ::= dcls::Decls
{
  top.cilkVersion = decls(nilDecl());
}

aspect production injectFunctionDeclsDecl
top::Decl ::= decls::Decls
{
  top.cilkVersion = injectFunctionDeclsDecl(decls);
}
