#include <stdio.h>
#include "testing.xh"

long f(unsigned int n) {
  long res = 1;
  for (unsigned int i = 0; i < n; i++)
    res *= n;
  return res;
}

double g(int x) {
  double res = 1.0;
  res *= x + 7;
  return res;
}

int main() {
  test parallel system;
  
  test parallel* ptr = &system;

  long r1, r2;
  int r3;

  spawn r1 = f(17); by system;
  spawn r2 = f(44); by (*ptr);

  spawn r3 = g(102); by system;

  sync;

  printf("%d\n", 4);
  return 0;
}
