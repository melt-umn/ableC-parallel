#include <stdio.h>
#include <stdlib.h>
#include <ableC_posix.h>
#include <ableC_vector.h>

int main() {
  vectorize parallel vect = new vectorize parallel();
  
  int* arr = aligned_malloc(32, sizeof(int) * 100);
  for (int i = 0; i < 100; i++) arr[i] = i;

  int* fourths =
    map[fuse map-map; by vect; sync-by posix;] 
      (map arr[100] by \x -> x * x)
    by \x -> x * x;
  
  printf("%d %d %d %d %d %d\n", fourths[0], fourths[5], fourths[10], fourths[25], fourths[50], fourths[99]);
  free(fourths);

  free(arr);
  delete vect;

  return 0;
}
