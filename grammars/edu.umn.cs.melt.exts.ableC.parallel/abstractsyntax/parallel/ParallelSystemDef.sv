grammar edu:umn:cs:melt:exts:ableC:parallel:abstractsyntax:parallel;

-- Handler for task spawn
synthesized attribute fSpawn::(Stmt ::= Expr Location SpawnAnnotations);

-- Handler for parallel for loop
synthesized attribute fFor::(Stmt ::= Stmt Location ParallelAnnotations);

closed nonterminal ParallelSystem with parName, fSpawn, fFor, newProd, deleteProd;
