#include <stdio.h>
#include "testing.xh"

int main() {
  test parallel system;
  parallel for (int i = 0; i < 100; i++) { by system;
    printf("%d\n", i);
    i = 4;
  }
  return 0;
}
