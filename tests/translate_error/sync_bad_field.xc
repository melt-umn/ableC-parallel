#include <ableC_posix.h>

struct s {
  int a, b, c;
};

typedef posix synchronized <struct s> = {
  condition dZero(this.d == 0);
  when (this.d) += 1 then signal not dZero;
} syncS;

int main() { return 0; }
