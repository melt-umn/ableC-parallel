grammar artifact;

{- This Silver specification does little more than list the desired
   extensions, albeit in a somewhat stylized way. -}

import edu:umn:cs:melt:ableC:concretesyntax as cst;
import edu:umn:cs:melt:ableC:drivers:compile;

parser extendedParser :: cst:Root {
  edu:umn:cs:melt:ableC:concretesyntax;
  edu:umn:cs:melt:exts:ableC:constructor;
  
  edu:umn:cs:melt:exts:ableC:algebraicDataTypes;
  edu:umn:cs:melt:exts:ableC:templating;
  edu:umn:cs:melt:exts:ableC:templateAlgebraicDataTypes;

  edu:umn:cs:melt:exts:ableC:parallel;
  edu:umn:cs:melt:exts:ableC:parallel:impl:posix;
  edu:umn:cs:melt:exts:ableC:parallel:exts:lvars;
}

function main
IOVal<Integer> ::= args::[String] io_in::IO
{
  return driver(args, io_in, extendedParser);
}
