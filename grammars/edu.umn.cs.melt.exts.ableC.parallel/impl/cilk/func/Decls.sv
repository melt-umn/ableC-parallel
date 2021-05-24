grammar edu:umn:cs:melt:exts:ableC:parallel:impl:cilk:func;

aspect production consDecl
top::Decls ::= h::Decl t::Decls
{
  top.cilkParNeedStates = h.cilkParNeedStates + t.cilkParNeedStates;
  h.cilkParInitState = top.cilkParInitState;
  t.cilkParInitState = h.cilkParInitState + h.cilkParNeedStates;
}

aspect production nilDecl
top::Decls ::=
{
  top.cilkParNeedStates = 0;
}

aspect default production
top::Decl ::=
{
  top.cilkParNeedStates = 0;
}

aspect production deferredDecl
top::Decl ::= refId::String d::Decl
{
  -- I don't really know what this is, so leaving cilkParNeedStates = 0
  -- Setting this for MWDA
  d.cilkParInitState = top.cilkParInitState;
}

aspect production decls
top::Decl ::= d::Decls
{
  top.cilkParNeedStates = d.cilkParNeedStates;
  d.cilkParInitState = top.cilkParInitState;
}

aspect production variableDecls
top::Decl ::= storage::StorageClasses attrs::Attributes ty::BaseTypeExpr dcls::Declarators
{
  top.cilkParNeedStates = dcls.cilkParNeedStates;
  dcls.cilkParInitState = top.cilkParInitState;
}

aspect production typedefDecls
top::Decl ::= attrs::Attributes ty::BaseTypeExpr dcls::Declarators
{
  top.cilkParNeedStates = dcls.cilkParNeedStates;
  dcls.cilkParInitState = top.cilkParInitState;
}

aspect production staticAssertDecl
top::Decl ::= e::Expr s::String
{
  top.cilkParNeedStates = e.cilkParNeedStates;
  e.cilkParInitState = top.cilkParInitState;
}

aspect production autoDecl
top::Decl ::= n::Name e::Expr
{
  top.cilkParNeedStates = e.cilkParNeedStates;
  e.cilkParInitState = top.cilkParInitState;
}

aspect production consDeclarator
top::Declarators ::= h::Declarator t::Declarators
{
  top.cilkParNeedStates = h.cilkParNeedStates + t.cilkParNeedStates;
  h.cilkParInitState = top.cilkParInitState;
  t.cilkParInitState = h.cilkParInitState + h.cilkParNeedStates;
}

aspect production nilDeclarator
top::Declarators ::=
{
  top.cilkParNeedStates = 0;
}

aspect default production
top::Declarator ::=
{
  top.cilkParNeedStates = 0;
}

aspect production declarator
top::Declarator ::= name::Name ty::TypeModifierExpr attrs::Attributes initializer::MaybeInitializer
{
  top.cilkParNeedStates = initializer.cilkParNeedStates;
  initializer.cilkParInitState = top.cilkParInitState;
}

aspect production injectGlobalDeclsDecl
top::Decl ::= decls::Decls
{
  decls.cilkParInitState = 1; -- Since injected into the global state (really just for MWDA)
  top.cilkParFastClone = injectGlobalDeclsDecl(decls);
  top.cilkParSlowClone = injectGlobalDeclsDecl(decls);
}

aspect production injectFunctionDeclsDecl
top::Decl ::= decls::Decls
{
  decls.cilkParInitState = 1; -- Really just for MWDA, also we handle function decls manually
  top.cilkParFastClone = injectFunctionDeclsDecl(decls);
  top.cilkParSlowClone = injectFunctionDeclsDecl(decls);
}
