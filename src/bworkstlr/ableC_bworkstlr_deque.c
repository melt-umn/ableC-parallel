#define ABLEC_NON_MAIN

#include <stdlib.h>

#include <ableC_workstlr_alloc.h>
#include <ableC_workstlr_deque.h>
#include <ableC_bworkstlr_deque.h>

int bworkstlr_init_deque(struct bworkstlr_deque* deque) {
  deque->inUse = 0;
  deque->head = NULL;
  deque->tail = NULL;
  return pthread_mutex_init(&(deque->lck), NULL);
}

int bworkstlr_destroy_deque(struct bworkstlr_deque* deque) {
  if (deque->head != NULL || deque->tail != NULL || deque->inUse) {
    return -1;
  }
  return pthread_mutex_destroy(&(deque->lck));
}

int bworkstlr_claim_deque(struct bworkstlr_deque* deque) {
  return deque->inUse++ == 0;
}

void bworkstlr_release_deque(struct bworkstlr_deque* deque) {
  deque->inUse = 0;
}
