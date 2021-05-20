grammar edu:umn:cs:melt:exts:ableC:parallel:abstractsyntax:sync;

function partitionThenMap
Pair<[b] [b]> ::= partitionFunc::(Boolean ::= a) mapFunc::(b ::= a) lst::[a]
{
  local partitioned::Pair<[a] [a]> =
    partition(partitionFunc, lst);

  return
    pair(map(mapFunc, partitioned.fst),
        map(mapFunc, partitioned.snd));
}

abstract production syncTask
top::Stmt ::= tasks::Exprs
{
  top.pp = ppConcat([text("sync"), space(), 
    ppImplode(cat(comma(), space()), tasks.pps)]);
  top.functionDefs := [];
  top.labelDefs := [];

  tasks.env = top.env;

  local exprs :: [Pair<Expr Type>] = 
    zipWith(\e::Expr t::Type -> pair(e, t), tasks.exprList, tasks.typereps);

  local wrongTypes :: [Pair<Expr Type>] =
    filter(\p::Pair<Expr Type> -> 
      case p.snd of
      | extType(_, threadType(_)) -> false
      | extType(_, groupType(_)) -> false
      | _ -> true
      end, exprs);
  local localErrors :: [Message] =
    tasks.errors ++
      map(\p::Pair<Expr Type> -> 
        err(p.fst.location, "Sync can only be used on thread and group objects"), 
        wrongTypes);

  -- First of pair contains threads, second contains groups
  local syncObjects :: Pair<[Pair<Expr SyncSystem>] [Pair<Expr SyncSystem>]> =
    partitionThenMap(
      \p::Pair<Pair<Expr SyncSystem> Type> ->
        case p.snd of
        | extType(_, threadType(_)) -> true
        | extType(_, groupType(_))  -> false
        | _ -> error("Wrong type should be caught by errors attribute")
        end,
      \p::Pair<Pair<Expr SyncSystem> Type> -> p.fst,
      map(\p::Pair<Expr Type> ->
        case p.snd of
        | extType(_, threadType(sys)) -> pair(pair(p.fst, sys), p.snd)
        | extType(_, groupType(sys))  -> pair(pair(p.fst, sys), p.snd)
        | _ -> error("Wrong type should be caught by errors attributes")
        end,
        exprs
      )
    );

  local threads::[Pair<Expr SyncSystem>] = syncObjects.fst;
  local groups ::[Pair<Expr SyncSystem>] = syncObjects.snd;

  local threadSync :: [Stmt] =
    map(
      \sys::SyncSystem ->
          (decorate sys with {env=top.env;
            threads = map(\p::Pair<Expr SyncSystem> -> p.fst,
              filter(
                \p::Pair<Expr SyncSystem> -> p.snd.parName == sys.parName,
                threads
              )
            );
          }).syncThreads,
      nubBy(
        \s1::SyncSystem s2::SyncSystem -> s1.parName == s2.parName,
        map(\p::Pair<Expr SyncSystem> -> p.snd, threads)
      )
    );
  local groupSync :: [Stmt] =
    map(
      \sys::SyncSystem ->
        (decorate sys with {env=top.env;
          groups = map(\p::Pair<Expr SyncSystem> -> p.fst,
            filter(
              \p::Pair<Expr SyncSystem> -> p.snd.parName == sys.parName,
              groups
            )
          );
        }).syncGroups,
      nubBy(
        \s1::SyncSystem s2::SyncSystem -> s1.parName == s2.parName,
        map(\p::Pair<Expr SyncSystem> -> p.snd, groups)
      )
    );

  forwards to 
    if !null(localErrors)
    then warnStmt(localErrors)
    else 
      if null(tasks.typereps)
      then nullStmt() -- handles `sync;` by synchronizing on the implicit group... TODO
      else seqStmt(foldStmt(threadSync), foldStmt(groupSync));
}
