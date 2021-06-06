#include <ableC_workstlr.h>
#include <ableC_posix.h>
#include <stdio.h>

workstlr_func void f(int n) {
  printf("%d\n", n);
  return;
}

workstlr_func int foo() {
  parallel for (int i = 0; i < 10; ++i) {
    f(i);
  }
  
  sync;

  return 0;
}

int main(int argc, char** argv) {
  workstlr parallel sys = new workstlr parallel(4);
  posix thread thd; thd = new posix thread();
  
  int tmp;
  spawn tmp = foo(); by sys; as thd;
  sync thd;
  delete thd;

  /*posix group grp; grp = new posix group();
  parallel for (int i = 0; i < 5; i++) { by sys; in grp; global f;
    f(i);
  }
  sync grp;
  delete grp;*/

  delete sys;

  return 0;
}
