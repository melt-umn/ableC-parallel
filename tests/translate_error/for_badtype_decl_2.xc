#include <stdio.h>
#include "testing.xh"

typedef struct {
  int x;
} var;

int main() {
  test parallel system;
  parallel for (var i = {0}; i.x < 10; i.x++) { by system;
    printf("%d\n", i.x);
  }
}
