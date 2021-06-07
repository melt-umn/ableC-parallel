grammar edu:umn:cs:melt:exts:ableC:parallel:abstractsyntax:parallel:spawn;

synthesized attribute dropShareAnnotation :: Maybe<SpawnAnnotation>;
synthesized attribute dropShareAnnotations :: SpawnAnnotations;

nonterminal SpawnAnnotations with errors, env, controlStmtContext,
  bySystem, asThreads, inGroups, publics, privates, globals,
  dropShareAnnotations;

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
  
  top.dropShareAnnotations =
    case hd.dropShareAnnotation of
    | just(a) -> consSpawnAnnotations(a, tl.dropShareAnnotations)
    | nothing() -> tl.dropShareAnnotations
    end;
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
  top.dropShareAnnotations = nilSpawnAnnotations();
}

closed nonterminal SpawnAnnotation with errors, env, controlStmtContext,
  bySystem, asThreads, inGroups, location, publics, privates, globals,
  dropShareAnnotation;

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
  top.dropShareAnnotation = just(top);
}

abstract production spawnAsAnnotation -- specify thread object to associate with
top::SpawnAnnotation ::= expr::Expr
{
  top.asThreads = expr :: [];
  top.errors <- case expr.typerep of
                | extType(_, threadType(_)) -> []
                | _ -> [err(expr.location, s"Annotation 'as' on spawn expects object of thread type")]
                end;
  top.dropShareAnnotation = just(top);
}

abstract production spawnInAnnotation -- specify group object to add to
top::SpawnAnnotation ::= expr::Expr
{
  top.inGroups = expr :: [];
  top.errors <- case expr.typerep of
                | extType(_, groupType(_)) -> []
                | _ -> [err(expr.location, "Annotation 'in' on spawn expects object of group type")]
                end;
  top.dropShareAnnotation = just(top);
}

abstract production spawnPrivateAnnotation -- specify that a variable should be private to the thread
top::SpawnAnnotation ::= nms::[Name]
{
  top.privates = nms;
  top.dropShareAnnotation = nothing();
}

abstract production spawnPublicAnnotation -- specify that a variable should be shared to the thread
top::SpawnAnnotation ::= nms::[Name]
{
  top.publics = nms;
  top.dropShareAnnotation = nothing();
}

abstract production spawnGlobalAnnotation
top::SpawnAnnotation ::= nms::[Name]
{
  top.globals = nms;
  top.dropShareAnnotation = nothing();
}
