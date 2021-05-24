grammar edu:umn:cs:melt:exts:ableC:parallel:impl:cilk;

marking terminal Cilk_t 'cilk' lexer classes {Keyword, Reserved};

concrete productions top::TypeQualifier_c
| 'cilk' {
    top.typeQualifiers = foldQualifier([cilkParallelQualifier(location=top.location)]);
    top.mutateTypeSpecifiers = [];
  }

abstract production cilkParallelQualifier
top::Qualifier ::=
{
  top.pp = text("cilk");
  top.mangledName = "cilk";
  top.qualIsPositive = true;
  top.qualIsNegative = false;
  top.qualAppliesWithinRef = true;
  top.qualCompat = \qtc::Qualifier ->
    case qtc of cilkParallelQualifier() -> true | _ -> false end;
  top.qualIsHost = false;
  top.errors := [];

  top.parSystem = just(cilkParallelSystem());
}
