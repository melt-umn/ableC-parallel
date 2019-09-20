grammar edu:umn:cs:melt:exts:ableC:parallel:abstractsyntax;

synthesized attribute parallelName :: String;
synthesized attribute minThreads :: Maybe<Integer>;
synthesized attribute maxThreads :: Maybe<Integer>;
synthesized attribute setup :: (Stmt ::= Expr Integer);

nonterminal ParallelExtension with parallelName, minThreads, maxThreads,
  setup;

abstract production parallelExtension
top::ParallelExtension ::= name::String min::Maybe<Integer> 
    max::Maybe<Integer> setup::(Stmt ::= Expr Integer)
{
  top.parallelName = name;
  top.minThreads = min;
  top.maxThreads = max;
  top.setup = setup;
}

synthesized attribute parallelExtensions :: [ParallelExtension] with ++;
synthesized attribute extensionNames :: [String];
synthesized attribute setupStmt :: Stmt;

inherited attribute extensionName :: String;
synthesized attribute extensionNumber :: [Integer];

nonterminal ParallelConstruct with parallelExtensions, extensionNames,
	setupStmt, extensionName, extensionNumber;

abstract production parallelism
top::ParallelConstruct ::= env::Decorated Env nproc::Expr
{
  top.parallelExtensions := [];

	top.extensionNames = map(\e::ParallelExtension -> e.parallelName,
		top.parallelExtensions);

  local extensionNums :: [Pair<ParallelExtension Integer>] =
    foldr(\ext::ParallelExtension res::[Pair<ParallelExtension Integer>] ->
      pair(ext, length(res) + 1) :: res, [], top.parallelExtensions);

  local setups :: [Stmt] =
    map(prepareSetup(_, env), extensionNums);

  local extensionMap :: tm:Map<String Integer> =
    tm:add(map(\p::Pair<ParallelExtension Integer> ->
      pair(p.fst.parallelName, p.snd), extensionNums), tm:empty(compareString));

  top.extensionNumber = tm:lookup(top.extensionName, extensionMap);

  local loc :: Location =
    builtinLoc("parallelization");

  top.setupStmt =
    if null(top.parallelExtensions)
    then nullStmt()
    else foldl(seqStmt,
      seqStmt(exprStmt(directCallExpr(name("setup_thread_system", location=loc),
        nilExpr(), location=loc)), 
        mkIntDeclExpr("__nproc", nproc, loc)), setups);
}

function lookupParallelExtension
Integer ::= ext::String
{
  return head((decorate parallelism(emptyEnv(), mkIntConst(0, builtinLoc("paralleliation")))
    with {extensionName=ext;}).extensionNumber);
}

function prepareSetup
Stmt ::= pr::Pair<ParallelExtension Integer> env::Decorated Env
{
  local ext::ParallelExtension = pr.fst;
  local num::Integer = pr.snd;
  
  local percent :: [Float] =
    lookupParallelExt(ext.parallelName, env);
  
  local loc :: Location = builtinLoc("parallelization");

  local lErrors :: [Message] =
    case percent of
    | [] -> if ext.minThreads.isJust && ext.maxThreads.isJust &&
              ext.minThreads.fromJust == ext.maxThreads.fromJust
            then []
            else [err(loc,
              s"No desired thread amount specified for ${ext.parallelName}")]
    | h :: [] -> []
    | _ -> [err(loc,
            s"Multiple desired thread amounts specified for ${ext.parallelName}")]
    end;

  local minThreads :: Integer = fromMaybe(1, ext.minThreads);

  local maxThreads :: Maybe <Integer> = ext.maxThreads;

  local nproc :: Expr = declRefExpr(name("__nproc", location=loc), location=loc);
  local numThreads :: Expr = declRefExpr(name("numThreads", location=loc), location=loc);

  local threadExpr :: Expr =
    if null(percent)
    then mkIntConst(minThreads, loc)
    else
    stmtExpr(seqStmt(
      mkIntDeclExpr("numThreads", explicitCastExpr(
        typeName(builtinTypeExpr(nilQualifier(), signedType(intType())), baseTypeExpr()), 
        addExpr(
          mulExpr(nproc,
            realConstant(floatConstant(toString(head(percent)), 
              doubleFloatSuffix(), location=loc), location=loc), location=loc), 
          realConstant(floatConstant("0.5", doubleFloatSuffix(), location=loc),
            location=loc), location=loc), location=loc), loc), 
      seqStmt(
        exprStmt(eqExpr(numThreads, conditionalExpr(
          ltExpr(numThreads, mkIntConst(minThreads, loc), location=loc),
          mkIntConst(minThreads, loc),
          numThreads, location=loc), location=loc)),
        if maxThreads.isJust
        then exprStmt(eqExpr(numThreads, conditionalExpr(
          gtExpr(numThreads, mkIntConst(maxThreads.fromJust, loc), location=loc),
          mkIntConst(maxThreads.fromJust, loc),
          numThreads, location=loc), location=loc))
        else nullStmt())), numThreads, location=loc);

  return
    if !null(lErrors)
    then warnStmt(lErrors)
    else ext.setup(threadExpr, num);
}

function generateIndexList
[Pair<String Integer>] ::= lst::[String]
{
  return generateIndexListHelper(lst, 0);
}

function generateIndexListHelper
[Pair<String Integer>] ::= lst::[String] i::Integer
{
  return case lst of
         | [] -> []
         | h :: tl -> pair(h, i) :: generateIndexListHelper(tl, i + 1)
         end;
}
