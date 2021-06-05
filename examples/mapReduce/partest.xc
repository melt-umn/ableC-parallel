#include <stdio.h>
#include <stdlib.h>
#include <ableC_posix.h>

struct pair { 
  int x, y;
};

int square(int x) { return x * x; }

int main() {
  int* arr = malloc(sizeof(int) * 100);
  for (int i = 0; i < 100; i++) arr[i] = i;

  int tmp =
    reduce[fuse reduce-map;]
      (map[fuse map-map;]
        (map arr[100] by \x -> ({struct pair p = {x, x+1}; p;}))
        by \p -> p.x + p.y + 1)
      from (0)
      by \x t -> x + t;
  printf("%d\n", tmp);

  int val =
    reduce[fuse reduce-map;]
      (map[fuse map-map;]
        (map arr[100] by \x -> x * x)
      by \x -> x * 2)
    from (0)
    by \x t -> x + t;
  printf("%d\n", val);

  posix parallel thrds; thrds = new posix parallel();

  int* fourths =
    map[fuse map-map; by thrds; num-threads 4; sync-by posix;] 
      (map arr[100] by square)
    by square;
  printf("%d %d %d %d %d %d\n", fourths[0], fourths[5], fourths[10], fourths[25], fourths[50], fourths[99]);
  free(fourths);
  delete thrds;

  free(arr);

  return 0;
}
