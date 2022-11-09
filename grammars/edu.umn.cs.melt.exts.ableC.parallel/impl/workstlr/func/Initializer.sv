grammar edu:umn:cs:melt:exts:ableC:parallel:impl:workstlr:func;

aspect production nothingInitializer
top::MaybeInitializer ::=
{
  top.workstlrParNeedStates = 0;
}

aspect production justInitializer
top::MaybeInitializer ::= i::Initializer
{
  top.workstlrParNeedStates = i.workstlrParNeedStates;
  i.workstlrParInitState = top.workstlrParInitState;

  propagate workstlrParFuncName;
}

aspect production exprInitializer
top::Initializer ::= e::Expr
{
  top.workstlrParNeedStates = e.workstlrParNeedStates;
  e.workstlrParInitState = top.workstlrParInitState;

  propagate workstlrParFuncName;
}

aspect production objectInitializer
top::Initializer ::= l::InitList
{
  top.workstlrParNeedStates = l.workstlrParNeedStates;
  l.workstlrParInitState = top.workstlrParInitState;

  propagate workstlrParFuncName;
}

aspect production consInit
top::InitList ::= h::Init  t::InitList
{
  top.workstlrParNeedStates = h.workstlrParNeedStates + t.workstlrParNeedStates;
  h.workstlrParInitState = top.workstlrParInitState;
  t.workstlrParInitState = h.workstlrParInitState + h.workstlrParNeedStates;

  propagate workstlrParFuncName;
}

aspect production nilInit
top::InitList ::=
{
  top.workstlrParNeedStates = 0;
}

aspect production positionalInit
top::Init ::= i::Initializer
{
  top.workstlrParNeedStates = i.workstlrParNeedStates;
  i.workstlrParInitState = top.workstlrParInitState;

  propagate workstlrParFuncName;
}

aspect production designatedInit
top::Init ::= d::Designator  i::Initializer
{
  top.workstlrParNeedStates = i.workstlrParNeedStates;
  i.workstlrParInitState = top.workstlrParInitState;

  propagate workstlrParFuncName;
}
