grammar edu:umn:cs:melt:exts:ableC:parallel:abstractsyntax:parallel;

synthesized attribute parName::String;          -- Unique name (extension name)
synthesized attribute typeImpl::ExtType;        -- Actual type for declaration
synthesized attribute fSpawn::(Stmt ::= Expr);  -- Handler for task spawn

-- Handler for parallel for loop
synthesized attribute fFor::(Stmt ::= Name Expr LoopBound LoopUpdate Stmt);

closed nonterminal ParallelSystem with parName, typeImpl, fSpawn, fFor;
