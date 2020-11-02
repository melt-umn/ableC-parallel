grammar edu:umn:cs:melt:exts:ableC:parallel:abstractsyntax:locks;

synthesized attribute lockType :: ExtType;
synthesized attribute fAcquire :: (Stmt ::= [Expr]); -- Handler for lock acquire
synthesized attribute fRelease :: (Stmt ::= [Expr]); -- Handler for lock release

closed nonterminal LockSystem with parName, lockType, fAcquire, fRelease;
