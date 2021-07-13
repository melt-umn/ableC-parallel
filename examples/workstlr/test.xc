#include <ableC_workstlr.h>
#include <ableC_posix.h>
#include <stdio.h>

int fib(int n) {
  if (n <= 1) return n;
  return fib(n-1) + fib(n-2);
}

workstlr_func int h(int n) {
  posix parallel thrds = new posix parallel();
  posix thread thd; thd = new posix thread();

  int x;
  spawn x = fib(n); by thrds; as thd; public x; private n; global fib;

  sync thd;
  delete thd;
  delete thrds;
 
  return x;
}

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

  printf("\nA\n");

  posix group grp; grp = new posix group();
  parallel for (int i = 0; i < 5; i++) { by sys; in grp; global printf; num-threads 2;
    printf("%d\n", i);
  }
  sync grp;
  delete grp;

  thd = new posix thread();

  spawn tmp = h(12); by sys; as thd;
  sync thd;
  delete thd;

  printf("fib(12) = %d\n", tmp);

  delete sys;

  return 0;
}
