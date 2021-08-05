#include <stdlib.h>

#define N 100
#define EXPECTED 338350

int main() {
  int* arr = malloc(sizeof(int) * N);
  for (int i = 0; i < N; i++) { arr[i] = i; }

  int res =
    reduce[fuse reduce-map;]
    (
      \x t -> x + t,
      0,
      map[fuse map-map;]
      (
        \x -> x * x,
        map(
          \x -> x + 1,
          arr,
          N
        )
      )
    );
  
  if (res != EXPECTED) exit(1);

  free(arr);
  return 0;
}
