#include <stdio.h>
#include <ableC_parallel.h>

#include "testing.xh"

int main() {
  test parallel system;
  parallel for (int i = 0; ; i++) { by system;
    printf("%d\n", i);
  }
}
