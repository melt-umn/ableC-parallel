grammar edu:umn:cs:melt:exts:ableC:parallel:impl:cilk:func;

aspect default production
top::Expr ::=
{
  top.cilkParNeedStates = 0;
}

aspect production qualifiedExpr
top::Expr ::= q::Qualifiers e::Expr
{
  top.cilkParNeedStates = e.cilkParNeedStates;
  e.cilkParInitState = top.cilkParInitState;
}

aspect production transformedExpr
top::Expr ::= original::Expr resolved::Expr
{
  top.cilkParNeedStates = resolved.cilkParNeedStates;
  original.cilkParInitState = top.cilkParInitState;
  resolved.cilkParInitState = top.cilkParInitState;
}

aspect production parenExpr
top::Expr ::= e::Expr
{
  top.cilkParNeedStates = e.cilkParNeedStates;
  e.cilkParInitState = top.cilkParInitState;
}

aspect production arraySubscriptExpr
top::Expr ::= lhs::Expr rhs::Expr
{
  top.cilkParNeedStates = lhs.cilkParNeedStates + rhs.cilkParNeedStates;
  lhs.cilkParInitState = top.cilkParInitState;
  rhs.cilkParInitState = top.cilkParInitState + lhs.cilkParNeedStates;
}

aspect production callExpr
top::Expr ::= f::Expr a::Exprs
{
  top.cilkParNeedStates = f.cilkParNeedStates + a.cilkParNeedStates;
  f.cilkParInitState = top.cilkParInitState;
  a.cilkParInitState = f.cilkParInitState + f.cilkParNeedStates;
}

aspect production memberExpr
top::Expr ::= lhs::Expr deref::Boolean rhs::Name
{
  top.cilkParNeedStates = lhs.cilkParNeedStates;
  lhs.cilkParInitState = top.cilkParInitState;
}

aspect production conditionalExpr
top::Expr ::= cond::Expr t::Expr e::Expr
{
  top.cilkParNeedStates = cond.cilkParNeedStates + t.cilkParNeedStates + e.cilkParNeedStates;
  cond.cilkParInitState = top.cilkParInitState;
  t.cilkParInitState = cond.cilkParInitState + cond.cilkParNeedStates;
  e.cilkParInitState = t.cilkParInitState + t.cilkParNeedStates;
}

aspect production binaryConditionalExpr
top::Expr ::= cond::Expr e::Expr
{
  top.cilkParNeedStates = cond.cilkParNeedStates + e.cilkParNeedStates;
  cond.cilkParInitState = top.cilkParInitState;
  e.cilkParInitState = cond.cilkParInitState + cond.cilkParNeedStates;
}

aspect production explicitCastExpr
top::Expr ::= ty::TypeName e::Expr
{
  top.cilkParNeedStates = e.cilkParNeedStates;
  e.cilkParInitState = top.cilkParInitState;
}

aspect production compoundLiteralExpr
top::Expr ::= ty::TypeName init::InitList
{
  top.cilkParNeedStates = init.cilkParNeedStates;
  init.cilkParInitState = top.cilkParInitState;
}

aspect production genericSelectionExpr
top::Expr ::= e::Expr gl::GenericAssocs def::MaybeExpr
{
  top.cilkParNeedStates = e.cilkParNeedStates + def.cilkParNeedStates;
  e.cilkParInitState = top.cilkParInitState;
  def.cilkParInitState = e.cilkParInitState + e.cilkParNeedStates;
}

aspect production stmtExpr
top::Expr ::= body::Stmt result::Expr
{
  top.cilkParNeedStates = body.cilkParNeedStates + result.cilkParNeedStates;
  body.cilkParInitState = top.cilkParInitState;
  result.cilkParInitState = body.cilkParInitState + body.cilkParNeedStates;
}

aspect production eqExpr
top::Expr ::= lhs::Expr rhs::Expr
{
  top.cilkParNeedStates = lhs.cilkParNeedStates + rhs.cilkParNeedStates;
  lhs.cilkParInitState = top.cilkParInitState;
  rhs.cilkParInitState = top.cilkParInitState + lhs.cilkParNeedStates;
}

aspect production mulEqExpr
top::Expr ::= lhs::Expr rhs::Expr
{
  top.cilkParNeedStates = lhs.cilkParNeedStates + rhs.cilkParNeedStates;
  lhs.cilkParInitState = top.cilkParInitState;
  rhs.cilkParInitState = top.cilkParInitState + lhs.cilkParNeedStates;
}

aspect production divEqExpr
top::Expr ::= lhs::Expr rhs::Expr
{
  top.cilkParNeedStates = lhs.cilkParNeedStates + rhs.cilkParNeedStates;
  lhs.cilkParInitState = top.cilkParInitState;
  rhs.cilkParInitState = top.cilkParInitState + lhs.cilkParNeedStates;
}

