#include <stdio.h>

int main() {
  int i = 0;

  parallel for (i = 0; i < 10; i++) {
    printf("%d\n", i);
  }
}
