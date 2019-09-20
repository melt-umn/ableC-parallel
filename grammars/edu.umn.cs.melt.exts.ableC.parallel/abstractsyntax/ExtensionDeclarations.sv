grammar edu:umn:cs:melt:exts:ableC:parallel:abstractsyntax;

imports edu:umn:cs:melt:ableC:abstractsyntax:construction;
imports edu:umn:cs:melt:ableC:abstractsyntax:env;
imports edu:umn:cs:melt:ableC:abstractsyntax:host;

imports silver:langutil;
imports silver:langutil:pp;
imports silver:util:raw:treemap as tm;

abstract production parallelDeclaration
top::Decl ::= exts::[Pair<String Float>] loc::Location
{
  top.pp = ppConcat([text("%parallel"),
    ppImplode(text(" "), map(\p::Pair<String Float> ->
      ppConcat([text(p.fst), text("="), text(toString(p.snd))]), exts))]);

  local undeclaredExts :: [String] =
    removeAllBy(stringEq, parallelism(top.env, 
      mkIntConst(0, builtinLoc("parallelization"))).extensionNames,
      map(\p::Pair<String Float> -> p.fst, exts));

  forwards to
    if !null(undeclaredExts)
    then warnDecl(map(\nm::String -> err(loc, 
      s"No parallel extension ${nm} in use"), undeclaredExts))
    else defsDecl(
      map(\p::Pair<String Float> -> parallelDef(p.fst, p.snd), exts));
}

synthesized attribute parallelAmounts::Scopes<Float> occurs on Env;
synthesized attribute parallelContribs::Contribs<Float> occurs on Defs, Def;

abstract production parallelDef
top::Def ::= s::String f::Float
{
  top.parallelContribs = [pair(s, f)];
}

aspect production emptyEnv_i
top::Env ::=
{
  top.parallelAmounts = [tm:empty(compareString)];
}

aspect production addEnv_i
top::Env ::= d::Defs e::Decorated Env
{
  top.parallelAmounts = addGlobalScope(gd.parallelContribs,
    addScope(d.parallelContribs, e.parallelAmounts));
}

aspect production openScopeEnv_i
top::Env ::= e::Decorated Env
{
  top.parallelAmounts = tm:empty(compareString) :: e.parallelAmounts;
}

aspect production globalEnv_i
top::Env ::= e::Decorated Env
{
  top.parallelAmounts = [last(e.parallelAmounts)];
}

aspect production nonGlobalEnv_i
top::Env ::= e::Decorated Env
{
  top.parallelAmounts = nonGlobalScope(e.parallelAmounts);
}

aspect production functionEnv_i
top::Env ::= e::Decorated Env
{
  top.parallelAmounts = functionScope(e.parallelAmounts);
}

aspect production nilDefs
top::Defs ::=
{
  top.parallelContribs = [];
}

aspect production consDefs
top::Defs ::= h::Def t::Defs
{
  top.parallelContribs = h.parallelContribs ++ t.parallelContribs;
}

aspect default production
top::Def ::=
{
  top.parallelContribs = [];
}

function lookupParallelExt
[Float] ::= n::String e::Decorated Env
{
  return lookupScope(n, e.parallelAmounts);
}
