grammar edu:umn:cs:melt:exts:ableC:parallel:abstractsyntax:parallel:spawn;

synthesized attribute spawnBy :: Maybe<Expr>;

closed nonterminal SpawnAnnotations with errors, env, returnType, spawnBy;

abstract production consSpawnAnnotations
top::SpawnAnnotations ::= hd::SpawnAnnotation tl::SpawnAnnotations
{
  top.spawnBy = if hd.spawnBy.isJust then hd.spawnBy else tl.spawnBy;
  top.errors := hd.errors ++ tl.errors ++ 
    if hd.spawnBy.isJust && tl.spawnBy.isJust
    then [err(hd.location, "Multiple annotations on spawn specify the system to use")]
    else [];
  
}

abstract production nilSpawnAnnotations
top::SpawnAnnotations ::= 
{
  top.errors := [];
  top.spawnBy = nothing();
}

closed nonterminal SpawnAnnotation with errors, env, returnType, spawnBy, location;

propagate errors on SpawnAnnotation;

aspect default production
top::SpawnAnnotation ::=
{
  top.spawnBy = nothing();
}

abstract production spawnByAnnotation
top::SpawnAnnotation ::= expr::Expr 
{
  top.spawnBy = just(expr);
}

abstract production fakeSpawnAnnotation
top::SpawnAnnotation ::= expr::Expr
{
}
