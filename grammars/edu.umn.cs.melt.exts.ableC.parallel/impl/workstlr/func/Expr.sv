grammar edu:umn:cs:melt:exts:ableC:parallel:impl:workstlr:func;

aspect default production
top::Expr ::=
{
  top.workstlrParNeedStates = 0;
}

aspect production exprAsType
top::Expr ::= e::Expr t::Type
{
  e.workstlrParInitState = top.workstlrParInitState;
  propagate workstlrParForConverted, workstlrParFastClone, workstlrParSlowClone;

  propagate controlStmtContext, env;

  propagate workstlrParFuncName;
}

aspect production qualifiedExpr
top::Expr ::= q::Qualifiers e::Expr
{
  top.workstlrParNeedStates = e.workstlrParNeedStates;
  e.workstlrParInitState = top.workstlrParInitState;

  propagate workstlrParFuncName;
}

aspect production transformedExpr
top::Expr ::= original::Expr resolved::Expr
{
  top.workstlrParNeedStates = resolved.workstlrParNeedStates;
  original.workstlrParInitState = top.workstlrParInitState;
  resolved.workstlrParInitState = top.workstlrParInitState;

  propagate workstlrParFuncName;
}

aspect production parenExpr
top::Expr ::= e::Expr
{
  top.workstlrParNeedStates = e.workstlrParNeedStates;
  e.workstlrParInitState = top.workstlrParInitState;

  propagate workstlrParFuncName;
}

aspect production arraySubscriptExpr
top::Expr ::= lhs::Expr rhs::Expr
{
  top.workstlrParNeedStates = lhs.workstlrParNeedStates + rhs.workstlrParNeedStates;
  lhs.workstlrParInitState = top.workstlrParInitState;
  rhs.workstlrParInitState = top.workstlrParInitState + lhs.workstlrParNeedStates;

  propagate workstlrParFuncName;
}

aspect production callExpr
top::Expr ::= f::Expr a::Exprs
{
  top.workstlrParNeedStates = f.workstlrParNeedStates + a.workstlrParNeedStates;
  f.workstlrParInitState = top.workstlrParInitState;
  a.workstlrParInitState = f.workstlrParInitState + f.workstlrParNeedStates;

  propagate workstlrParFuncName;
}

aspect production memberExpr
top::Expr ::= lhs::Expr deref::Boolean rhs::Name
{
  top.workstlrParNeedStates = lhs.workstlrParNeedStates;
  lhs.workstlrParInitState = top.workstlrParInitState;

  propagate workstlrParFuncName;
}

aspect production conditionalExpr
top::Expr ::= cond::Expr t::Expr e::Expr
{
  top.workstlrParNeedStates = cond.workstlrParNeedStates + t.workstlrParNeedStates + e.workstlrParNeedStates;
  cond.workstlrParInitState = top.workstlrParInitState;
  t.workstlrParInitState = cond.workstlrParInitState + cond.workstlrParNeedStates;
  e.workstlrParInitState = t.workstlrParInitState + t.workstlrParNeedStates;

  propagate workstlrParFuncName;
}

aspect production binaryConditionalExpr
top::Expr ::= cond::Expr e::Expr
{
  top.workstlrParNeedStates = cond.workstlrParNeedStates + e.workstlrParNeedStates;
  cond.workstlrParInitState = top.workstlrParInitState;
  e.workstlrParInitState = cond.workstlrParInitState + cond.workstlrParNeedStates;

  propagate workstlrParFuncName;
}

aspect production explicitCastExpr
top::Expr ::= ty::TypeName e::Expr
{
  top.workstlrParNeedStates = e.workstlrParNeedStates;
  e.workstlrParInitState = top.workstlrParInitState;

  propagate workstlrParFuncName;
}

aspect production compoundLiteralExpr
top::Expr ::= ty::TypeName init::InitList
{
  top.workstlrParNeedStates = init.workstlrParNeedStates;
  init.workstlrParInitState = top.workstlrParInitState;

  propagate workstlrParFuncName;
}

aspect production genericSelectionExpr
top::Expr ::= e::Expr gl::GenericAssocs def::MaybeExpr
{
  top.workstlrParNeedStates = e.workstlrParNeedStates + def.workstlrParNeedStates;
  e.workstlrParInitState = top.workstlrParInitState;
  def.workstlrParInitState = e.workstlrParInitState + e.workstlrParNeedStates;

  propagate workstlrParFuncName;
}

