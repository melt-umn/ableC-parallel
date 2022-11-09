grammar edu:umn:cs:melt:exts:ableC:parallel:impl:workstlr:func;

aspect production asmStatement
a::AsmStatement ::= arg::AsmArgument
{
  a.workstlrParNeedStates = arg.workstlrParNeedStates;
  arg.workstlrParInitState = a.workstlrParInitState;

  propagate workstlrParFuncName;
}

aspect production asmStatementTypeQual
a::AsmStatement ::= tq::Qualifier arg::AsmArgument
{
  a.workstlrParNeedStates = arg.workstlrParNeedStates;
  arg.workstlrParInitState = a.workstlrParInitState;

  propagate workstlrParFuncName;
}

aspect production asmArgument
top::AsmArgument ::= s::String asmOps1::AsmOperands asmOps2::AsmOperands asmC::AsmClobbers
{
  top.workstlrParNeedStates = asmOps1.workstlrParNeedStates + asmOps2.workstlrParNeedStates;
  asmOps1.workstlrParInitState = top.workstlrParInitState;
  asmOps2.workstlrParInitState = asmOps1.workstlrParInitState + asmOps1.workstlrParNeedStates;

  propagate workstlrParFuncName;
}

aspect production noneAsmOps
top::AsmOperands ::=
{
  top.workstlrParNeedStates = 0;

  propagate workstlrParFuncName;
}

aspect production oneAsmOps
top::AsmOperands ::= asmOp::AsmOperand
{
  top.workstlrParNeedStates = asmOp.workstlrParNeedStates;
  asmOp.workstlrParInitState = top.workstlrParInitState;

  propagate workstlrParFuncName;
}

aspect production snocAsmOps
top::AsmOperands ::= asmOps::AsmOperands asmOp::AsmOperand
{
  top.workstlrParNeedStates = asmOps.workstlrParNeedStates + asmOp.workstlrParNeedStates;
  asmOps.workstlrParInitState = top.workstlrParInitState;
  asmOp.workstlrParInitState = asmOps.workstlrParInitState + asmOps.workstlrParNeedStates;

  propagate workstlrParFuncName;
}

aspect production asmOperand
top::AsmOperand ::= s::String e::Expr
{
  top.workstlrParNeedStates = e.workstlrParNeedStates;
  e.workstlrParInitState = top.workstlrParInitState;

  propagate workstlrParFuncName;
}

aspect production asmOperandId
top::AsmOperand ::= id::Name  s::String e::Expr
{
  top.workstlrParNeedStates = e.workstlrParNeedStates;
  e.workstlrParInitState = top.workstlrParInitState;

  propagate workstlrParFuncName;
}
