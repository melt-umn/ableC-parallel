#include <ableC_cilk.h>
#include <ableC_posix.h>
#include <stdio.h>

cilk parallel sys;

parallel by sys int f(int n) {
  printf("%d\n", n);
  return 0;
}

parallel by sys int foo() {
  parallel for (int i = 0; i < 10; ++i) {
    f(i);
  }
  
  sync;

  return 0;
}

int main(int argc, char** argv) {
  sys = new cilk parallel(4);
  posix thread thd; thd = new posix thread();
  
  int tmp;
  spawn tmp = foo(); by sys; as thd;
  sync thd;
  delete thd;

  printf("\nA\n");

  posix group grp; grp = new posix group();
  parallel for (int i = 0; i < 10; i++) { by sys; in grp; global printf; num-threads 4;
    printf("%d\n", i);
  }
  sync grp;
  delete grp;

  delete sys;

  return 0;
}
