#include <stdio.h>

typedef struct {
  int x;
} var;

int main() {
  parallel for (var i = {0}; i.x < 10; i.x++) {
    printf("%d\n", i.x);
  }
}
