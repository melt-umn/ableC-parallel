grammar edu:umn:cs:melt:exts:ableC:parallel:impl:bworkstlr;

marking terminal BWorkstlr_t 'bworkstlr' lexer classes {Keyword, Reserved};

concrete productions top::TypeQualifier_c
| 'bworkstlr' {
    top.typeQualifiers = foldQualifier([bworkstlrParallelQualifier(location=top.location)]);
    top.mutateTypeSpecifiers = [];
  }

abstract production bworkstlrParallelQualifier
top::Qualifier ::=
{
  top.pp = text("bworkstlr");
  top.mangledName = "bworkstlr";
  top.qualIsPositive = true;
  top.qualIsNegative = false;
  top.qualAppliesWithinRef = true;
  top.qualCompat = \qtc::Qualifier ->
    case qtc of bworkstlrParallelQualifier() -> true | _ -> false end;
  top.qualIsHost = false;
  top.errors := [];

  top.parSystem = just(bworkstlrParallelSystem());
}
