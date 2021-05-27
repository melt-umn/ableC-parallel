#include <ableC_cilk.h>
#include <ableC_posix.h>
#include <stdio.h>

cilk_func int f(int n) {
  printf("%d\n", n);
  return 0;
}

cilk_func int foo() {
  parallel for (int i = 0; i < 10; ++i) {
    f(i);
  }
  
  sync;

  return 0;
}

int main(int argc, char** argv) {
  cilk parallel sys = new cilk parallel(4);
  posix thread thd; thd = new posix thread();
  
  int tmp;
  spawn tmp = foo(); by sys; as thd;
  sync thd;

  delete thd;
  delete sys;

  return 0;
}
