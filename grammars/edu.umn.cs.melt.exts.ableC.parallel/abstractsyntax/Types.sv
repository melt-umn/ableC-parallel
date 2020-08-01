grammar edu:umn:cs:melt:exts:ableC:parallel:abstractsyntax;

{- TODO: This really shouldn't exist. It is just here filling in until
    an actual implementation for the needed types.  -}
abstract production tempTypeExpr
top::BaseTypeExpr ::= q::Qualifiers loc::Location
{
  forwards to builtinTypeExpr(q, signedType(intType()));
}
