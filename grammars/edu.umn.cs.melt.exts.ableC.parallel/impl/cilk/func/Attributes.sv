grammar edu:umn:cs:melt:exts:ableC:parallel:impl:cilk:func;

synthesized attribute cilkParNeedStates :: Integer occurs on AsmArgument, 
  AsmOperand, AsmOperands, AsmStatement, Decl, Declarator, 
  Declarators, Decls, Expr, Exprs, Init, Initializer, InitList, MaybeExpr,
  MaybeInitializer, Stmt;
inherited attribute cilkParInitState :: Integer occurs on AsmArgument, 
  AsmOperand, AsmOperands, AsmStatement, Decl, Declarator, 
  Declarators, Decls, Expr, Exprs, Init, Initializer, InitList, MaybeExpr,
  MaybeInitializer, Stmt;
autocopy attribute cilkParFuncName :: String occurs on AsmArgument,
  AsmOperand, AsmOperands, AsmStatement, Decl, Declarator,
  Declarators, Decls, Expr, Exprs, Init, Initializer, InitList, MaybeExpr,
  MaybeInitializer, Stmt;

functor attribute cilkParFastClone occurs on AsmArgument, AsmOperand,
  AsmOperands, AsmStatement, Decl, Declarator, Declarators,
  Decls, Expr, Exprs, Init, Initializer, InitList, MaybeExpr,
  MaybeInitializer, Stmt;
functor attribute cilkParSlowClone occurs on AsmArgument, AsmOperand,
  AsmOperands,  AsmStatement, Decl, Declarator, Declarators,
  Decls, Expr, Exprs, Init, Initializer, InitList, MaybeExpr,
  MaybeInitializer, Stmt;

propagate cilkParFastClone, cilkParSlowClone on AsmArgument, AsmOperand,
  AsmOperands, AsmStatement, Decl, Declarator, Declarators,
  Decls, Expr, Exprs, Init, Initializer, InitList, MaybeExpr,
  MaybeInitializer, Stmt 
  excluding returnStmt, injectGlobalDeclsExpr, injectGlobalDeclsStmt,
    injectGlobalDeclsDecl, injectFunctionDeclsDecl;
