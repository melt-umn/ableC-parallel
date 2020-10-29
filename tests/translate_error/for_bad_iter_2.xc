#include <stdio.h>
#include "testing.xh"

int main() {
  test parallel system;
  parallel for (int i = 0; i < 10; i += 1 + i) { by system;
    printf("%d\n", i);
  }
}
