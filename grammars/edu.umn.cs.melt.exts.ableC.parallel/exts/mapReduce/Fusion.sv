grammar edu:umn:cs:melt:exts:ableC:parallel:exts:mapReduce;

synthesized attribute fusion :: Maybe<Fusion>;

inherited attribute annts :: MapReduceAnnts;
inherited attribute innerArray :: MapReduceArray;
inherited attribute mapSpec :: (Name, Expr); -- Variable name and expression body
inherited attribute reduceSpec :: (Expr, Name, Name, Expr); -- inner arrayVar, accumulatorVar, body
synthesized attribute mapFusion :: Either<MapReduceArray [Message]>;
synthesized attribute reduceFusion :: Either<Expr [Message]>;

closed nonterminal Fusion with location, pp, env, controlStmtContext,
  innerArray, mapSpec, reduceSpec, mapFusion, reduceFusion, annts;

abstract production mapMapFusion
top::Fusion ::= 
{
  top.pp = text("map-map");

  {- Replacing the variable with the appropriate transformation can make for
   - weird code since it may repeat those computations, but I think a good
   - optimizing compiler should be able to avoid most of that. The advantage
   - of this approach is that it makes code that is possible to vectorize
   - still, though I don't know how ofter that would come up -}
  top.mapFusion =
    case top.innerArray of
    | mapExpr(inn, iV, iB, _) ->
      left(
        mapExpr(inn, iV,
          replaceExprVariable(top.mapSpec.2, top.mapSpec.1, iB, top.env,
            top.controlStmtContext),
          removeFusion(top.annts),
          location=top.location
        )
      )
    | _ ->
      right(
        [err(top.location, "A map-map fusion cannot be performed because the inner value is not a map")]
      )
    end;

  top.reduceFusion =
    right(
      [err(top.location, "A map-map fusion cannot be performed on a reduce")]
    );
}

abstract production reduceMapFusion
top::Fusion ::=
{
  top.pp = text("reduce-map");

  top.mapFusion =
    right(
      [err(top.location, "A reduce-map fusion cannot be performed on a map")]
    );

  top.reduceFusion =
    case top.innerArray of
    | mapExpr(inn, iV, iB, _) ->
      left(
        reduceExpr(inn, top.reduceSpec.1, iV, top.reduceSpec.3,
          replaceExprVariable(top.reduceSpec.4, top.reduceSpec.2, iB, top.env,
            top.controlStmtContext),
          removeFusion(top.annts),
          location=top.location
        )
      )
    | _ ->
      right(
        [err(top.location, "A reduce-map fusion cannot be performed because the inner value is not a map")]
      )
    end;
}
