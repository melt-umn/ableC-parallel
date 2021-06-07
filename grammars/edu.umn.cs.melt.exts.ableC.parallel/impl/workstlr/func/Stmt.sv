grammar edu:umn:cs:melt:exts:ableC:parallel:impl:workstlr:func;

aspect default production
top::Stmt ::=
{
  top.workstlrParNeedStates = 0;
}

aspect production seqStmt
top::Stmt ::= h::Stmt t::Stmt
{
  top.workstlrParNeedStates = h.workstlrParNeedStates + t.workstlrParNeedStates;
  h.workstlrParInitState = top.workstlrParInitState;
  t.workstlrParInitState = h.workstlrParInitState + h.workstlrParNeedStates;
}

aspect production compoundStmt
top::Stmt ::= s::Stmt
{
  top.workstlrParNeedStates = s.workstlrParNeedStates;
  s.workstlrParInitState = top.workstlrParInitState;
}

aspect production declStmt
top::Stmt ::= d::Decl
{
  top.workstlrParNeedStates = d.workstlrParNeedStates;
  d.workstlrParInitState = top.workstlrParInitState;
}

aspect production exprStmt
top::Stmt ::= e::Expr
{
  top.workstlrParNeedStates = e.workstlrParNeedStates;
  e.workstlrParInitState = top.workstlrParInitState;
}

aspect production ifStmt
top::Stmt ::= c::Expr t::Stmt e::Stmt
{
  top.workstlrParNeedStates = c.workstlrParNeedStates + t.workstlrParNeedStates + e.workstlrParNeedStates;
  c.workstlrParInitState = top.workstlrParInitState;
  t.workstlrParInitState = c.workstlrParInitState + c.workstlrParNeedStates;
  e.workstlrParInitState = t.workstlrParInitState + t.workstlrParNeedStates;
}

aspect production whileStmt
top::Stmt ::= e::Expr b::Stmt
{
  top.workstlrParNeedStates = e.workstlrParNeedStates + b.workstlrParNeedStates;
  e.workstlrParInitState = top.workstlrParInitState;
  b.workstlrParInitState = e.workstlrParInitState + e.workstlrParNeedStates;
}

aspect production doStmt
top::Stmt ::= b::Stmt e::Expr
{
  top.workstlrParNeedStates = b.workstlrParNeedStates + e.workstlrParNeedStates;
  b.workstlrParInitState = top.workstlrParInitState;
  e.workstlrParInitState = b.workstlrParInitState + b.workstlrParNeedStates;
}

aspect production forStmt
top::Stmt ::= i::MaybeExpr c::MaybeExpr s::MaybeExpr b::Stmt
{
  top.workstlrParNeedStates = i.workstlrParNeedStates + c.workstlrParNeedStates
                        + s.workstlrParNeedStates + b.workstlrParNeedStates;
  i.workstlrParInitState = top.workstlrParInitState;
  c.workstlrParInitState = i.workstlrParInitState + i.workstlrParNeedStates;
  s.workstlrParInitState = c.workstlrParInitState + c.workstlrParNeedStates;
  b.workstlrParInitState = s.workstlrParInitState + s.workstlrParNeedStates;
}

aspect production forDeclStmt
top::Stmt ::= i::Decl c::MaybeExpr s::MaybeExpr b::Stmt
{
  top.workstlrParNeedStates = i.workstlrParNeedStates + c.workstlrParNeedStates 
                        + s.workstlrParNeedStates + b.workstlrParNeedStates;
  i.workstlrParInitState = top.workstlrParInitState;
  c.workstlrParInitState = i.workstlrParInitState + i.workstlrParNeedStates;
  s.workstlrParInitState = c.workstlrParInitState + c.workstlrParNeedStates;
  b.workstlrParInitState = s.workstlrParInitState + s.workstlrParNeedStates;
}

