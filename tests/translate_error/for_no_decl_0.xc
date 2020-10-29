#include <stdio.h>
#include "testing.xh"

int main() {
  int i = 0;

  test parallel system;
  parallel for (i = 0; i < 10; i++) { by system;
    printf("%d\n", i);
  }
}
