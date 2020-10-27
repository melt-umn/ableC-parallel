grammar edu:umn:cs:melt:exts:ableC:parallel:abstractsyntax:spawn;

abstract production syncTask
top::Stmt ::= tasks::Exprs
{
  top.pp = ppConcat([text("sync"), space(), 
    ppImplode(cat(comma(), space()), tasks.pps)]);

  forwards to nullStmt();
}
