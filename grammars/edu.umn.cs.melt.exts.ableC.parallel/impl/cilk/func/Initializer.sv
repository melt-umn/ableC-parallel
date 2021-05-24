grammar edu:umn:cs:melt:exts:ableC:parallel:impl:cilk:func;

aspect production nothingInitializer
top::MaybeInitializer ::=
{
  top.cilkParNeedStates = 0;
}

aspect production justInitializer
top::MaybeInitializer ::= i::Initializer
{
  top.cilkParNeedStates = i.cilkParNeedStates;
  i.cilkParInitState = top.cilkParInitState;
}

aspect production exprInitializer
top::Initializer ::= e::Expr
{
  top.cilkParNeedStates = e.cilkParNeedStates;
  e.cilkParInitState = top.cilkParInitState;
}

aspect production objectInitializer
top::Initializer ::= l::InitList
{
  top.cilkParNeedStates = l.cilkParNeedStates;
  l.cilkParInitState = top.cilkParInitState;
}

aspect production consInit
top::InitList ::= h::Init  t::InitList
{
  top.cilkParNeedStates = h.cilkParNeedStates + t.cilkParNeedStates;
  h.cilkParInitState = top.cilkParInitState;
  t.cilkParInitState = h.cilkParInitState + h.cilkParNeedStates;
}

aspect production nilInit
top::InitList ::=
{
  top.cilkParNeedStates = 0;
}

aspect production positionalInit
top::Init ::= i::Initializer
{
  top.cilkParNeedStates = i.cilkParNeedStates;
  i.cilkParInitState = top.cilkParInitState;
}

aspect production designatedInit
top::Init ::= d::Designator  i::Initializer
{
  top.cilkParNeedStates = i.cilkParNeedStates;
  i.cilkParInitState = top.cilkParInitState;
}