aspect production modEqExpr
top::Expr ::= lhs::Expr rhs::Expr
{
  top.cilkParNeedStates = lhs.cilkParNeedStates + rhs.cilkParNeedStates;
  lhs.cilkParInitState = top.cilkParInitState;
  rhs.cilkParInitState = top.cilkParInitState + lhs.cilkParNeedStates;
}

aspect production addEqExpr
top::Expr ::= lhs::Expr rhs::Expr
{
  top.cilkParNeedStates = lhs.cilkParNeedStates + rhs.cilkParNeedStates;
  lhs.cilkParInitState = top.cilkParInitState;
  rhs.cilkParInitState = top.cilkParInitState + lhs.cilkParNeedStates;
}

aspect production subEqExpr
top::Expr ::= lhs::Expr rhs::Expr
{
  top.cilkParNeedStates = lhs.cilkParNeedStates + rhs.cilkParNeedStates;
  lhs.cilkParInitState = top.cilkParInitState;
  rhs.cilkParInitState = top.cilkParInitState + lhs.cilkParNeedStates;
}

aspect production lshEqExpr
top::Expr ::= lhs::Expr rhs::Expr
{
  top.cilkParNeedStates = lhs.cilkParNeedStates + rhs.cilkParNeedStates;
  lhs.cilkParInitState = top.cilkParInitState;
  rhs.cilkParInitState = top.cilkParInitState + lhs.cilkParNeedStates;
}

aspect production rshEqExpr
top::Expr ::= lhs::Expr rhs::Expr
{
  top.cilkParNeedStates = lhs.cilkParNeedStates + rhs.cilkParNeedStates;
  lhs.cilkParInitState = top.cilkParInitState;
  rhs.cilkParInitState = top.cilkParInitState + lhs.cilkParNeedStates;
}

aspect production andEqExpr
top::Expr ::= lhs::Expr rhs::Expr
{
  top.cilkParNeedStates = lhs.cilkParNeedStates + rhs.cilkParNeedStates;
  lhs.cilkParInitState = top.cilkParInitState;
  rhs.cilkParInitState = top.cilkParInitState + lhs.cilkParNeedStates;
}

aspect production xorEqExpr
top::Expr ::= lhs::Expr rhs::Expr
{
  top.cilkParNeedStates = lhs.cilkParNeedStates + rhs.cilkParNeedStates;
  lhs.cilkParInitState = top.cilkParInitState;
  rhs.cilkParInitState = top.cilkParInitState + lhs.cilkParNeedStates;
}

aspect production orEqExpr
top::Expr ::= lhs::Expr rhs::Expr
{
  top.cilkParNeedStates = lhs.cilkParNeedStates + rhs.cilkParNeedStates;
  lhs.cilkParInitState = top.cilkParInitState;
  rhs.cilkParInitState = top.cilkParInitState + lhs.cilkParNeedStates;
}

aspect production andExpr
top::Expr ::= lhs::Expr rhs::Expr
{
  top.cilkParNeedStates = lhs.cilkParNeedStates + rhs.cilkParNeedStates;
  lhs.cilkParInitState = top.cilkParInitState;
  rhs.cilkParInitState = top.cilkParInitState + lhs.cilkParNeedStates;
}

aspect production orExpr
top::Expr ::= lhs::Expr rhs::Expr
{
  top.cilkParNeedStates = lhs.cilkParNeedStates + rhs.cilkParNeedStates;
  lhs.cilkParInitState = top.cilkParInitState;
  rhs.cilkParInitState = top.cilkParInitState + lhs.cilkParNeedStates;
}

aspect production andBitExpr
top::Expr ::= lhs::Expr rhs::Expr
{
  top.cilkParNeedStates = lhs.cilkParNeedStates + rhs.cilkParNeedStates;
  lhs.cilkParInitState = top.cilkParInitState;
  rhs.cilkParInitState = top.cilkParInitState + lhs.cilkParNeedStates;
}

aspect production orBitExpr
top::Expr ::= lhs::Expr rhs::Expr
{
  top.cilkParNeedStates = lhs.cilkParNeedStates + rhs.cilkParNeedStates;
  lhs.cilkParInitState = top.cilkParInitState;
  rhs.cilkParInitState = top.cilkParInitState + lhs.cilkParNeedStates;
}

aspect production xorExpr
top::Expr ::= lhs::Expr rhs::Expr
{
  top.cilkParNeedStates = lhs.cilkParNeedStates + rhs.cilkParNeedStates;
  lhs.cilkParInitState = top.cilkParInitState;
  rhs.cilkParInitState = top.cilkParInitState + lhs.cilkParNeedStates;
}

