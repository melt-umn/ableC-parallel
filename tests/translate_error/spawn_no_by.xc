#include <stdio.h>
#include <ableC_parallel.h>

#include "testing.xh"

int f(int x) {
  return x * x;
}

int main() {
  int x;
  spawn x = f(77);
  sync;

  printf("%d\n", x);
}
