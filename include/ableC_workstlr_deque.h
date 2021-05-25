#ifndef INCLUDE_WORKSTLR_DEQUE_H_
#define INCLUDE_WORKSTLR_DEQUE_H_

#include <ableC_parallel.h>

struct workstlr_deque_item {
  void* data;
  struct workstlr_deque_item* prev; // In the direction of the head
  struct workstlr_deque_item* next; // In the direction of the tail
};

struct workstlr_deque {
  struct workstlr_deque_item* head;
  struct workstlr_deque_item* tail;
  pthread_mutex_t lck;
};

// returns 0 on success
int workstlr_init_deque(struct workstlr_deque*);
// returns 0 on success
int workstlr_destroy_deque(struct workstlr_deque*);

// Head will be used by worker, tail by thief
void workstlr_push_head(struct workstlr_deque*, void*);
void workstlr_push_tail(struct workstlr_deque*, void*);

// Returns 1 if it popped an item that matched the supplied data. 
// Otherwise returns 0 and does not change the contents of the deque
int workstlr_verify_pop_head(struct workstlr_deque*, void*);

void* workstlr_pop_head(struct workstlr_deque*);
void* workstlr_pop_tail(struct workstlr_deque*);

#endif
