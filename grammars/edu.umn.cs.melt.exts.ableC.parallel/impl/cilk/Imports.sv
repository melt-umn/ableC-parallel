grammar edu:umn:cs:melt:exts:ableC:parallel:impl:cilk;

imports edu:umn:cs:melt:exts:ableC:parallel:impl:cilk:func;

imports edu:umn:cs:melt:ableC:concretesyntax;

imports edu:umn:cs:melt:ableC:abstractsyntax:construction;
imports edu:umn:cs:melt:ableC:abstractsyntax:env;
imports edu:umn:cs:melt:ableC:abstractsyntax:host;
imports edu:umn:cs:melt:ableC:abstractsyntax:overloadable as ovrld;

imports silver:langutil;
imports silver:langutil:pp;
imports silver:util:treemap as tm;

imports edu:umn:cs:melt:exts:ableC:cilk;

imports edu:umn:cs:melt:exts:ableC:parallel:abstractsyntax;
imports edu:umn:cs:melt:exts:ableC:parallel:abstractsyntax:parallel;
imports edu:umn:cs:melt:exts:ableC:parallel:abstractsyntax:parallel:loop;
imports edu:umn:cs:melt:exts:ableC:parallel:abstractsyntax:parallel:spawn;
imports edu:umn:cs:melt:exts:ableC:parallel:abstractsyntax:sync;

imports edu:umn:cs:melt:exts:ableC:constructor:abstractsyntax;
