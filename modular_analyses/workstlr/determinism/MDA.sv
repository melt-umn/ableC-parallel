grammar determinism;

{- This Silver specification does not generate a useful working
   compiler, it only serves as a grammar for running the modular
   determinism analysis. -}

import edu:umn:cs:melt:ableC:concretesyntax as cst;

parser ablecParParser :: cst:Root {
  edu:umn:cs:melt:ableC:concretesyntax;
  edu:umn:cs:melt:exts:ableC:cilk:concretesyntax;
  edu:umn:cs:melt:exts:ableC:parallel:concretesyntax;
}

copper_mda testConcreteSyntax(ablecParParser) {
  edu:umn:cs:melt:exts:ableC:parallel:impl:workstlr;
}
