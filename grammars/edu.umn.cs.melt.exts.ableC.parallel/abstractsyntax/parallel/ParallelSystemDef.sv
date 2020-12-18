grammar edu:umn:cs:melt:exts:ableC:parallel:abstractsyntax:parallel;

synthesized attribute fSpawn::(Stmt ::= Expr SpawnAnnotations);  -- Handler for task spawn

-- Handler for parallel for loop
-- The arguments (in order): loop-variable name, loop-variable type,
--                          loop-var initialization, loop condition,
--                          loop update, loop body
synthesized attribute fFor::(Stmt ::= Stmt ParallelAnnotations);

closed nonterminal ParallelSystem with parName, fSpawn, fFor, newProd, deleteProd;
