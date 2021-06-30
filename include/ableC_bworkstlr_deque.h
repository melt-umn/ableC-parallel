#ifndef INCLUDE_BWORKSTLR_DEQUE_H_
#define INCLUDE_BWORKSTLR_DEQUE_H_

#include <ableC_parallel.h>

// This struct has the same layout (except at the end) as a workstlr_deque,
// and so most operations should just use the operations provided for those
struct bworkstlr_deque {
  struct workstlr_deque_item* head;
  struct workstlr_deque_item* tail;
  pthread_mutex_t lck;
  volatile _Atomic int inUse;
};

// returns 0 on success
int bworkstlr_init_deque(struct bworkstlr_deque*);
// returns 0 on success
int bworkstlr_destroy_deque(struct bworkstlr_deque*);
// returns 1 if it claims the deque, 0 if it is already claimed
int bworkstlr_claim_deque(struct bworkstlr_deque*);
void bworkstlr_release_deque(struct bworkstlr_deque*);

#endif
