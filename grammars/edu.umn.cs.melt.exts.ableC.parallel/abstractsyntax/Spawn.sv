grammar edu:umn:cs:melt:exts:ableC:parallel:abstractsyntax;

abstract production spawnStmt
top::Stmt ::= body::Stmt options::SpawnOptions
{
  forwards to nullStmt();
}

synthesized attribute threadName :: Maybe<Name>;
synthesized attribute systemName :: Maybe<Name>;
synthesized attribute groupNames :: [Name];
nonterminal SpawnOptions with threadName, systemName, groupNames, errors;

abstract production emptyOptions
top::SpawnOptions ::= 
{
  top.threadName = nothing();
  top.systemName = nothing();
  top.groupNames = [];
  top.errors := [];
}

abstract production systemOption
top::SpawnOptions ::= sys::String rest::SpawnOptions loc::Location
{
  top.threadName = rest.threadName;
  top.systemName = just(name(sys, location=loc));
  top.groupNames = rest.groupNames;

  top.errors := case rest.systemName of
                | just(_) -> err(loc, "Spawn can only have one 'by' clause")
                          :: rest.errors
                | nothing() -> rest.errors
                end;
}

abstract production nameOption
top::SpawnOptions ::= nm::String rest::SpawnOptions loc::Location
{
  top.threadName = just(name(nm, location=loc));
  top.systemName = rest.systemName;
  top.groupNames = rest.groupNames;

  top.errors := case rest.systemName of
                | just(_) -> err(loc, "Spawn can only have one 'as' clause")
                          :: rest.errors
                | nothing() -> rest.errors
                end;
}

abstract production groupOption
top::SpawnOptions ::= names::[Name] rest::SpawnOptions loc::Location
{
  top.threadName = rest.threadName;
  top.systemName = rest.systemName;
  top.groupNames = names ++ rest.groupNames;

  top.errors := rest.errors;
}
