#include <stdio.h>
#include <ableC_parallel.h>
#include <ableC_posix.h>

typedef struct {
  int x;
} var;

int main() {
  posix parallel system;
  parallel for (var i = {0}; i.x < 10; i.x++) { by system;
    printf("%d\n", i.x);
  }
}
