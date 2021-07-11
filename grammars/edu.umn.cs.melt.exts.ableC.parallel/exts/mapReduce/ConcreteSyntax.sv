grammar edu:umn:cs:melt:exts:ableC:parallel:exts:mapReduce;

marking terminal MMap_t 'map' lexer classes {Keyword, Reserved};
marking terminal Reduce_t 'reduce' lexer classes {Keyword, Reserved};

terminal IMap_t 'map';

terminal Lambda_t /\\/;

terminal By_t 'by';
terminal From_t 'from';
terminal Fuse_t 'fuse';
terminal SyncBy_t 'sync-by';
terminal ParComb_t 'par-comb';

terminal MapMap_t 'map-map';
terminal ReduceMap_t 'reduce-map';

concrete productions top::AssignExpr_c
| 'reduce' annts::MapReduceAnnts_c '(' func::AssignExpr_c ',' v::AssignExpr_c ','
    arr::MapReduceArray_c ')'
  {
    top.ast = reduceExpr(arr.ast, v.ast, name("__elem", location=top.location),
                name("__prev", location=top.location),
                ableC_Expr { $Expr{func.ast}(__elem, __prev) }, annts.ast,
                location=top.location);
  }
| 'reduce' annts::MapReduceAnnts_c '('
    t::Lambda_t var::Identifier_c v2::Identifier_c '->' body::AssignExpr_c ','
    v::AssignExpr_c ',' arr::MapReduceArray_c  ')' 
  {
    top.ast = reduceExpr(arr.ast, v.ast, var.ast, v2.ast, body.ast, annts.ast,
                location=top.location);
  }
| m::MMap_t annts::MapReduceAnnts_c '(' func::AssignExpr_c ','
    arr::MapReduceArray_c  ')' {
    top.ast = mapExprBridge(mapExpr(arr.ast, name("__var", location=top.location),
                        ableC_Expr { $Expr{func.ast}(__var) }, annts.ast,
                        location=top.location), location=top.location);
  }
| m::MMap_t annts::MapReduceAnnts_c '('
    t::Lambda_t var::Identifier_c '->' body::AssignExpr_c ','
    arr::MapReduceArray_c ')'
  {
    top.ast = mapExprBridge(mapExpr(arr.ast, var.ast, body.ast, annts.ast,
                location=top.location), location=top.location);
  }

nonterminal MapReduceArray_c with location, ast<MapReduceArray>;
concrete productions top::MapReduceArray_c
| arr::Identifier_c ',' len::Expr_c {
    top.ast = arrayExpr(arr.ast, len.ast, location=top.location);
  }
| m::IMap_t annts::MapReduceAnnts_c '(' func::AssignExpr_c ','
    arr::MapReduceArray_c ')'
  {
    top.ast = mapExpr(arr.ast, name("__var", location=top.location),
                      ableC_Expr { $Expr{func.ast}(__var) }, annts.ast,
                      location=top.location);
  }
| m::IMap_t annts::MapReduceAnnts_c '('
    t::Lambda_t var::Identifier_c '->' body::AssignExpr_c ','
    arr::MapReduceArray_c ')'
  {
    top.ast = mapExpr(arr.ast, var.ast, body.ast, annts.ast,
                      location=top.location);
  }

nonterminal MapReduceAnnts_c with ast<MapReduceAnnts>;
concrete productions top::MapReduceAnnts_c
| { top.ast = nilMapReduceAnnts(); }
| '[' annts::MapReduceAnntsList_c ']' { top.ast = annts.ast; }

nonterminal MapReduceAnntsList_c with ast<MapReduceAnnts>;
concrete productions top::MapReduceAnntsList_c
| { top.ast = nilMapReduceAnnts(); }
| annt::MapReduceAnnt_c ';' annts::MapReduceAnntsList_c {
    top.ast = consMapReduceAnnts(annt.ast, annts.ast);
  }

nonterminal MapReduceAnnt_c with location, ast<MapReduceAnnt>;
concrete productions top::MapReduceAnnt_c
| annt::ParallelAnnotation_c {
    top.ast = mapReduceParallelAnnt(annt.ast, location=top.location);
  }
| 'fuse' fusion::Fusion_c {
    top.ast = mapReduceFusionAnnt(fusion.ast, location=top.location);
  }
| 'sync-by' q::TypeQualifier_c {
    top.ast = mapReduceSyncAnnt(q.typeQualifiers, location=top.location);
  }
| 'par-comb' l::Lambda_t v1::Identifier_c v2::Identifier_c '->' bd::Expr_c {
    top.ast = mapReduceParCombAnnt(v1.ast, v2.ast, bd.ast, location=top.location);
  }

nonterminal Fusion_c with location, ast<Fusion>;
concrete productions top::Fusion_c
| 'map-map' { top.ast = mapMapFusion(location=top.location); }
| 'reduce-map' { top.ast = reduceMapFusion(location=top.location); }
