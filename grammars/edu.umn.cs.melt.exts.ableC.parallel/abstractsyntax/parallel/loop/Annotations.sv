grammar edu:umn:cs:melt:exts:ableC:parallel:abstractsyntax:parallel:loop;

nonterminal ParallelAnnotations with errors, env, returnType, 
  bySystem, inGroups, publics, privates, globals, numThreads;

abstract production consParallelAnnotations
top::ParallelAnnotations ::= hd::ParallelAnnotation tl::ParallelAnnotations
{
  top.bySystem = if hd.bySystem.isJust then hd.bySystem else tl.bySystem;
  top.inGroups = hd.inGroups ++ tl.inGroups;

  top.publics = hd.publics ++ tl.publics;
  top.privates = hd.privates ++ tl.privates;
  top.globals = hd.globals ++ tl.globals;

  top.numThreads = if hd.numThreads.isJust then hd.numThreads else tl.numThreads;

  top.errors := hd.errors ++ tl.errors ++
    (if hd.bySystem.isJust && tl.bySystem.isJust
    then [err(hd.location, "Multiple annotations on parallel for-loop specify the system to use")]
    else [])
    ++
    if hd.numThreads.isJust && tl.numThreads.isJust
    then [err(hd.location, "Multiple annotations on parallel for-loop specify the number of threads")]
    else [];
}

abstract production nilParallelAnnotations
top::ParallelAnnotations ::=
{
  top.errors := [];
  top.bySystem = nothing();
  top.inGroups = [];
  top.publics = [];
  top.privates = [];
  top.globals = [];
  top.numThreads = nothing();
}

closed nonterminal ParallelAnnotation with errors, env, returnType, location,
  bySystem, inGroups, publics, privates, globals, numThreads;

propagate errors on ParallelAnnotation;

aspect default production
top::ParallelAnnotation ::=
{
  top.bySystem = nothing();
  top.inGroups = [];
  top.publics = [];
  top.privates = [];
  top.globals = [];
  top.numThreads = nothing();
}

abstract production parallelByAnnotation
top::ParallelAnnotation ::= expr::Expr
{
  top.bySystem = just(expr);
}

abstract production parallelInAnnotation
top::ParallelAnnotation ::= group::Expr
{
  top.inGroups = group :: [];
  top.errors <- case group.typerep of
                | extType(_, groupType(_)) -> []
                | _ -> [err(group.location, "Annotation 'in' on spawn expects object of group type")]
                end;
}

abstract production parallelPublicAnnotation
top::ParallelAnnotation ::= id::Name
{
  top.publics = id :: [];
}

abstract production parallelPrivateAnnotation
top::ParallelAnnotation ::= id::Name
{
  top.privates = id :: [];
}

abstract production parallelGlobalAnnotation
top::ParallelAnnotation ::= id::Name
{
  top.globals = id :: [];
}

abstract production parallelNumThreadsAnnotation
top::ParallelAnnotation ::= num::Expr
{
  top.numThreads = just(num);
}
