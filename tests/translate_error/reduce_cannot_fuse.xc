#include <stdlib.h>

#define N 100

int main() {
  int* arr = malloc(sizeof(int) * N);
  for (int i = 0; i < N; i++) arr[i] = i;
  
  int res =
    reduce[fuse reduce-map;]
    (
      \x t -> x + t,
      0,
      arr,
      N
    );
  
  return 0;
}