aspect production lshExpr
top::Expr ::= lhs::Expr rhs::Expr
{
  top.cilkParNeedStates = lhs.cilkParNeedStates + rhs.cilkParNeedStates;
  lhs.cilkParInitState = top.cilkParInitState;
  rhs.cilkParInitState = top.cilkParInitState + lhs.cilkParNeedStates;
}

aspect production rshExpr
top::Expr ::= lhs::Expr rhs::Expr
{
  top.cilkParNeedStates = lhs.cilkParNeedStates + rhs.cilkParNeedStates;
  lhs.cilkParInitState = top.cilkParInitState;
  rhs.cilkParInitState = top.cilkParInitState + lhs.cilkParNeedStates;
}

aspect production equalsExpr
top::Expr ::= lhs::Expr rhs::Expr
{
  top.cilkParNeedStates = lhs.cilkParNeedStates + rhs.cilkParNeedStates;
  lhs.cilkParInitState = top.cilkParInitState;
  rhs.cilkParInitState = top.cilkParInitState + lhs.cilkParNeedStates;
}

aspect production notEqualsExpr
top::Expr ::= lhs::Expr rhs::Expr
{
  top.cilkParNeedStates = lhs.cilkParNeedStates + rhs.cilkParNeedStates;
  lhs.cilkParInitState = top.cilkParInitState;
  rhs.cilkParInitState = top.cilkParInitState + lhs.cilkParNeedStates;
}

aspect production gtExpr
top::Expr ::= lhs::Expr rhs::Expr
{
  top.cilkParNeedStates = lhs.cilkParNeedStates + rhs.cilkParNeedStates;
  lhs.cilkParInitState = top.cilkParInitState;
  rhs.cilkParInitState = top.cilkParInitState + lhs.cilkParNeedStates;
}

aspect production ltExpr
top::Expr ::= lhs::Expr rhs::Expr
{
  top.cilkParNeedStates = lhs.cilkParNeedStates + rhs.cilkParNeedStates;
  lhs.cilkParInitState = top.cilkParInitState;
  rhs.cilkParInitState = top.cilkParInitState + lhs.cilkParNeedStates;
}

aspect production gteExpr
top::Expr ::= lhs::Expr rhs::Expr
{
  top.cilkParNeedStates = lhs.cilkParNeedStates + rhs.cilkParNeedStates;
  lhs.cilkParInitState = top.cilkParInitState;
  rhs.cilkParInitState = top.cilkParInitState + lhs.cilkParNeedStates;
}

aspect production lteExpr
top::Expr ::= lhs::Expr rhs::Expr
{
  top.cilkParNeedStates = lhs.cilkParNeedStates + rhs.cilkParNeedStates;
  lhs.cilkParInitState = top.cilkParInitState;
  rhs.cilkParInitState = top.cilkParInitState + lhs.cilkParNeedStates;
}

aspect production addExpr
top::Expr ::= lhs::Expr rhs::Expr
{
  top.cilkParNeedStates = lhs.cilkParNeedStates + rhs.cilkParNeedStates;
  lhs.cilkParInitState = top.cilkParInitState;
  rhs.cilkParInitState = top.cilkParInitState + lhs.cilkParNeedStates;
}

aspect production subExpr
top::Expr ::= lhs::Expr rhs::Expr
{
  top.cilkParNeedStates = lhs.cilkParNeedStates + rhs.cilkParNeedStates;
  lhs.cilkParInitState = top.cilkParInitState;
  rhs.cilkParInitState = top.cilkParInitState + lhs.cilkParNeedStates;
}

aspect production mulExpr
top::Expr ::= lhs::Expr rhs::Expr
{
  top.cilkParNeedStates = lhs.cilkParNeedStates + rhs.cilkParNeedStates;
  lhs.cilkParInitState = top.cilkParInitState;
  rhs.cilkParInitState = top.cilkParInitState + lhs.cilkParNeedStates;
}

aspect production divExpr
top::Expr ::= lhs::Expr rhs::Expr
{
  top.cilkParNeedStates = lhs.cilkParNeedStates + rhs.cilkParNeedStates;
  lhs.cilkParInitState = top.cilkParInitState;
  rhs.cilkParInitState = top.cilkParInitState + lhs.cilkParNeedStates;
}

aspect production modExpr
top::Expr ::= lhs::Expr rhs::Expr
{
  top.cilkParNeedStates = lhs.cilkParNeedStates + rhs.cilkParNeedStates;
  lhs.cilkParInitState = top.cilkParInitState;
  rhs.cilkParInitState = top.cilkParInitState + lhs.cilkParNeedStates;
}

