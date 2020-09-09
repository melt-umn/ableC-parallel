grammar edu:umn:cs:melt:exts:ableC:parallel:abstractsyntax;

abstract production systemDeclaration
top::Decl ::= name::Name sys::ParallelSystem
{
  forwards to defsDecl([]);
}

abstract production stopSystem
top::Stmt ::= name::Name
{
  forwards to nullStmt();
}

closed nonterminal ParallelSystem;