aspect production stmtExpr
top::Expr ::= body::Stmt result::Expr
{
  top.workstlrParNeedStates = body.workstlrParNeedStates + result.workstlrParNeedStates;
  body.workstlrParInitState = top.workstlrParInitState;
  result.workstlrParInitState = body.workstlrParInitState + body.workstlrParNeedStates;

  propagate workstlrParFuncName;
}

aspect production eqExpr
top::Expr ::= lhs::Expr rhs::Expr
{
  top.workstlrParNeedStates = lhs.workstlrParNeedStates + rhs.workstlrParNeedStates;
  lhs.workstlrParInitState = top.workstlrParInitState;
  rhs.workstlrParInitState = top.workstlrParInitState + lhs.workstlrParNeedStates;

  propagate workstlrParFuncName;
}

aspect production mulEqExpr
top::Expr ::= lhs::Expr rhs::Expr
{
  top.workstlrParNeedStates = lhs.workstlrParNeedStates + rhs.workstlrParNeedStates;
  lhs.workstlrParInitState = top.workstlrParInitState;
  rhs.workstlrParInitState = top.workstlrParInitState + lhs.workstlrParNeedStates;

  propagate workstlrParFuncName;
}

aspect production divEqExpr
top::Expr ::= lhs::Expr rhs::Expr
{
  top.workstlrParNeedStates = lhs.workstlrParNeedStates + rhs.workstlrParNeedStates;
  lhs.workstlrParInitState = top.workstlrParInitState;
  rhs.workstlrParInitState = top.workstlrParInitState + lhs.workstlrParNeedStates;

  propagate workstlrParFuncName;
}

aspect production modEqExpr
top::Expr ::= lhs::Expr rhs::Expr
{
  top.workstlrParNeedStates = lhs.workstlrParNeedStates + rhs.workstlrParNeedStates;
  lhs.workstlrParInitState = top.workstlrParInitState;
  rhs.workstlrParInitState = top.workstlrParInitState + lhs.workstlrParNeedStates;

  propagate workstlrParFuncName;
}

aspect production addEqExpr
top::Expr ::= lhs::Expr rhs::Expr
{
  top.workstlrParNeedStates = lhs.workstlrParNeedStates + rhs.workstlrParNeedStates;
  lhs.workstlrParInitState = top.workstlrParInitState;
  rhs.workstlrParInitState = top.workstlrParInitState + lhs.workstlrParNeedStates;

  propagate workstlrParFuncName;
}

aspect production subEqExpr
top::Expr ::= lhs::Expr rhs::Expr
{
  top.workstlrParNeedStates = lhs.workstlrParNeedStates + rhs.workstlrParNeedStates;
  lhs.workstlrParInitState = top.workstlrParInitState;
  rhs.workstlrParInitState = top.workstlrParInitState + lhs.workstlrParNeedStates;

  propagate workstlrParFuncName;
}

aspect production lshEqExpr
top::Expr ::= lhs::Expr rhs::Expr
{
  top.workstlrParNeedStates = lhs.workstlrParNeedStates + rhs.workstlrParNeedStates;
  lhs.workstlrParInitState = top.workstlrParInitState;
  rhs.workstlrParInitState = top.workstlrParInitState + lhs.workstlrParNeedStates;

  propagate workstlrParFuncName;
}

aspect production rshEqExpr
top::Expr ::= lhs::Expr rhs::Expr
{
  top.workstlrParNeedStates = lhs.workstlrParNeedStates + rhs.workstlrParNeedStates;
  lhs.workstlrParInitState = top.workstlrParInitState;
  rhs.workstlrParInitState = top.workstlrParInitState + lhs.workstlrParNeedStates;

  propagate workstlrParFuncName;
}

aspect production andEqExpr
top::Expr ::= lhs::Expr rhs::Expr
{
  top.workstlrParNeedStates = lhs.workstlrParNeedStates + rhs.workstlrParNeedStates;
  lhs.workstlrParInitState = top.workstlrParInitState;
  rhs.workstlrParInitState = top.workstlrParInitState + lhs.workstlrParNeedStates;

  propagate workstlrParFuncName;
}

aspect production xorEqExpr
top::Expr ::= lhs::Expr rhs::Expr
{
  top.workstlrParNeedStates = lhs.workstlrParNeedStates + rhs.workstlrParNeedStates;
  lhs.workstlrParInitState = top.workstlrParInitState;
  rhs.workstlrParInitState = top.workstlrParInitState + lhs.workstlrParNeedStates;

  propagate workstlrParFuncName;
}

