grammar edu:umn:cs:melt:exts:ableC:parallel:abstractsyntax:loop;

monoid attribute loopVarErrs :: [Message] with [], ++ occurs on Expr, Decl, Stmt, 
  MaybeExpr, Exprs, ExprOrTypeName, Initializer, MaybeInitializer, Declarators,
  Declarator;

propagate loopVarErrs on Expr, Decl, Stmt, MaybeExpr, Exprs, ExprOrTypeName, 
  Initializer, MaybeInitializer, Declarators, Declarator;

aspect production addressOfExpr
top::Expr ::= e::Expr
{
  top.loopVarErrs <- if isVarExpr(e, top.parLoopVarName)
                     then [err(top.location, "Address of loop variable cannot be taken in parallel for-loop")]
                     else [];
}

aspect production eqExpr
top::Expr ::= lhs::Expr rhs::Expr
{
  top.loopVarErrs <- if isVarExpr(lhs, top.parLoopVarName)
                     then [err(top.location, "A parallel for-loop's loop variable must not be modified in the body")]
                     else [];
}

aspect production mulEqExpr
top::Expr ::= lhs::Expr rhs::Expr
{
  top.loopVarErrs <- if isVarExpr(lhs, top.parLoopVarName)
                     then [err(top.location, "A parallel for-loop's loop variable must not be modified in the body")]
                     else [];
}

aspect production divEqExpr
top::Expr ::= lhs::Expr rhs::Expr
{
  top.loopVarErrs <- if isVarExpr(lhs, top.parLoopVarName)
                     then [err(top.location, "A parallel for-loop's loop variable must not be modified in the body")]
                     else [];
}

aspect production modEqExpr
top::Expr ::= lhs::Expr rhs::Expr
{
  top.loopVarErrs <- if isVarExpr(lhs, top.parLoopVarName)
                     then [err(top.location, "A parallel for-loop's loop variable must not be modified in the body")]
                     else [];
}

aspect production addEqExpr
top::Expr ::= lhs::Expr rhs::Expr
{
  top.loopVarErrs <- if isVarExpr(lhs, top.parLoopVarName)
                     then [err(top.location, "A parallel for-loop's loop variable must not be modified in the body")]
                     else [];
}

aspect production subEqExpr
top::Expr ::= lhs::Expr rhs::Expr
{
  top.loopVarErrs <- if isVarExpr(lhs, top.parLoopVarName)
                     then [err(top.location, "A parallel for-loop's loop variable must not be modified in the body")]
                     else [];
}

aspect production lshEqExpr
top::Expr ::= lhs::Expr rhs::Expr
{
  top.loopVarErrs <- if isVarExpr(lhs, top.parLoopVarName)
                     then [err(top.location, "A parallel for-loop's loop variable must not be modified in the body")]
                     else [];
}

aspect production rshEqExpr
top::Expr ::= lhs::Expr rhs::Expr
{
  top.loopVarErrs <- if isVarExpr(lhs, top.parLoopVarName)
                     then [err(top.location, "A parallel for-loop's loop variable must not be modified in the body")]
                     else [];
}

aspect production andEqExpr
top::Expr ::= lhs::Expr rhs::Expr
{
  top.loopVarErrs <- if isVarExpr(lhs, top.parLoopVarName)
                     then [err(top.location, "A parallel for-loop's loop variable must not be modified in the body")]
                     else [];
}

aspect production xorEqExpr
top::Expr ::= lhs::Expr rhs::Expr
{
  top.loopVarErrs <- if isVarExpr(lhs, top.parLoopVarName)
                     then [err(top.location, "A parallel for-loop's loop variable must not be modified in the body")]
                     else [];
}

aspect production orEqExpr
top::Expr ::= lhs::Expr rhs::Expr
{
  top.loopVarErrs <- if isVarExpr(lhs, top.parLoopVarName)
                     then [err(top.location, "A parallel for-loop's loop variable must not be modified in the body")]
                     else [];
}

aspect production preIncExpr
top::Expr ::= e::Expr
{
  top.loopVarErrs <- if isVarExpr(e, top.parLoopVarName)
                     then [err(top.location, "A parallel for-loop's loop variable must not be modified in the body")]
                     else [];
}

aspect production preDecExpr
top::Expr ::= e::Expr
{
  top.loopVarErrs <- if isVarExpr(e, top.parLoopVarName)
                     then [err(top.location, "A parallel for-loop's loop variable must not be modified in the body")]
                     else [];
}

aspect production postIncExpr
top::Expr ::= e::Expr
{
  top.loopVarErrs <- if isVarExpr(e, top.parLoopVarName)
                     then [err(top.location, "A parallel for-loop's loop variable must not be modified in the body")]
                     else [];
}

aspect production postDecExpr
top::Expr ::= e::Expr
{
  top.loopVarErrs <- if isVarExpr(e, top.parLoopVarName)
                     then [err(top.location, "A parallel for-loop's loop variable must not be modified in the body")]
                     else [];
}
