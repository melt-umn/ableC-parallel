grammar edu:umn:cs:melt:exts:ableC:parallel:impl:vector;

marking terminal Vectorize_t 'vectorize' lexer classes {Keyword, Reserved};

concrete productions top::TypeQualifier_c
| 'vectorize' {
    top.typeQualifiers = foldQualifier([vectorParallelQualifier(location=top.location)]);
    top.mutateTypeSpecifiers = [];
  }

abstract production vectorParallelQualifier
top::Qualifier ::=
{
  top.pp = text("vectorize");
  top.mangledName = "vectorize";
  top.qualIsPositive = true;
  top.qualIsNegative = false;
  top.qualAppliesWithinRef = true;
  top.qualCompat = \qtc::Qualifier ->
    case qtc of vectorParallelQualifier() -> true | _ -> false end;
  top.qualIsHost = false;
  top.errors := [];

  top.parSystem = just(vectorParallelSystem());
}
