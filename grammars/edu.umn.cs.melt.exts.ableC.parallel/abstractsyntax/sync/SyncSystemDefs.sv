grammar edu:umn:cs:melt:exts:ableC:parallel:abstractsyntax:sync;

synthesized attribute threadType :: ExtType;
synthesized attribute setThread :: (Stmt ::= Expr);
synthesized attribute finishThread :: (Stmt ::= Expr);
-- Taking a list as the argument again lets us do what we do with locks
-- where the extension could pick the order of the synchronization of all
-- threads (and separately groups) that extension is responsible for
synthesized attribute syncThread :: (Stmt ::= [Expr]);

synthesized attribute groupType :: ExtType;
synthesized attribute initGroup :: Expr;
synthesized attribute addGroup :: (Stmt ::= Expr);
synthesized attribute finishGroup :: (Stmt ::= Expr);
synthesized attribute syncGroup :: (Stmt ::= [Expr]);

closed nonterminal SyncSystem with parName, 
          threadType, setThread, finishThread, syncThread,
          groupType, initGroup, addGroup, finishGroup, syncGroup;

synthesized attribute syncSystem ::Maybe<SyncSystem> occurs on Qualifier;

aspect default production
top::Qualifier ::=
{
  top.syncSystem = nothing();
}
