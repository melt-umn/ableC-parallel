#include <stdio.h>
#include <ableC_parallel.h>

#include "testing.xh"

int f(int x) {
  return x * x * x;
}

int main() {

  int r;
  spawn r = f(7); by "test";
  sync;

  printf("%d\n", r);
}
