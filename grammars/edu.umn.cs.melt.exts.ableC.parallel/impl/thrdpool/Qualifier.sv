grammar edu:umn:cs:melt:exts:ableC:parallel:impl:thrdpool;

marking terminal Thrdpool_t 'thrdpool' lexer classes {Keyword, Reserved};

concrete productions top::TypeQualifier_c
| 'thrdpool' {
    top.typeQualifiers = foldQualifier([thrdpoolParallelQualifier(location=top.location)]);
    top.mutateTypeSpecifiers = [];
  }

abstract production thrdpoolParallelQualifier
top::Qualifier ::=
{
  top.pp = text("thrdpool");
  top.mangledName = "thrdpool";
  top.qualIsPositive = true;
  top.qualIsNegative = false;
  top.qualAppliesWithinRef = true;
  top.qualCompat = \qtc::Qualifier ->
    case qtc of thrdpoolParallelQualifier() -> true | _ -> false end;
  top.qualIsHost = false;
  top.errors := [];

  top.parSystem = just(thrdpoolParallelSystem());
}
