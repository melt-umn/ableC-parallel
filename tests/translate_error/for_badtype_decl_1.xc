#include <stdio.h>
#include <ableC_parallel.h>

#include "testing.xh"

int main() {
  test parallel system;
  parallel for (double i = 0; i < 10; i++) { by system;
    printf("%lf\n", i);
  }
}