aspect production orEqExpr
top::Expr ::= lhs::Expr rhs::Expr
{
  top.workstlrParNeedStates = lhs.workstlrParNeedStates + rhs.workstlrParNeedStates;
  lhs.workstlrParInitState = top.workstlrParInitState;
  rhs.workstlrParInitState = top.workstlrParInitState + lhs.workstlrParNeedStates;

  propagate workstlrParFuncName;
}

aspect production andExpr
top::Expr ::= lhs::Expr rhs::Expr
{
  top.workstlrParNeedStates = lhs.workstlrParNeedStates + rhs.workstlrParNeedStates;
  lhs.workstlrParInitState = top.workstlrParInitState;
  rhs.workstlrParInitState = top.workstlrParInitState + lhs.workstlrParNeedStates;

  propagate workstlrParFuncName;
}

aspect production orExpr
top::Expr ::= lhs::Expr rhs::Expr
{
  top.workstlrParNeedStates = lhs.workstlrParNeedStates + rhs.workstlrParNeedStates;
  lhs.workstlrParInitState = top.workstlrParInitState;
  rhs.workstlrParInitState = top.workstlrParInitState + lhs.workstlrParNeedStates;

  propagate workstlrParFuncName;
}

aspect production andBitExpr
top::Expr ::= lhs::Expr rhs::Expr
{
  top.workstlrParNeedStates = lhs.workstlrParNeedStates + rhs.workstlrParNeedStates;
  lhs.workstlrParInitState = top.workstlrParInitState;
  rhs.workstlrParInitState = top.workstlrParInitState + lhs.workstlrParNeedStates;

  propagate workstlrParFuncName;
}

aspect production orBitExpr
top::Expr ::= lhs::Expr rhs::Expr
{
  top.workstlrParNeedStates = lhs.workstlrParNeedStates + rhs.workstlrParNeedStates;
  lhs.workstlrParInitState = top.workstlrParInitState;
  rhs.workstlrParInitState = top.workstlrParInitState + lhs.workstlrParNeedStates;

  propagate workstlrParFuncName;
}

aspect production xorExpr
top::Expr ::= lhs::Expr rhs::Expr
{
  top.workstlrParNeedStates = lhs.workstlrParNeedStates + rhs.workstlrParNeedStates;
  lhs.workstlrParInitState = top.workstlrParInitState;
  rhs.workstlrParInitState = top.workstlrParInitState + lhs.workstlrParNeedStates;

  propagate workstlrParFuncName;
}

aspect production lshExpr
top::Expr ::= lhs::Expr rhs::Expr
{
  top.workstlrParNeedStates = lhs.workstlrParNeedStates + rhs.workstlrParNeedStates;
  lhs.workstlrParInitState = top.workstlrParInitState;
  rhs.workstlrParInitState = top.workstlrParInitState + lhs.workstlrParNeedStates;

  propagate workstlrParFuncName;
}

aspect production rshExpr
top::Expr ::= lhs::Expr rhs::Expr
{
  top.workstlrParNeedStates = lhs.workstlrParNeedStates + rhs.workstlrParNeedStates;
  lhs.workstlrParInitState = top.workstlrParInitState;
  rhs.workstlrParInitState = top.workstlrParInitState + lhs.workstlrParNeedStates;

  propagate workstlrParFuncName;
}

aspect production equalsExpr
top::Expr ::= lhs::Expr rhs::Expr
{
  top.workstlrParNeedStates = lhs.workstlrParNeedStates + rhs.workstlrParNeedStates;
  lhs.workstlrParInitState = top.workstlrParInitState;
  rhs.workstlrParInitState = top.workstlrParInitState + lhs.workstlrParNeedStates;

  propagate workstlrParFuncName;
}

aspect production notEqualsExpr
top::Expr ::= lhs::Expr rhs::Expr
{
  top.workstlrParNeedStates = lhs.workstlrParNeedStates + rhs.workstlrParNeedStates;
  lhs.workstlrParInitState = top.workstlrParInitState;
  rhs.workstlrParInitState = top.workstlrParInitState + lhs.workstlrParNeedStates;

  propagate workstlrParFuncName;
}

aspect production gtExpr
top::Expr ::= lhs::Expr rhs::Expr
{
  top.workstlrParNeedStates = lhs.workstlrParNeedStates + rhs.workstlrParNeedStates;
  lhs.workstlrParInitState = top.workstlrParInitState;
  rhs.workstlrParInitState = top.workstlrParInitState + lhs.workstlrParNeedStates;

  propagate workstlrParFuncName;
}

