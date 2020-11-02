grammar edu:umn:cs:melt:exts:ableC:parallel:abstractsyntax:parallel:spawn;

abstract production syncTask
top::Stmt ::= tasks::Exprs
{
  top.pp = ppConcat([text("sync"), space(), 
    ppImplode(cat(comma(), space()), tasks.pps)]);

  -- TODO
  forwards to nullStmt();
}
