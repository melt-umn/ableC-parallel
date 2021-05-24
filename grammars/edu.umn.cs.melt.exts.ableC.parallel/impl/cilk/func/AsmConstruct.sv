grammar edu:umn:cs:melt:exts:ableC:parallel:impl:cilk:func;

aspect production asmStatement
a::AsmStatement ::= arg::AsmArgument
{
  a.cilkParNeedStates = arg.cilkParNeedStates;
  arg.cilkParInitState = a.cilkParInitState;
}

aspect production asmStatementTypeQual
a::AsmStatement ::= tq::Qualifier arg::AsmArgument
{
  a.cilkParNeedStates = arg.cilkParNeedStates;
  arg.cilkParInitState = a.cilkParInitState;
}

aspect production asmArgument
top::AsmArgument ::= s::String asmOps1::AsmOperands asmOps2::AsmOperands asmC::AsmClobbers
{
  top.cilkParNeedStates = asmOps1.cilkParNeedStates + asmOps2.cilkParNeedStates;
  asmOps1.cilkParInitState = top.cilkParInitState;
  asmOps2.cilkParInitState = asmOps1.cilkParInitState + asmOps1.cilkParNeedStates;
}

aspect production noneAsmOps
top::AsmOperands ::=
{
  top.cilkParNeedStates = 0;
}

aspect production oneAsmOps
top::AsmOperands ::= asmOp::AsmOperand
{
  top.cilkParNeedStates = asmOp.cilkParNeedStates;
  asmOp.cilkParInitState = top.cilkParInitState;
}

aspect production snocAsmOps
top::AsmOperands ::= asmOps::AsmOperands asmOp::AsmOperand
{
  top.cilkParNeedStates = asmOps.cilkParNeedStates + asmOp.cilkParNeedStates;
  asmOps.cilkParInitState = top.cilkParInitState;
  asmOp.cilkParInitState = asmOps.cilkParInitState + asmOps.cilkParNeedStates;
}

aspect production asmOperand
top::AsmOperand ::= s::String e::Expr
{
  top.cilkParNeedStates = e.cilkParNeedStates;
  e.cilkParInitState = top.cilkParInitState;
}

aspect production asmOperandId
top::AsmOperand ::= id::Name  s::String e::Expr
{
  top.cilkParNeedStates = e.cilkParNeedStates;
  e.cilkParInitState = top.cilkParInitState;
}
