#include <stdio.h>
#include <ableC_parallel.h>

#include "testing.xh"

int main() {
  testing parallel system;
  parallel for (int i = 0; i < 10; i = 1 - i) { by system;
    printf("%d\n", i);
  }
}
