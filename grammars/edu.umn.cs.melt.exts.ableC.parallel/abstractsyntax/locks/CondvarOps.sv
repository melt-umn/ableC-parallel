grammar edu:umn:cs:melt:exts:ableC:parallel:abstractsyntax:locks;

abstract production genericCVOp
top::Stmt ::= cv::Expr sysOp::((Stmt ::= Expr) ::= LockSystem) nm::String
{
  cv.env = top.env;

  top.pp = ppConcat([text(nm), space(), cv.pp]);
  top.functionDefs := [];

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
    end;

  forwards to
    if !null(localErrors)
    then warnStmt(localErrors)
    else sysOp(lockSystem)(cv);
}

abstract production waitCV
top::Stmt ::= cv::Expr
{
  forwards to genericCVOp(cv, \sys::LockSystem -> sys.fWait, "wait");
}

abstract production signalCV
top::Stmt ::= cv::Expr
{
  forwards to genericCVOp(cv, \sys::LockSystem -> sys.fSignal, "signal");
}

abstract production broadcastCV
top::Stmt ::= cv::Expr
{
  forwards to genericCVOp(cv, \sys::LockSystem -> sys.fBroadcast, "broadcast");
}
