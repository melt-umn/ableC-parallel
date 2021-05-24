#include <ableC_posix.h>
#include <stdio.h>
#include <stdlib.h>

struct bounded_buffer {
  int head, tail, n, len;
  int* items;
};

typedef posix synchronized<struct bounded_buffer> = {
  condition empty(this.n == 0);
  condition full(this.n >= this.len);

  when (this.n) += 1 then signal not empty;
  when (this.n) -= 1 then signal not full;
} bounded_buffer;

bounded_buffer* create_buffer(int len) {
  bounded_buffer* res = malloc(sizeof(bounded_buffer));

  struct bounded_buffer tmp;
  tmp.head = 0; tmp.tail = 0; tmp.n = 0; tmp.len = len;
  tmp.items = malloc(sizeof(int) * len);
  if (tmp.items == NULL) {
    free(res);
    return NULL;
  }

  *res = new bounded_buffer(tmp);
  return res;
}

void destroy_buffer(bounded_buffer* buffer) {
  holding (*buffer) as buf {
    free(buf.items);
  }

  delete *buffer;
  free(buffer);
}

int buffer_get(bounded_buffer* buffer) {
  int res;

  holding (*buffer) as buf {
    wait while buf.empty;

    res = buf.items[buf.head];
    buf.head = (buf.head + 1) % buf.len;
    buf.n -= 1;
  }

  return res;
}

void buffer_put(bounded_buffer* buffer, int elem) {
  holding (*buffer) as buf {
    wait while buf.full;
    
    buf.items[buf.tail] = elem;
    buf.tail = (buf.tail + 1) % buf.len;
    buf.n += 1;
  }
}

int main() {
  bounded_buffer* buf = create_buffer(100);
  
  for (int i = 0; i < 100; i++) {
    buffer_put(buf, i);
  }
  for (int i = 0; i < 100; i++) {
    int r = buffer_get(buf);
    if (r != i) printf("Err\n");
  }
  
  destroy_buffer(buf);
  return 0;
}
