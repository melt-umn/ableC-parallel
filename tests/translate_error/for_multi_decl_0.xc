#include <stdio.h>

int main() {
  parallel for (int i = 0, j = 7; i < 10; i++) {
    printf("%d\n", i);
  }
}
