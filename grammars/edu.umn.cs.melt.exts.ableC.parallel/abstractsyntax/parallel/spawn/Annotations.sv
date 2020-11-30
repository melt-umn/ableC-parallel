grammar edu:umn:cs:melt:exts:ableC:parallel:abstractsyntax:parallel:spawn;

synthesized attribute spawnBy :: Maybe<Expr>;
synthesized attribute threads :: [Expr];
synthesized attribute groups :: [Expr];

closed nonterminal SpawnAnnotations with errors, env, returnType, spawnBy, threads, groups;

abstract production consSpawnAnnotations
top::SpawnAnnotations ::= hd::SpawnAnnotation tl::SpawnAnnotations
{
  top.spawnBy = if hd.spawnBy.isJust then hd.spawnBy else tl.spawnBy;
  top.threads = hd.threads ++ tl.threads;
  top.groups = hd.groups ++ tl.groups;

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
  top.threads = [];
  top.groups = [];
}

closed nonterminal SpawnAnnotation with errors, env, returnType, spawnBy, threads, groups, location;

propagate errors on SpawnAnnotation;

aspect default production
top::SpawnAnnotation ::=
{
  top.spawnBy = nothing();
  top.threads = [];
  top.groups = [];
}

abstract production spawnByAnnotation
top::SpawnAnnotation ::= expr::Expr 
{
  top.spawnBy = just(expr);
}

abstract production spawnAsAnnotation -- specify thread object to associate with
top::SpawnAnnotation ::= expr::Expr
{
  top.threads = expr :: [];

  expr.env = top.env;
  top.errors <- case expr.typerep of
                | extType(_, threadType(_)) -> []
                | _ -> [err(expr.location, s"Annotation 'as' on spawn expects object of thread type")]
                end;
}

abstract production spawnInAnnotation -- specify group object to add to
top::SpawnAnnotation ::= expr::Expr
{
  top.groups = expr :: [];
  top.errors <- case expr.typerep of
                | extType(_, groupType(_)) -> []
                | _ -> [err(expr.location, "Annotation 'in' on spawn expects object of group type")]
                end;
}
