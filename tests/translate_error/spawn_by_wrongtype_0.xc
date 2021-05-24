#include <stdio.h>
#include <ableC_parallel.h>

int f(int x) {
  return x * x * x;
}

int main() {

  int r;
  spawn r = f(7); by 4;
  sync;

  printf("%d\n", r);
}
