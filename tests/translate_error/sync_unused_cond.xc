#include <ableC_posix.h>

struct s {
  int a, b, c;
};

typedef posix synchronized <struct s> = {
  condition aZero(this.a == 0);
} syncS;

int main() { return 0; }