aspect production returnStmt
top::Stmt ::= e::MaybeExpr
{
  top.workstlrParNeedStates = e.workstlrParNeedStates;
  e.workstlrParInitState = top.workstlrParInitState;

  local retValErrors :: [Message] =
    case top.controlStmtContext.returnType, e.maybeTyperep of
    | nothing(), nothing() -> []
    | just(builtinType(_, voidType())), nothing() -> []
    | just(expected), just(actual) ->
        if typeAssignableTo(expected, actual) then []
        else [err(e.justTheExpr.fromJust.location,
              "Incorrect return type, expected " ++ showType(expected) ++ " but found " ++ showType(actual))]
    | nothing(), just(actual) -> [err(e.justTheExpr.fromJust.location, "Unexpected return")]
    | just(expected), nothing() ->
      [err(loc("TODOWorkstlrReturn",-1,-1,-1,-1,-1,-1), "Expected return value, but found valueless return")]
    end;

  top.workstlrParFastClone =
    if null(retValErrors)
    then
      if e.isJust
      then ableC_Stmt { __retVal = $Expr{e.justTheExpr.fromJust}; goto $name{s"__${top.workstlrParFuncName}_fast_return"}; }
      else ableC_Stmt { goto $name{s"__${top.workstlrParFuncName}_fast_return"}; }
    else warnStmt(retValErrors);
  top.workstlrParSlowClone =
    if e.isJust
    then ableC_Stmt { __retVal = $Expr{e.justTheExpr.fromJust}; goto $name{s"__${top.workstlrParFuncName}_slow_return"}; }
    else ableC_Stmt { goto $name{s"__${top.workstlrParFuncName}_slow_return"}; };
}

aspect production switchStmt
top::Stmt ::= e::Expr b::Stmt
{
  top.workstlrParNeedStates = e.workstlrParNeedStates + b.workstlrParNeedStates;
  e.workstlrParInitState = top.workstlrParInitState;
  b.workstlrParInitState = e.workstlrParInitState + e.workstlrParNeedStates;
}

aspect production labelStmt
top::Stmt ::= l::Name s::Stmt
{
  top.workstlrParNeedStates = s.workstlrParNeedStates;
  s.workstlrParInitState = top.workstlrParInitState;
}

aspect production caseLabelStmt
top::Stmt ::= v::Expr s::Stmt
{
  top.workstlrParNeedStates = v.workstlrParNeedStates + s.workstlrParNeedStates;
  v.workstlrParInitState = top.workstlrParInitState;
  s.workstlrParInitState = v.workstlrParInitState + v.workstlrParNeedStates;
}

aspect production defaultLabelStmt
top::Stmt ::= s::Stmt
{
  top.workstlrParNeedStates = s.workstlrParNeedStates;
  s.workstlrParInitState = top.workstlrParInitState;
}

aspect production caseLabelRangeStmt
top::Stmt ::= l::Expr u::Expr s::Stmt
{
  top.workstlrParNeedStates = l.workstlrParNeedStates + u.workstlrParNeedStates + s.workstlrParNeedStates;
  l.workstlrParInitState = top.workstlrParInitState;
  u.workstlrParInitState = l.workstlrParInitState + l.workstlrParNeedStates;
  s.workstlrParInitState = u.workstlrParInitState + u.workstlrParNeedStates;
}

aspect production asmStmt
top::Stmt ::= asm::AsmStatement
{
  top.workstlrParNeedStates = asm.workstlrParNeedStates;
  asm.workstlrParInitState = top.workstlrParInitState;
}

aspect production injectGlobalDeclsStmt
top::Stmt ::= decls::Decls lifted::Stmt
{
  top.workstlrParNeedStates = lifted.workstlrParNeedStates;
  lifted.workstlrParInitState = top.workstlrParInitState;
  decls.workstlrParInitState = 1; -- Just setting for MWDA

  top.workstlrParFastClone = injectGlobalDeclsStmt(decls, lifted.workstlrParFastClone);
  top.workstlrParSlowClone = injectGlobalDeclsStmt(decls, lifted.workstlrParSlowClone);
}
