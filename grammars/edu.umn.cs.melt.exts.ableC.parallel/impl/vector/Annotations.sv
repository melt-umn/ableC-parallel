grammar edu:umn:cs:melt:exts:ableC:parallel:impl:vector;

marking terminal ParBy_t 'par-by' lexer classes {Keyword, Reserved};

concrete productions top::ParallelAnnotation_c
| 'par-by' sys::Expr_c {
    top.ast = parallelFurtherByAnnotation(sys.ast, location=top.location);
  }

synthesized attribute furtherBySystem :: Maybe<Expr> occurs on
  ParallelAnnotation, ParallelAnnotations;

aspect default production
top::ParallelAnnotation ::=
{
  top.furtherBySystem = nothing();
}

abstract production parallelFurtherByAnnotation
top::ParallelAnnotation ::= expr::Expr
{
  top.furtherBySystem = just(expr);
  top.errors := [];
}

aspect production consParallelAnnotations
top::ParallelAnnotations ::= hd::ParallelAnnotation tl::ParallelAnnotations
{
  top.furtherBySystem = if hd.furtherBySystem.isJust then hd.furtherBySystem
                        else tl.furtherBySystem;

  top.errors <-
    if hd.furtherBySystem.isJust && tl.furtherBySystem.isJust
    then [err(hd.location, "Multiple par-by annotations on parallel for-loop not allowed")]
    else [];
}

aspect production nilParallelAnnotations
top::ParallelAnnotations ::=
{
  top.furtherBySystem = nothing();
}
