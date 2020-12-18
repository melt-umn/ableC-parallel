grammar edu:umn:cs:melt:exts:ableC:parallel:abstractsyntax:parallel;

synthesized attribute bySystem   :: Maybe<Expr>;

synthesized attribute asThreads  :: [Expr];
synthesized attribute inGroups   :: [Expr];

synthesized attribute publics    :: [Name];
synthesized attribute privates   :: [Name];
synthesized attribute globals    :: [Name];

synthesized attribute numParallelThreads :: Maybe<Expr>;
