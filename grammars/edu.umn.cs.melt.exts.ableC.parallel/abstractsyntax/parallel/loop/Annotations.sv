grammar edu:umn:cs:melt:exts:ableC:parallel:abstractsyntax:parallel:loop;

nonterminal ParallelAnnotations with errors, env, returnType, 
  bySystem, inGroups, publics, privates, globals, numParallelThreads;

abstract production consParallelAnnotations
top::ParallelAnnotations ::= hd::ParallelAnnotation tl::ParallelAnnotations
{
  top.bySystem = if hd.bySystem.isJust then hd.bySystem else tl.bySystem;
  top.inGroups = hd.inGroups ++ tl.inGroups;

  top.publics = hd.publics ++ tl.publics;
  top.privates = hd.privates ++ tl.privates;
  top.globals = hd.globals ++ tl.globals;

  top.numParallelThreads = if hd.numParallelThreads.isJust then hd.numParallelThreads else tl.numParallelThreads;

  top.errors := hd.errors ++ tl.errors ++
    (if hd.bySystem.isJust && tl.bySystem.isJust
    then [err(hd.location, "Multiple annotations on parallel for-loop specify the system to use")]
    else [])
    ++
    if hd.numParallelThreads.isJust && tl.numParallelThreads.isJust
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
  top.numParallelThreads = nothing();
}

closed nonterminal ParallelAnnotation with errors, env, returnType, location,
  bySystem, inGroups, publics, privates, globals, numParallelThreads;

propagate errors on ParallelAnnotation;

aspect default production
top::ParallelAnnotation ::=
{
  top.bySystem = nothing();
  top.inGroups = [];
  top.publics = [];
  top.privates = [];
  top.globals = [];
  top.numParallelThreads = nothing();
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
top::ParallelAnnotation ::= ids::[Name]
{
  top.publics = ids;
}

abstract production parallelPrivateAnnotation
top::ParallelAnnotation ::= ids::[Name]
{
  top.privates = ids;
}

abstract production parallelGlobalAnnotation
top::ParallelAnnotation ::= ids::[Name]
{
  top.globals = ids;
}

abstract production parallelNumThreadsAnnotation
top::ParallelAnnotation ::= num::Expr
{
  top.numParallelThreads = just(num);
}
