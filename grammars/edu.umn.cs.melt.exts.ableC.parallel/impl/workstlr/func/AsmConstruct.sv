grammar edu:umn:cs:melt:exts:ableC:parallel:impl:workstlr:func;

aspect production asmStatement
a::AsmStatement ::= arg::AsmArgument
{
  a.workstlrParNeedStates = arg.workstlrParNeedStates;
  arg.workstlrParInitState = a.workstlrParInitState;
}

aspect production asmStatementTypeQual
a::AsmStatement ::= tq::Qualifier arg::AsmArgument
{
  a.workstlrParNeedStates = arg.workstlrParNeedStates;
  arg.workstlrParInitState = a.workstlrParInitState;
}

aspect production asmArgument
top::AsmArgument ::= s::String asmOps1::AsmOperands asmOps2::AsmOperands asmC::AsmClobbers
{
  top.workstlrParNeedStates = asmOps1.workstlrParNeedStates + asmOps2.workstlrParNeedStates;
  asmOps1.workstlrParInitState = top.workstlrParInitState;
  asmOps2.workstlrParInitState = asmOps1.workstlrParInitState + asmOps1.workstlrParNeedStates;
}

aspect production noneAsmOps
top::AsmOperands ::=
{
  top.workstlrParNeedStates = 0;
}

aspect production oneAsmOps
top::AsmOperands ::= asmOp::AsmOperand
{
  top.workstlrParNeedStates = asmOp.workstlrParNeedStates;
  asmOp.workstlrParInitState = top.workstlrParInitState;
}

aspect production snocAsmOps
top::AsmOperands ::= asmOps::AsmOperands asmOp::AsmOperand
{
  top.workstlrParNeedStates = asmOps.workstlrParNeedStates + asmOp.workstlrParNeedStates;
  asmOps.workstlrParInitState = top.workstlrParInitState;
  asmOp.workstlrParInitState = asmOps.workstlrParInitState + asmOps.workstlrParNeedStates;
}

aspect production asmOperand
top::AsmOperand ::= s::String e::Expr
{
  top.workstlrParNeedStates = e.workstlrParNeedStates;
  e.workstlrParInitState = top.workstlrParInitState;
}

aspect production asmOperandId
top::AsmOperand ::= id::Name  s::String e::Expr
{
  top.workstlrParNeedStates = e.workstlrParNeedStates;
  e.workstlrParInitState = top.workstlrParInitState;
}
