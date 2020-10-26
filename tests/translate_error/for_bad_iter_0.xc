#include <stdio.h>

int main() {
  int j;

  parallel for (int i = 0; i < 10; j++) {
    printf("%d\n", i);
  }
}
