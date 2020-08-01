grammar edu:umn:cs:melt:exts:ableC:parallel:abstractsyntax;

abstract production waitStmt
top::Stmt ::= cvs::[Name]
{
  forwards to nullStmt();
}

abstract production signalStmt
top::Stmt ::= cv::Name
{
  forwards to nullStmt();
}

abstract production broadcastStmt
top::Stmt ::= cv::Name
{
  forwards to nullStmt();
}
