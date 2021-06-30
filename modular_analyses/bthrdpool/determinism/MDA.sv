grammar determinism;

{- This Silver specification does not generate a useful working
   compiler, it only serves as a grammar for running the modular
   determinism analysis. -}

import edu:umn:cs:melt:ableC:concretesyntax as cst;

parser ablecParse :: cst:Root {
  edu:umn:cs:melt:ableC:concretesyntax;
}

copper_mda testConcreteSyntax(ablecParse) {
  edu:umn:cs:melt:exts:ableC:parallel:exts:balancer:uses:bthrdpool;
}
