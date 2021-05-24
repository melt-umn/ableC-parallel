#include <ableC_lvars.xh>
#include <ableC_posix.h>
#include <unistd.h>

void lub_int_max(Value<int>* a, int b) {
  match (a) {
    &Top()    -> {}
    &Bottom() -> {
      *a = Of(b);
    }
    &Of(x)    -> {
      if (b > x) {
        *a = Of(b);
      }
    }
  }
}

void print_value_int(Value<int>* v) {
  match (v) {
    &Top()    -> { printf("Top\n"); }
    &Bottom() -> { printf("Bottom\n"); }
    &Of(x)    -> { printf("%d\n", x); }
  }
}

Maybe<Value<int>> int_atleast_3(Value<int> v) {
  match (&v) {
    &Top()    -> { return Just(Of(3)); }
    &Bottom() -> { return inst Nothing<Value<int>>(); }
    &Of(x)    -> { 
      if (x >= 3) return Just(Of(3));
      else return inst Nothing<Value<int>>();
    }
  }
}

void testFunc(posix lvar<int>* lv) {
  sleep(1);
  *lv <- 2;
  sleep(1);
  *lv <- 6;
  sleep(1);
  *lv <- 13;
}

int main() {
  posix lvar<int> lv;
  lv = new posix lvar<int>(lub_int_max);

  posix parallel threads; threads = new posix parallel();
  posix thread thd; thd = new posix thread();

  spawn testFunc(&lv); by threads; as thd; public lv; global testFunc;

  Value<int> v1 = (get lv at int_atleast_3);
  print_value_int(&v1);
  
  sync thd; delete thd;
  
  Value<int> x = (freeze lv);
  print_value_int(&x);

  return 0;
}
