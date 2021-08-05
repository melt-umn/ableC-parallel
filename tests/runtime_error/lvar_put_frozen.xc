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

  Value<int> x = freeze lv;

  lv <- 7;

  return 0;
}