aspect production ltExpr
top::Expr ::= lhs::Expr rhs::Expr
{
  top.workstlrParNeedStates = lhs.workstlrParNeedStates + rhs.workstlrParNeedStates;
  lhs.workstlrParInitState = top.workstlrParInitState;
  rhs.workstlrParInitState = top.workstlrParInitState + lhs.workstlrParNeedStates;

  propagate workstlrParFuncName;
}

aspect production gteExpr
top::Expr ::= lhs::Expr rhs::Expr
{
  top.workstlrParNeedStates = lhs.workstlrParNeedStates + rhs.workstlrParNeedStates;
  lhs.workstlrParInitState = top.workstlrParInitState;
  rhs.workstlrParInitState = top.workstlrParInitState + lhs.workstlrParNeedStates;

  propagate workstlrParFuncName;
}

aspect production lteExpr
top::Expr ::= lhs::Expr rhs::Expr
{
  top.workstlrParNeedStates = lhs.workstlrParNeedStates + rhs.workstlrParNeedStates;
  lhs.workstlrParInitState = top.workstlrParInitState;
  rhs.workstlrParInitState = top.workstlrParInitState + lhs.workstlrParNeedStates;

  propagate workstlrParFuncName;
}

aspect production addExpr
top::Expr ::= lhs::Expr rhs::Expr
{
  top.workstlrParNeedStates = lhs.workstlrParNeedStates + rhs.workstlrParNeedStates;
  lhs.workstlrParInitState = top.workstlrParInitState;
  rhs.workstlrParInitState = top.workstlrParInitState + lhs.workstlrParNeedStates;

  propagate workstlrParFuncName;
}

aspect production subExpr
top::Expr ::= lhs::Expr rhs::Expr
{
  top.workstlrParNeedStates = lhs.workstlrParNeedStates + rhs.workstlrParNeedStates;
  lhs.workstlrParInitState = top.workstlrParInitState;
  rhs.workstlrParInitState = top.workstlrParInitState + lhs.workstlrParNeedStates;

  propagate workstlrParFuncName;
}

aspect production mulExpr
top::Expr ::= lhs::Expr rhs::Expr
{
  top.workstlrParNeedStates = lhs.workstlrParNeedStates + rhs.workstlrParNeedStates;
  lhs.workstlrParInitState = top.workstlrParInitState;
  rhs.workstlrParInitState = top.workstlrParInitState + lhs.workstlrParNeedStates;

  propagate workstlrParFuncName;
}

aspect production divExpr
top::Expr ::= lhs::Expr rhs::Expr
{
  top.workstlrParNeedStates = lhs.workstlrParNeedStates + rhs.workstlrParNeedStates;
  lhs.workstlrParInitState = top.workstlrParInitState;
  rhs.workstlrParInitState = top.workstlrParInitState + lhs.workstlrParNeedStates;

  propagate workstlrParFuncName;
}

aspect production modExpr
top::Expr ::= lhs::Expr rhs::Expr
{
  top.workstlrParNeedStates = lhs.workstlrParNeedStates + rhs.workstlrParNeedStates;
  lhs.workstlrParInitState = top.workstlrParInitState;
  rhs.workstlrParInitState = top.workstlrParInitState + lhs.workstlrParNeedStates;

  propagate workstlrParFuncName;
}

aspect production commaExpr
top::Expr ::= lhs::Expr rhs::Expr
{
  top.workstlrParNeedStates = lhs.workstlrParNeedStates + rhs.workstlrParNeedStates;
  lhs.workstlrParInitState = top.workstlrParInitState;
  rhs.workstlrParInitState = top.workstlrParInitState + lhs.workstlrParNeedStates;

  propagate workstlrParFuncName;
}

aspect production vaArgExpr
top::Expr ::= e::Expr ty::TypeName
{
  top.workstlrParNeedStates = e.workstlrParNeedStates;
  e.workstlrParInitState = top.workstlrParInitState;

  propagate workstlrParFuncName;
}

aspect production justExpr
top::MaybeExpr ::= e::Expr
{
  top.workstlrParNeedStates = e.workstlrParNeedStates;
  e.workstlrParInitState = top.workstlrParInitState;

  propagate workstlrParFuncName;
}

aspect production nothingExpr
top::MaybeExpr ::=
{
  top.workstlrParNeedStates = 0;
}

aspect production consExpr
top::Exprs ::= h::Expr t::Exprs
{
  top.workstlrParNeedStates = h.workstlrParNeedStates + t.workstlrParNeedStates;
  h.workstlrParInitState = top.workstlrParInitState;
  t.workstlrParInitState = h.workstlrParInitState + h.workstlrParNeedStates;

  propagate workstlrParFuncName;
}