aspect production commaExpr
top::Expr ::= lhs::Expr rhs::Expr
{
  top.cilkParNeedStates = lhs.cilkParNeedStates + rhs.cilkParNeedStates;
  lhs.cilkParInitState = top.cilkParInitState;
  rhs.cilkParInitState = top.cilkParInitState + lhs.cilkParNeedStates;
}

aspect production vaArgExpr
top::Expr ::= e::Expr ty::TypeName
{
  top.cilkParNeedStates = e.cilkParNeedStates;
  e.cilkParInitState = top.cilkParInitState;
}

aspect production justExpr
top::MaybeExpr ::= e::Expr
{
  top.cilkParNeedStates = e.cilkParNeedStates;
  e.cilkParInitState = top.cilkParInitState;
}

aspect production nothingExpr
top::MaybeExpr ::=
{
  top.cilkParNeedStates = 0;
}

aspect production consExpr
top::Exprs ::= h::Expr t::Exprs
{
  top.cilkParNeedStates = h.cilkParNeedStates + t.cilkParNeedStates;
  h.cilkParInitState = top.cilkParInitState;
  t.cilkParInitState = h.cilkParInitState + h.cilkParNeedStates;
}

aspect production nilExpr
top::Exprs ::=
{
  top.cilkParNeedStates = 0;
}

aspect production preIncExpr
top::Expr ::= e::Expr
{
  top.cilkParNeedStates = e.cilkParNeedStates;
  e.cilkParInitState = top.cilkParInitState;
}

aspect production preDecExpr
top::Expr ::= e::Expr
{
  top.cilkParNeedStates = e.cilkParNeedStates;
  e.cilkParInitState = top.cilkParInitState;
}

aspect production postIncExpr
top::Expr ::= e::Expr
{
  top.cilkParNeedStates = e.cilkParNeedStates;
  e.cilkParInitState = top.cilkParInitState;
}

aspect production postDecExpr
top::Expr ::= e::Expr
{
  top.cilkParNeedStates = e.cilkParNeedStates;
  e.cilkParInitState = top.cilkParInitState;
}

aspect production addressOfExpr
top::Expr ::= e::Expr
{
  top.cilkParNeedStates = e.cilkParNeedStates;
  e.cilkParInitState = top.cilkParInitState;
}

aspect production dereferenceExpr
top::Expr ::= e::Expr
{
  top.cilkParNeedStates = e.cilkParNeedStates;
  e.cilkParInitState = top.cilkParInitState;
}

aspect production positiveExpr
top::Expr ::= e::Expr
{
  top.cilkParNeedStates = e.cilkParNeedStates;
  e.cilkParInitState = top.cilkParInitState;
}

aspect production negativeExpr
top::Expr ::= e::Expr
{
  top.cilkParNeedStates = e.cilkParNeedStates;
  e.cilkParInitState = top.cilkParInitState;
}

aspect production bitNegateExpr
top::Expr ::= e::Expr
{
  top.cilkParNeedStates = e.cilkParNeedStates;
  e.cilkParInitState = top.cilkParInitState;
}

aspect production notExpr
top::Expr ::= e::Expr
{
  top.cilkParNeedStates = e.cilkParNeedStates;
  e.cilkParInitState = top.cilkParInitState;
}

aspect production isConstantExpr
top::Expr ::= e::Expr
{
  -- Setting this for MWDA, this seems like it should be a compile-time
  -- operation so I think it's safe to leave cilkParNeedStates = 0
  e.cilkParInitState = top.cilkParInitState;
}

aspect production expectExpr
top::Expr ::= eval::Expr expected::Expr
{
  -- Not entirely sure how this works, so not sure if really need this
  top.cilkParNeedStates = eval.cilkParNeedStates + expected.cilkParNeedStates;
  eval.cilkParInitState = top.cilkParInitState;
  expected.cilkParInitState = eval.cilkParInitState + eval.cilkParNeedStates;
}

aspect production injectGlobalDeclsExpr
top::Expr ::= decls::Decls lifted::Expr
{
  top.cilkParNeedStates = lifted.cilkParNeedStates;
  lifted.cilkParInitState = top.cilkParInitState;
  decls.cilkParInitState = 1; -- Just setting for MWDA

  top.cilkParFastClone = injectGlobalDeclsExpr(decls, lifted.cilkParFastClone, location=top.location);
  top.cilkParSlowClone = injectGlobalDeclsExpr(decls, lifted.cilkParSlowClone, location=top.location);
}

aspect production realExpr
top::Expr ::= e::Expr
{
  top.cilkParNeedStates = e.cilkParNeedStates;
  e.cilkParInitState = top.cilkParInitState;
}

aspect production imagExpr
top::Expr ::= e::Expr
{
  top.cilkParNeedStates = e.cilkParNeedStates;
  e.cilkParInitState = top.cilkParInitState;
}
