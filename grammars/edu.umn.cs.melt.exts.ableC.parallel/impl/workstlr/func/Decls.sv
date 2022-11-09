grammar edu:umn:cs:melt:exts:ableC:parallel:impl:workstlr:func;

aspect production consDecl
top::Decls ::= h::Decl t::Decls
{
  top.workstlrParNeedStates = h.workstlrParNeedStates + t.workstlrParNeedStates;
  h.workstlrParInitState = top.workstlrParInitState;
  t.workstlrParInitState = h.workstlrParInitState + h.workstlrParNeedStates;

  propagate workstlrParFuncName;
}

aspect production nilDecl
top::Decls ::=
{
  top.workstlrParNeedStates = 0;
}

aspect default production
top::Decl ::=
{
  top.workstlrParNeedStates = 0;
}

aspect production deferredDecl
top::Decl ::= refId::String d::Decl
{
  -- I don't really know what this is, so leaving workstlrParNeedStates = 0
  -- Setting this for MWDA
  d.workstlrParInitState = top.workstlrParInitState;

  propagate workstlrParFuncName;
}

aspect production decls
top::Decl ::= d::Decls
{
  top.workstlrParNeedStates = d.workstlrParNeedStates;
  d.workstlrParInitState = top.workstlrParInitState;

  propagate workstlrParFuncName;
}

aspect production variableDecls
top::Decl ::= storage::StorageClasses attrs::Attributes ty::BaseTypeExpr dcls::Declarators
{
  top.workstlrParNeedStates = dcls.workstlrParNeedStates;
  dcls.workstlrParInitState = top.workstlrParInitState;

  propagate workstlrParFuncName;
}

aspect production typedefDecls
top::Decl ::= attrs::Attributes ty::BaseTypeExpr dcls::Declarators
{
  top.workstlrParNeedStates = dcls.workstlrParNeedStates;
  dcls.workstlrParInitState = top.workstlrParInitState;

  propagate workstlrParFuncName;
}

aspect production staticAssertDecl
top::Decl ::= e::Expr s::String
{
  top.workstlrParNeedStates = e.workstlrParNeedStates;
  e.workstlrParInitState = top.workstlrParInitState;

  propagate workstlrParFuncName;
}

aspect production autoDecl
top::Decl ::= n::Name e::Expr
{
  top.workstlrParNeedStates = e.workstlrParNeedStates;
  e.workstlrParInitState = top.workstlrParInitState;

  propagate workstlrParFuncName;
}

aspect production consDeclarator
top::Declarators ::= h::Declarator t::Declarators
{
  top.workstlrParNeedStates = h.workstlrParNeedStates + t.workstlrParNeedStates;
  h.workstlrParInitState = top.workstlrParInitState;
  t.workstlrParInitState = h.workstlrParInitState + h.workstlrParNeedStates;

  propagate workstlrParFuncName;
}

aspect production nilDeclarator
top::Declarators ::=
{
  top.workstlrParNeedStates = 0;
}

aspect default production
top::Declarator ::=
{
  top.workstlrParNeedStates = 0;
}

aspect production declarator
top::Declarator ::= name::Name ty::TypeModifierExpr attrs::Attributes initializer::MaybeInitializer
{
  top.workstlrParNeedStates = initializer.workstlrParNeedStates;
  initializer.workstlrParInitState = top.workstlrParInitState;

  propagate workstlrParFuncName;
}

aspect production injectGlobalDeclsDecl
top::Decl ::= decls::Decls
{
  decls.workstlrParInitState = 1; -- Since injected into the global state (really just for MWDA)
  top.workstlrParFastClone = edu:umn:cs:melt:ableC:abstractsyntax:host:decls(nilDecl());
  top.workstlrParSlowClone = injectGlobalDeclsDecl(decls);

  propagate workstlrParFuncName;
}

aspect production injectFunctionDeclsDecl
top::Decl ::= decls::Decls
{
  decls.workstlrParInitState = 1; -- Really just for MWDA, also we handle function decls manually
  top.workstlrParFastClone = injectFunctionDeclsDecl(decls);
  top.workstlrParSlowClone = injectFunctionDeclsDecl(decls);

  propagate workstlrParFuncName;
}
