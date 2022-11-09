grammar edu:umn:cs:melt:exts:ableC:parallel:abstractsyntax:locks;

abstract production genericCVOp
top::Stmt ::= cv::Expr sysOp::(Stmt ::= LockSystem Decorated Env Expr) nm::String
{
  cv.env = top.env;

  propagate controlStmtContext;

  top.pp = ppConcat([text(nm), space(), cv.pp]);
  top.functionDefs := [];
  top.labelDefs := [];

  local localErrors :: [Message] = cv.errors
    ++ case cv.typerep of
       | extType(_, condvarType(_)) -> []
       | pointerType(_, extType(_, condvarType(_))) -> []
       | _ -> [err(cv.location, nm ++ " can only be used on objects of type condvar")]
       end;
  
  local lockSystem :: LockSystem = 
    case cv.typerep of 
    | extType(_, condvarType(s)) -> s 
    | pointerType(_, extType(_, condvarType(s))) -> s
    | _ -> error("Wrong type should be caught by errors attribute")
    end;

  forwards to
    if !null(localErrors)
    then warnStmt(localErrors)
    else sysOp(lockSystem, top.env, cv);
}

abstract production waitCV
top::Stmt ::= cv::Expr
{
  forwards to genericCVOp(cv, \sys::LockSystem env::Decorated Env cv::Expr ->
    (decorate sys with {env=env; condvar=cv;}).waitCV, "wait");
}

abstract production signalCV
top::Stmt ::= cv::Expr
{
  forwards to genericCVOp(cv, \sys::LockSystem env::Decorated Env cv::Expr -> 
    (decorate sys with {env=env; condvar=cv;}).signalCV, "signal");
}

abstract production broadcastCV
top::Stmt ::= cv::Expr
{
  forwards to genericCVOp(cv, \sys::LockSystem env::Decorated Env cv::Expr -> 
    (decorate sys with {env=env; condvar=cv;}).broadcastCV, "broadcast");
}
