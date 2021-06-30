grammar edu:umn:cs:melt:exts:ableC:parallel:exts:balancer:impl:fcfs;

marking terminal Fcfs_t 'fcfs' lexer classes {Keyword, Reserved};

concrete productions top::TypeQualifier_c
| 'fcfs' {
    top.typeQualifiers = foldQualifier([fcfsBalancerQualifier(location=top.location)]);
    top.mutateTypeSpecifiers = [];
  }

abstract production fcfsBalancerQualifier
top::Qualifier ::=
{
  top.pp = text("fcfs");
  top.mangledName = "fcfs";
  top.qualIsPositive = true;
  top.qualIsNegative = false;
  top.qualAppliesWithinRef = true;
  top.qualCompat = \qtc::Qualifier ->
    case qtc of fcfsBalancerQualifier() -> true | _ -> false end;
  top.qualIsHost = false;
  top.errors := [];

  top.balancerSystem = just(fcfsBalancerSystem());
}
