grammar edu:umn:cs:melt:exts:ableC:parallel:abstractsyntax:locks;

synthesized attribute lockType :: ExtType;
synthesized attribute fAcquire :: (Stmt ::= [Expr]); -- Handler for lock acquire
synthesized attribute fRelease :: (Stmt ::= [Expr]); -- Handler for lock release

synthesized attribute condType   :: ExtType;
synthesized attribute fWait      :: (Stmt ::= Expr); -- Handler for cv wait
synthesized attribute fSignal    :: (Stmt ::= Expr); -- Handler for cv signal
synthesized attribute fBroadcast :: (Stmt ::= Expr); -- Handler for cv broadcast

closed nonterminal LockSystem with parName, 
                                    lockType, fAcquire, fRelease,
                                    condType, fWait,    fSignal,  fBroadcast;

synthesized attribute lockSystem :: Maybe<LockSystem> occurs on Qualifier;

aspect default production 
top::Qualifier ::=
{
  top.lockSystem = nothing();
}

