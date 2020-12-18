grammar edu:umn:cs:melt:exts:ableC:parallel:abstractsyntax:parallel;

synthesized attribute fSpawn::(Stmt ::= Expr SpawnAnnotations);  -- Handler for task spawn

-- Handler for parallel for loop
synthesized attribute fFor::(Stmt ::= Stmt Location ParallelAnnotations);

closed nonterminal ParallelSystem with parName, fSpawn, fFor, newProd, deleteProd;
