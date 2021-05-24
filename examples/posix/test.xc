#include <ableC_posix.h>
#include <stdio.h>
#include <stdlib.h>

typedef struct {
  int head, tail, n, len;
  int* items;
  posix lock lk;
  posix condvar empty, full;
} bounded_buffer;

int initialize_buffer(bounded_buffer* buffer, int len) {
  buffer->head = 0;
  buffer->tail = 0;
  buffer->n = 0;
  buffer->len = len;

  buffer->lk = new posix lock();
  buffer->empty = new posix condvar(&(buffer->lk));
  buffer->full = new posix condvar(&(buffer->lk));

  buffer->items = malloc(sizeof(int) * len);

  if (buffer->items == NULL)
    return -1;
 
  return 0;
}

void destroy_buffer(bounded_buffer* buffer) {
  free(buffer->items);

  buffer->head = 0;
  buffer->tail = 0;
  buffer->n = 0;
  buffer->len = 0;
  buffer->items = NULL;

  delete buffer->lk;
  delete buffer->empty;
  delete buffer->full;
}

int buffer_get(bounded_buffer* buffer) {
  acquire buffer->lk;

  int res;

  while (buffer->n == 0) {
    wait buffer->empty;
  }

  res = buffer->items[buffer->head];
  buffer->head = (buffer->head + 1) % buffer->len;
  buffer->n -= 1;

  signal buffer->full;
  release buffer->lk;

  return res;
}

void buffer_put(bounded_buffer* buffer, int elem) {
  acquire buffer->lk;

  while (buffer->n >= buffer->len) {
    wait buffer->full;
  }

  buffer->items[buffer->tail] = elem;
  buffer->tail = (buffer->tail + 1) % buffer->len;
  buffer->n += 1;

  signal buffer->empty;
  release buffer->lk;
}

int total_buffer(bounded_buffer* buffer) {
  int res = 0;

  int elem;
  while ((elem = buffer_get(buffer)) >= 0) {
    res += elem;
  }

  return res;
}

void generate(bounded_buffer* buffer, int i) {
  unsigned int seed = i;

  for (int i = 0; i < 1024; i++) {
    buffer_put(buffer, rand_r(&seed));
  }
}

int main() {
  posix parallel threads = new posix parallel();

  posix thread th; th = new posix thread();
  posix group grp; grp = new posix group();

  bounded_buffer buffer;
  initialize_buffer(&buffer, 1024);

  int sum = 0;
  // I'm not a fan of the fact that buffer must be public, but...
  spawn sum = total_buffer(&buffer); by threads; as th; public buffer; global total_buffer; public sum;

  parallel for (int i = 0; i < 16; i++) { by threads; in grp; public buffer; global generate; num_threads 16;
    generate(&buffer, i);
  }

  sync grp;

  buffer_put(&buffer, -1);

  sync th;

  destroy_buffer(&buffer);
  
  delete th;
  delete grp;
  delete threads;

  printf("Sum = %d\n", sum);
  return 0;
}
