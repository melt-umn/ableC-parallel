grammar artifact;

{- This Silver specification does litte more than list the desired
   extensions, albeit in a somewhat stylized way.

   Files like this can easily be generated automatically from a simple
   list of the desired extensions.
 -}

import edu:umn:cs:melt:ableC:concretesyntax as cst;
import edu:umn:cs:melt:ableC:drivers:compile;


parser extendedParser :: cst:Root {
  edu:umn:cs:melt:ableC:concretesyntax;
  edu:umn:cs:melt:exts:ableC:constructor;
  edu:umn:cs:melt:exts:ableC:parallel;
  edu:umn:cs:melt:exts:ableC:parallel:exts:synchronization;
  edu:umn:cs:melt:exts:ableC:parallel:impl:posix;

  prefer edu:umn:cs:melt:exts:ableC:parallel:exts:synchronization:concretesyntax:Wait_t
    over edu:umn:cs:melt:exts:ableC:parallel:concretesyntax:Wait_t;
} 

function main
IOVal<Integer> ::= args::[String] io_in::IO
{
  return driver(args, io_in, extendedParser);
}
