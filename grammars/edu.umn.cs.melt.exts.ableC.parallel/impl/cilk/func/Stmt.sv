grammar edu:umn:cs:melt:exts:ableC:parallel:impl:cilk:func;

aspect default production
top::Stmt ::=
{
  top.cilkParNeedStates = 0;
}

aspect production seqStmt
top::Stmt ::= h::Stmt t::Stmt
{
  top.cilkParNeedStates = h.cilkParNeedStates + t.cilkParNeedStates;
  h.cilkParInitState = top.cilkParInitState;
  t.cilkParInitState = h.cilkParInitState + h.cilkParNeedStates;
}

aspect production compoundStmt
top::Stmt ::= s::Stmt
{
  top.cilkParNeedStates = s.cilkParNeedStates;
  s.cilkParInitState = top.cilkParInitState;
}

aspect production declStmt
top::Stmt ::= d::Decl
{
  top.cilkParNeedStates = d.cilkParNeedStates;
  d.cilkParInitState = top.cilkParInitState;
}

aspect production exprStmt
top::Stmt ::= e::Expr
{
  top.cilkParNeedStates = e.cilkParNeedStates;
  e.cilkParInitState = top.cilkParInitState;
}

aspect production ifStmt
top::Stmt ::= c::Expr t::Stmt e::Stmt
{
  top.cilkParNeedStates = c.cilkParNeedStates + t.cilkParNeedStates + e.cilkParNeedStates;
  c.cilkParInitState = top.cilkParInitState;
  t.cilkParInitState = c.cilkParInitState + c.cilkParNeedStates;
  e.cilkParInitState = t.cilkParInitState + t.cilkParNeedStates;
}

aspect production whileStmt
top::Stmt ::= e::Expr b::Stmt
{
  top.cilkParNeedStates = e.cilkParNeedStates + b.cilkParNeedStates;
  e.cilkParInitState = top.cilkParInitState;
  b.cilkParInitState = e.cilkParInitState + e.cilkParNeedStates;
}

aspect production doStmt
top::Stmt ::= b::Stmt e::Expr
{
  top.cilkParNeedStates = b.cilkParNeedStates + e.cilkParNeedStates;
  b.cilkParInitState = top.cilkParInitState;
  e.cilkParInitState = b.cilkParInitState + b.cilkParNeedStates;
}

aspect production forStmt
top::Stmt ::= i::MaybeExpr c::MaybeExpr s::MaybeExpr b::Stmt
{
  top.cilkParNeedStates = i.cilkParNeedStates + c.cilkParNeedStates
                        + s.cilkParNeedStates + b.cilkParNeedStates;
  i.cilkParInitState = top.cilkParInitState;
  c.cilkParInitState = i.cilkParInitState + i.cilkParNeedStates;
  s.cilkParInitState = c.cilkParInitState + c.cilkParNeedStates;
  b.cilkParInitState = s.cilkParInitState + s.cilkParNeedStates;
}

aspect production forDeclStmt
top::Stmt ::= i::Decl c::MaybeExpr s::MaybeExpr b::Stmt
{
  top.cilkParNeedStates = i.cilkParNeedStates + c.cilkParNeedStates 
                        + s.cilkParNeedStates + b.cilkParNeedStates;
  i.cilkParInitState = top.cilkParInitState;
  c.cilkParInitState = i.cilkParInitState + i.cilkParNeedStates;
  s.cilkParInitState = c.cilkParInitState + c.cilkParNeedStates;
  b.cilkParInitState = s.cilkParInitState + s.cilkParNeedStates;
}

aspect production returnStmt
top::Stmt ::= e::MaybeExpr
{
  top.cilkParNeedStates = e.cilkParNeedStates;
  e.cilkParInitState = top.cilkParInitState;

  top.cilkParFastClone = 
    if e.isJust
    then ableC_Stmt { __retVal = $Expr{e.justTheExpr.fromJust}; goto $name{s"__${top.cilkParFuncName}_fast_return"}; }
    else ableC_Stmt { goto $name{s"__${top.cilkParFuncName}_fast_return"}; };
  top.cilkParSlowClone =
    if e.isJust
    then ableC_Stmt { __retVal = $Expr{e.justTheExpr.fromJust}; goto $name{s"__${top.cilkParFuncName}_slow_return"}; }
    else ableC_Stmt { goto $name{s"__${top.cilkParFuncName}_slow_return"}; };
}

aspect production switchStmt
top::Stmt ::= e::Expr b::Stmt
{
  top.cilkParNeedStates = e.cilkParNeedStates + b.cilkParNeedStates;
  e.cilkParInitState = top.cilkParInitState;
  b.cilkParInitState = e.cilkParInitState + e.cilkParNeedStates;
}

aspect production labelStmt
top::Stmt ::= l::Name s::Stmt
{
  top.cilkParNeedStates = s.cilkParNeedStates;
  s.cilkParInitState = top.cilkParInitState;
}

aspect production caseLabelStmt
top::Stmt ::= v::Expr s::Stmt
{
  top.cilkParNeedStates = v.cilkParNeedStates + s.cilkParNeedStates;
  v.cilkParInitState = top.cilkParInitState;
  s.cilkParInitState = v.cilkParInitState + v.cilkParNeedStates;
}

aspect production defaultLabelStmt
top::Stmt ::= s::Stmt
{
  top.cilkParNeedStates = s.cilkParNeedStates;
  s.cilkParInitState = top.cilkParInitState;
}

aspect production caseLabelRangeStmt
top::Stmt ::= l::Expr u::Expr s::Stmt
{
  top.cilkParNeedStates = l.cilkParNeedStates + u.cilkParNeedStates + s.cilkParNeedStates;
  l.cilkParInitState = top.cilkParInitState;
  u.cilkParInitState = l.cilkParInitState + l.cilkParNeedStates;
  s.cilkParInitState = u.cilkParInitState + u.cilkParNeedStates;
}

aspect production asmStmt
top::Stmt ::= asm::AsmStatement
{
  top.cilkParNeedStates = asm.cilkParNeedStates;
  asm.cilkParInitState = top.cilkParInitState;
}

aspect production injectGlobalDeclsStmt
top::Stmt ::= decls::Decls lifted::Stmt
{
  top.cilkParNeedStates = lifted.cilkParNeedStates;
  lifted.cilkParInitState = top.cilkParInitState;
  decls.cilkParInitState = 1; -- Just setting for MWDA

  top.cilkParFastClone = injectGlobalDeclsStmt(decls, lifted.cilkParFastClone);
  top.cilkParSlowClone = injectGlobalDeclsStmt(decls, lifted.cilkParSlowClone);
}
