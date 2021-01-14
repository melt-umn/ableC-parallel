#include <stdio.h>
#include <ableC_parallel.h>

#include "testing.xh"

int main() {
  int i = 0;

  testing parallel system;
  parallel for (; i < 10; i++) { by system;
    printf("%d\n", i);
  }
}
