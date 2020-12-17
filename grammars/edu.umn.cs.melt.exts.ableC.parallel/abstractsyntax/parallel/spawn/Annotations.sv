grammar edu:umn:cs:melt:exts:ableC:parallel:abstractsyntax:parallel:spawn;

closed nonterminal SpawnAnnotations with errors, env, returnType, 
  bySystem, asThreads, inGroups, publics, privates, globals;

abstract production consSpawnAnnotations
top::SpawnAnnotations ::= hd::SpawnAnnotation tl::SpawnAnnotations
{
  top.bySystem = if hd.bySystem.isJust then hd.bySystem else tl.bySystem;
  
  top.asThreads = hd.asThreads ++ tl.asThreads;
  top.inGroups = hd.inGroups ++ tl.inGroups;

  top.publics = hd.publics ++ tl.publics;
  top.privates = hd.privates ++ tl.privates;
  top.globals = hd.globals ++ tl.globals;

  top.errors := hd.errors ++ tl.errors ++ 
    if hd.bySystem.isJust && tl.bySystem.isJust
    then [err(hd.location, "Multiple annotations on spawn specify the system to use")]
    else [];
  
}

abstract production nilSpawnAnnotations
top::SpawnAnnotations ::= 
{
  top.errors := [];
  top.bySystem = nothing();
  top.asThreads = [];
  top.inGroups = [];
  top.publics = [];
  top.privates = [];
  top.globals = [];
}

closed nonterminal SpawnAnnotation with errors, env, returnType, 
  bySystem, asThreads, inGroups, location, publics, privates, globals;

propagate errors on SpawnAnnotation;

aspect default production
top::SpawnAnnotation ::=
{
  top.bySystem = nothing();
  top.asThreads = [];
  top.inGroups = [];
  top.publics = [];
  top.privates = [];
  top.globals = [];
}

abstract production spawnByAnnotation
top::SpawnAnnotation ::= expr::Expr 
{
  top.bySystem = just(expr);
}

abstract production spawnAsAnnotation -- specify thread object to associate with
top::SpawnAnnotation ::= expr::Expr
{
  top.asThreads = expr :: [];
  top.errors <- case expr.typerep of
                | extType(_, threadType(_)) -> []
                | _ -> [err(expr.location, s"Annotation 'as' on spawn expects object of thread type")]
                end;
}

abstract production spawnInAnnotation -- specify group object to add to
top::SpawnAnnotation ::= expr::Expr
{
  top.inGroups = expr :: [];
  top.errors <- case expr.typerep of
                | extType(_, groupType(_)) -> []
                | _ -> [err(expr.location, "Annotation 'in' on spawn expects object of group type")]
                end;
}

abstract production spawnPrivateAnnotation -- specify that a variable should be private to the thread
top::SpawnAnnotation ::= nm::Name
{
  top.privates = nm :: [];
}

abstract production spawnPublicAnnotation -- specify that a variable should be shared to the thread
top::SpawnAnnotation ::= nm::Name
{
  top.publics = nm :: [];
}

abstract production spawnGlobalAnnotation
top::SpawnAnnotation ::= nm::Name
{
  top.globals = nm :: [];
}
