#include <stdlib.h>

#define N 100

int main() {
  int* arr = malloc(sizeof(int) * N);
  for (int i = 0; i < N; i++) arr[i] = i;
  
  int* res =
    map[fuse reduce-map;]
    (
      \x -> x * x,
      map(
        \x -> x + 1,
        arr,
        N
      )
    );
  
  return 0;
}
