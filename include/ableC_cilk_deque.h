#ifndef INCLUDE_DEQUE_H_
#define INCLUDE_DEQUE_H_

#include <ableC_parallel.h>

struct cilk_deque_item {
  void* data;
  struct cilk_deque_item* prev; // In the direction of the head
  struct cilk_deque_item* next; // In the direction of the tail
};

struct cilk_deque {
  struct cilk_deque_item* head;
  struct cilk_deque_item* tail;
  pthread_mutex_t lck;
};

// returns 0 on success
int cilk_init_deque(struct cilk_deque*);
// returns 0 on success
int cilk_destroy_deque(struct cilk_deque*);

// Head will be used by worker, tail by thief
void cilk_push_head(struct cilk_deque*, void*);
void cilk_push_tail(struct cilk_deque*, void*);

// Returns 1 if it popped an item that matched the supplied data. 
// Otherwise returns 0 and does not change the contents of the deque
int cilk_verify_pop_head(struct cilk_deque*, void*);

void* cilk_pop_head(struct cilk_deque*);
void* cilk_pop_tail(struct cilk_deque*);

#endif
