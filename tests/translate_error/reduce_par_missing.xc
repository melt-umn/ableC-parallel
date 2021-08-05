#include <ableC_posix.h>
#include <stdlib.h>

#define N 100

int main() {
  int* arr = malloc(sizeof(int) * N);
  for (int i = 0; i < N; i++) arr[i] = i;
  
  posix parallel thd = new posix parallel();

  int res =
    reduce[by thd;]
    (
      \x t -> x + t,
      0,
      arr,
      N
    );
  
  return 0;
}
