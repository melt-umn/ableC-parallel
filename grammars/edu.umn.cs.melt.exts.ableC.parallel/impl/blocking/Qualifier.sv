grammar edu:umn:cs:melt:exts:ableC:parallel:impl:blocking;

marking terminal Blocking_t 'blocking' lexer classes {Keyword, Reserved};

concrete productions top::TypeQualifier_c
| 'blocking' {
    top.typeQualifiers = foldQualifier([blockingQualifier(location=top.location)]);
    top.mutateTypeSpecifiers = [];
  }

abstract production blockingQualifier
top::Qualifier ::=
{
  top.pp = text("blocking");
  top.mangledName = "blocking";
  top.qualIsPositive = true;
  top.qualIsNegative = false;
  top.qualAppliesWithinRef = true;
  top.qualCompat = \qtc::Qualifier ->
    case qtc of blockingQualifier() -> true | _ -> false end;
  top.qualIsHost = false;
  top.errors := [];

  top.lockSystem = just(blockingLockSystem());
  top.syncSystem = just(blockingSyncSystem());
}
