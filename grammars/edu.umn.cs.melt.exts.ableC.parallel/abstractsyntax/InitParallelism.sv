grammar edu:umn:cs:melt:exts:ableC:parallel:abstractsyntax;

abstract production initParallelism
top::Stmt ::= threads::Maybe<Integer> loc::Location
{
  top.pp = ppConcat(text("%parallelize ") :: if threads.isJust 
    then text(toString(threads.fromJust)) :: [] else []);

  top.functionDefs := [];

  forwards to
    parallelism(top.env, 
      if threads.isJust 
      then mkIntConst(threads.fromJust,loc)
      else directCallExpr(name("get_nprocs", location=loc), nilExpr(),
        location=loc)).setupStmt;
}
