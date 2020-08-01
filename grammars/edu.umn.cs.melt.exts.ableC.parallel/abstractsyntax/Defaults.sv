grammar edu:umn:cs:melt:exts:ableC:parallel:abstractsyntax;

abstract production defaultDeclaration
top::Decl ::= feature::ParallelFeature name::Name
{
  forwards to defsDecl([]);
}

closed nonterminal ParallelFeature;

abstract production featureSpawn
top::ParallelFeature ::= 
{}

abstract production featureLock
top::ParallelFeature ::= 
{}

abstract production featureAtomic
top::ParallelFeature ::= 
{}

abstract production featureParallel
top::ParallelFeature ::= 
{}
