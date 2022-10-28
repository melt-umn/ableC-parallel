grammar edu:umn:cs:melt:exts:ableC:parallel:impl:workstlr:func;

synthesized attribute workstlrParNeedStates :: Integer occurs on AsmArgument, 
  AsmOperand, AsmOperands, AsmStatement, Decl, Declarator, 
  Declarators, Decls, Expr, Exprs, Init, Initializer, InitList, MaybeExpr,
  MaybeInitializer, Stmt;
inherited attribute workstlrParInitState :: Integer occurs on AsmArgument, 
  AsmOperand, AsmOperands, AsmStatement, Decl, Declarator, 
  Declarators, Decls, Expr, Exprs, Init, Initializer, InitList, MaybeExpr,
  MaybeInitializer, Stmt;
inherited attribute workstlrParFuncName :: String occurs on AsmArgument,
  AsmOperand, AsmOperands, AsmStatement, Decl, Declarator,
  Declarators, Decls, Expr, Exprs, Init, Initializer, InitList, MaybeExpr,
  MaybeInitializer, Stmt;

functor attribute workstlrParForConverted occurs on AsmArgument, AsmOperand,
  AsmOperands, AsmStatement, Decl, Declarator, Declarators,
  Decls, Expr, Exprs, Init, Initializer, InitList, MaybeExpr,
  MaybeInitializer, Stmt;
functor attribute workstlrParFastClone occurs on AsmArgument, AsmOperand,
  AsmOperands, AsmStatement, Decl, Declarator, Declarators,
  Decls, Expr, Exprs, Init, Initializer, InitList, MaybeExpr,
  MaybeInitializer, Stmt;
functor attribute workstlrParSlowClone occurs on AsmArgument, AsmOperand,
  AsmOperands,  AsmStatement, Decl, Declarator, Declarators,
  Decls, Expr, Exprs, Init, Initializer, InitList, MaybeExpr,
  MaybeInitializer, Stmt;

propagate workstlrParForConverted on AsmArgument, AsmOperand,
  AsmOperands, AsmStatement, Decl, Declarator, Declarators,
  Decls, Expr, Exprs, Init, Initializer, InitList, MaybeExpr,
  MaybeInitializer, Stmt;

-- NOTE: We drop global injections from the fast clone copy since the slow clone
-- should be placed first, and retains these injections
propagate workstlrParFastClone, workstlrParSlowClone on AsmArgument, AsmOperand,
  AsmOperands, AsmStatement, Decl, Declarator, Declarators,
  Decls, Expr, Exprs, Init, Initializer, InitList, MaybeExpr,
  MaybeInitializer, Stmt 
  excluding returnStmt, injectGlobalDeclsExpr, injectGlobalDeclsStmt,
    injectGlobalDeclsDecl, injectFunctionDeclsDecl;
