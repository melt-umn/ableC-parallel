#include <ableC_cilk.h>
#include <ableC_posix.h>
#include <stdlib.h>
#include <stdio.h>

cilk_func int fib(int n);
cilk_func int fib(int n) {
  if (n <= 1) return n;
  int x, y;
  spawn x = fib(n-1);
  spawn y = fib(n-2);
  sync;

  return x + y;
}

cilk_func int fib_into(int n, int* res) {
  int tmp;
  spawn tmp = fib(n);
  sync;
  *res = tmp;
  return 0;
}

int tmp;

int main(int argc, char** argv) {
  cilk parallel sys = new cilk parallel(4);
  posix group grp; grp = new posix group();
  
  srand(31415);
  int* nums = malloc(sizeof(int) * 1000);
  for (int i = 0; i < 1000; i++) nums[i] = rand() % 30;

  parallel for (int i = 0; i < 1000; i++) by sys; in grp; num-threads 4;
                                      global fib_into, rand, tmp; private nums;
  {
    tmp = fib_into(nums[i], nums + i);
  }
  sync grp;

  delete grp;
  delete sys;

  for (int i = 0; i < 1000; i++) {
    printf("%d\n", nums[i]);
  }
  free(nums);

  return 0;
}
