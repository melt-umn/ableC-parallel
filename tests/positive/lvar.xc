#include <ableC_lvars.xh>
#include <ableC_posix.h>
#include <unistd.h>

#define max(q, t) (q > t ? q : t)

void lub_int_max(Value<int>* a, int b) {
  match (a) {
    &Top()    -> {}
    &Bottom() -> {*a = Of(b);}
    &Of(x)    -> {*a = Of(max(b, x));}
  }
}

int main() {
  posix lvar<int> lv;
  lv = new posix lvar<int>(lub_int_max);

  lv <- 3;
  lv <- 9;
  lv <- -3;
  lv <- 2;

  Value<int> x = freeze lv;

  match (&x) {
    &Top()    -> { exit(1); }
    &Bottom() -> { exit(1); }
    &Of(x)    -> { if (x != 9) exit(1); }
  }

  delete lv;
  return 0;
}
