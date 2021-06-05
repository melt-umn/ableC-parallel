grammar edu:umn:cs:melt:exts:ableC:parallel:exts:mapReduce;

synthesized attribute fusion :: Maybe<Fusion>;

nonterminal Fusion with pp;

abstract production mapMapFusion
top::Fusion ::= { top.pp = text("map-map"); }

abstract production reduceMapFusion
top::Fusion ::= { top.pp = text("reduce-map"); }
