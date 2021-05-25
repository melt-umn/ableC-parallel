grammar edu:umn:cs:melt:exts:ableC:parallel:impl:workstlr;

marking terminal Workstlr_t 'workstlr' lexer classes {Keyword, Reserved};

concrete productions top::TypeQualifier_c
| 'workstlr' {
    top.typeQualifiers = foldQualifier([workstlrParallelQualifier(location=top.location)]);
    top.mutateTypeSpecifiers = [];
  }

abstract production workstlrParallelQualifier
top::Qualifier ::=
{
  top.pp = text("workstlr");
  top.mangledName = "workstlr";
  top.qualIsPositive = true;
  top.qualIsNegative = false;
  top.qualAppliesWithinRef = true;
  top.qualCompat = \qtc::Qualifier ->
    case qtc of workstlrParallelQualifier() -> true | _ -> false end;
  top.qualIsHost = false;
  top.errors := [];

  top.parSystem = just(workstlrParallelSystem());
}
