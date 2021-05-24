grammar edu:umn:cs:melt:exts:ableC:parallel:impl:posix;

marking terminal Posix_t 'posix' lexer classes {Keyword, Reserved};

concrete productions top::TypeQualifier_c
| 'posix' {
    top.typeQualifiers = foldQualifier([posixParallelQualifier(location=top.location)]);
    top.mutateTypeSpecifiers = [];
  }

abstract production posixParallelQualifier
top::Qualifier ::=
{
  top.pp = text("posix");
  top.mangledName = "posix";
  top.qualIsPositive = true;
  top.qualIsNegative = false;
  top.qualAppliesWithinRef = true;
  top.qualCompat = \qtc::Qualifier ->
    case qtc of posixParallelQualifier() -> true | _ -> false end;
  top.qualIsHost = false;
  top.errors := [];

  top.parSystem = just(posixParallelSystem());
  top.lockSystem = just(posixLockSystem());
  top.syncSystem = just(posixSyncSystem());
}
