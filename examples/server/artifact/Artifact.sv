grammar artifact;

import edu:umn:cs:melt:ableC:concretesyntax as cst;
import edu:umn:cs:melt:ableC:drivers:compile;

parser extendedParser :: cst:Root {
  edu:umn:cs:melt:ableC:concretesyntax;

  edu:umn:cs:melt:exts:ableC:constructor;

  edu:umn:cs:melt:exts:ableC:parallel:impl:thrdpool;
  edu:umn:cs:melt:exts:ableC:parallel:impl:blocking;
  edu:umn:cs:melt:exts:ableC:parallel:impl:posix;
  edu:umn:cs:melt:exts:ableC:cilk;
  edu:umn:cs:melt:exts:ableC:parallel:impl:cilk;

  edu:umn:cs:melt:exts:ableC:parallel prefix with "PR";
  edu:umn:cs:melt:exts:ableC:parallel:exts:synchronization prefix with "SN";

  prefer edu:umn:cs:melt:exts:ableC:parallel:concretesyntax:Spawn_t
    over edu:umn:cs:melt:exts:ableC:cilk:concretesyntax:CilkSpawn_t;

  prefer edu:umn:cs:melt:exts:ableC:parallel:concretesyntax:Sync_t
    over edu:umn:cs:melt:exts:ableC:cilk:concretesyntax:CilkSync_t;

  prefer edu:umn:cs:melt:exts:ableC:parallel:exts:synchronization:concretesyntax:Wait_t
    over edu:umn:cs:melt:exts:ableC:parallel:concretesyntax:Wait_t;
}

function main
IOVal<Integer> ::= args::[String] io_in::IO
{
  return driver(args, io_in, extendedParser);
}
