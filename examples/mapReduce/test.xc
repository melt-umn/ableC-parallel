#include <stdio.h>
#include <stdlib.h>

struct pair { 
  int x, y;
};

int square(int x) { return x * x; }

int main() {
  int* arr = malloc(sizeof(int) * 100);
  for (int i = 0; i < 100; i++) arr[i] = i;

  int tmp =
    reduce[fuse reduce-map;]
    (
      \x t -> x + t,
      0,
      map[fuse map-map;]
      (
        \p -> p.x + p.y + 1,
        map(\x -> ({struct pair p = {x, x+1}; p;}), arr[100])
      )
    );
  printf("%d\n", tmp);

  int val =
    reduce[fuse reduce-map;]
    (
      \x t -> x + t,
      0,
      map[fuse map-map;]
      (
        \x -> x * 2,
        map(\x -> x * x, arr[100])
      )
    );
  printf("%d\n", val);

  int* fourths = map[fuse map-map;](square, map(square, arr[100]));
  printf("%d %d %d %d %d %d\n", fourths[0], fourths[5], fourths[10], fourths[25], fourths[50], fourths[99]);
  free(fourths);

  free(arr);

  return 0;
}