aspect production nilExpr
top::Exprs ::=
{
  top.workstlrParNeedStates = 0;
}

aspect production preIncExpr
top::Expr ::= e::Expr
{
  top.workstlrParNeedStates = e.workstlrParNeedStates;
  e.workstlrParInitState = top.workstlrParInitState;

  propagate workstlrParFuncName;
}

aspect production preDecExpr
top::Expr ::= e::Expr
{
  top.workstlrParNeedStates = e.workstlrParNeedStates;
  e.workstlrParInitState = top.workstlrParInitState;

  propagate workstlrParFuncName;
}

aspect production postIncExpr
top::Expr ::= e::Expr
{
  top.workstlrParNeedStates = e.workstlrParNeedStates;
  e.workstlrParInitState = top.workstlrParInitState;

  propagate workstlrParFuncName;
}

aspect production postDecExpr
top::Expr ::= e::Expr
{
  top.workstlrParNeedStates = e.workstlrParNeedStates;
  e.workstlrParInitState = top.workstlrParInitState;

  propagate workstlrParFuncName;
}

aspect production addressOfExpr
top::Expr ::= e::Expr
{
  top.workstlrParNeedStates = e.workstlrParNeedStates;
  e.workstlrParInitState = top.workstlrParInitState;

  propagate workstlrParFuncName;
}

aspect production dereferenceExpr
top::Expr ::= e::Expr
{
  top.workstlrParNeedStates = e.workstlrParNeedStates;
  e.workstlrParInitState = top.workstlrParInitState;

  propagate workstlrParFuncName;
}

aspect production positiveExpr
top::Expr ::= e::Expr
{
  top.workstlrParNeedStates = e.workstlrParNeedStates;
  e.workstlrParInitState = top.workstlrParInitState;

  propagate workstlrParFuncName;
}

aspect production negativeExpr
top::Expr ::= e::Expr
{
  top.workstlrParNeedStates = e.workstlrParNeedStates;
  e.workstlrParInitState = top.workstlrParInitState;

  propagate workstlrParFuncName;
}

aspect production bitNegateExpr
top::Expr ::= e::Expr
{
  top.workstlrParNeedStates = e.workstlrParNeedStates;
  e.workstlrParInitState = top.workstlrParInitState;

  propagate workstlrParFuncName;
}

aspect production notExpr
top::Expr ::= e::Expr
{
  top.workstlrParNeedStates = e.workstlrParNeedStates;
  e.workstlrParInitState = top.workstlrParInitState;

  propagate workstlrParFuncName;
}

aspect production isConstantExpr
top::Expr ::= e::Expr
{
  -- Setting this for MWDA, this seems like it should be a compile-time
  -- operation so I think it's safe to leave workstlrParNeedStates = 0
  e.workstlrParInitState = top.workstlrParInitState;

  propagate workstlrParFuncName;
}

aspect production expectExpr
top::Expr ::= eval::Expr expected::Expr
{
  -- Not entirely sure how this works, so not sure if really need this
  top.workstlrParNeedStates = eval.workstlrParNeedStates + expected.workstlrParNeedStates;
  eval.workstlrParInitState = top.workstlrParInitState;
  expected.workstlrParInitState = eval.workstlrParInitState + eval.workstlrParNeedStates;

  propagate workstlrParFuncName;
}

aspect production injectGlobalDeclsExpr
top::Expr ::= decls::Decls lifted::Expr
{
  top.workstlrParNeedStates = lifted.workstlrParNeedStates;
  lifted.workstlrParInitState = top.workstlrParInitState;
  decls.workstlrParInitState = 1; -- Just setting for MWDA

  top.workstlrParFastClone = lifted.workstlrParFastClone;
  top.workstlrParSlowClone = injectGlobalDeclsExpr(decls, lifted.workstlrParSlowClone, location=top.location);

  propagate workstlrParFuncName;
}

aspect production realExpr
top::Expr ::= e::Expr
{
  top.workstlrParNeedStates = e.workstlrParNeedStates;
  e.workstlrParInitState = top.workstlrParInitState;

  propagate workstlrParFuncName;
}

aspect production imagExpr
top::Expr ::= e::Expr
{
  top.workstlrParNeedStates = e.workstlrParNeedStates;
  e.workstlrParInitState = top.workstlrParInitState;

  propagate workstlrParFuncName;
}
