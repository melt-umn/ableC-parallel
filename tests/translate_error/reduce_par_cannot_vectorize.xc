#include <ableC_posix.h>
#include <ableC_vector.h>
#include <stdlib.h>

#define N 100

int main() {
  int* arr = malloc(sizeof(int) * N);
  for (int i = 0; i < N; i++) arr[i] = i;
  
  vectorize parallel thd = new vectorize parallel();

  int res =
    reduce[by thd; num-threads 1; sync-by posix; par-comb \a b -> a + b;]
    (
      \x t -> x + t,
      0,
      arr,
      N
    );
  
  return 0;
}
