grammar edu:umn:cs:melt:exts:ableC:parallel:impl:vector;

imports edu:umn:cs:melt:ableC:concretesyntax;

imports edu:umn:cs:melt:ableC:abstractsyntax:construction;
imports edu:umn:cs:melt:ableC:abstractsyntax:env;
imports edu:umn:cs:melt:ableC:abstractsyntax:host;
imports edu:umn:cs:melt:ableC:abstractsyntax:overloadable as ovrld;

imports silver:langutil;
imports silver:langutil:pp;
imports silver:util:treeset as ts;

imports edu:umn:cs:melt:exts:ableC:parallel:abstractsyntax;
imports edu:umn:cs:melt:exts:ableC:parallel:abstractsyntax:parallel;
imports edu:umn:cs:melt:exts:ableC:parallel:abstractsyntax:parallel:loop;
imports edu:umn:cs:melt:exts:ableC:parallel:abstractsyntax:parallel:spawn;
imports edu:umn:cs:melt:exts:ableC:parallel:abstractsyntax:sync;
imports edu:umn:cs:melt:exts:ableC:parallel:concretesyntax;

imports edu:umn:cs:melt:exts:ableC:constructor:abstractsyntax;
