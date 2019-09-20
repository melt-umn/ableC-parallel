grammar edu:umn:cs:melt:exts:ableC:parallel:concretesyntax;

imports edu:umn:cs:melt:ableC:concretesyntax;
imports edu:umn:cs:melt:exts:ableC:parallel:abstractsyntax;
imports silver:langutil;

marking terminal Parallel_t '%parallel';
terminal ExtensionName_t /[a-zA-Z0-9\-:_]*/;
terminal CaptureLine_t /\h*(\n|\r\n)/;

concrete production parallelExtensions
top::Declaration_c ::= '%parallel' exts::ExtensionSpecs_c CaptureLine_t
  layout { Spaces_t }
{
  top.ast = parallelDeclaration(exts.ast, exts.location);
}

nonterminal ExtensionSpecs_c with ast<[Pair<String Float>]>, location;
concrete productions top::ExtensionSpecs_c
| { top.ast = []; }
| nm::ExtensionName_t '=' val::FloatConstant_t tl::ExtensionSpecs_c
  layout { Spaces_t }
{
  top.ast = pair(nm.lexeme, toFloat(val.lexeme)) :: tl.ast;
}

marking terminal Parallelize_t '%parallelize';
concrete production parallelize
top::Stmt_c ::= '%parallelize' threads::ThreadSpec_c CaptureLine_t
  layout { Spaces_t }
{
  top.ast = initParallelism(threads.ast, threads.location);
}

nonterminal ThreadSpec_c with ast<Maybe<Integer>>, location;
concrete productions top::ThreadSpec_c
| { top.ast = nothing(); }
| val::DecConstant_t { top.ast = just(toInt(val.lexeme)); }
