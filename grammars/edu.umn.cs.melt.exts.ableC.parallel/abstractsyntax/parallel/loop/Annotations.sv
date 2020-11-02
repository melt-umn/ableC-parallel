grammar edu:umn:cs:melt:exts:ableC:parallel:abstractsyntax:parallel:loop;

synthesized attribute parallelBy :: Maybe<Expr>;

nonterminal ParallelAnnotations with errors, env, returnType, parallelBy;

abstract production consParallelAnnotations
top::ParallelAnnotations ::= hd::ParallelAnnotation tl::ParallelAnnotations
{
  top.parallelBy = if hd.parallelBy.isJust then hd.parallelBy else tl.parallelBy;
  top.errors := hd.errors ++ tl.errors ++
    if hd.parallelBy.isJust && tl.parallelBy.isJust
    then [err(hd.location, "Multiple annotations on parallel for-loop specify the system to use")]
    else [];
}

abstract production nilParallelAnnotations
top::ParallelAnnotations ::=
{
  top.errors := [];
  top.parallelBy = nothing();
}

closed nonterminal ParallelAnnotation with errors, env, returnType, parallelBy, location;

propagate errors on ParallelAnnotation;

aspect default production
top::ParallelAnnotation ::=
{
  top.parallelBy = nothing();
}

abstract production parallelByAnnotation
top::ParallelAnnotation ::= expr::Expr
{
  top.parallelBy = just(expr);
}

abstract production fakeParallelAnnotation
top::ParallelAnnotation ::= expr::Expr
{
}
