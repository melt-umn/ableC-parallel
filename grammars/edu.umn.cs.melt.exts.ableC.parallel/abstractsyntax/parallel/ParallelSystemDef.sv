grammar edu:umn:cs:melt:exts:ableC:parallel:abstractsyntax:parallel;

synthesized attribute fSpawn::(Stmt ::= Expr);  -- Handler for task spawn

-- Handler for parallel for loop
-- The arguments (in order): loop-variable name, loop-variable type,
--                          loop-var initialization, loop condition,
--                          loop update, loop body
synthesized attribute fFor::(Stmt ::= Name Type Expr LoopBound LoopUpdate Stmt);

closed nonterminal ParallelSystem with parName, fSpawn, fFor, newProd, deleteProd;
