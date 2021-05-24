#define ABLEC_NON_MAIN

#include <stdlib.h>

#include <ableC_cilk_alloc.h>
#include <ableC_cilk_deque.h>

int cilk_init_deque(struct cilk_deque* deque) {
  deque->head = NULL;
  deque->tail = NULL;
  return pthread_mutex_init(&(deque->lck), NULL);
}

int cilk_destroy_deque(struct cilk_deque* deque) {
  if (deque->head != NULL || deque->tail != NULL) {
    return -1;
  }
  return pthread_mutex_destroy(&(deque->lck));
}

void cilk_push_head(struct cilk_deque* deque, void* data) {
  checked_pthread_mutex_lock(&(deque->lck));

  struct cilk_deque_item* newItem = cilk_malloc(sizeof(struct cilk_deque_item));
  newItem->data = data;

  newItem->prev = NULL;
  newItem->next = deque->head;

  deque->head = newItem;

  if (deque->tail == NULL) {
    deque->tail = newItem;
  } else {
    newItem->next->prev = newItem;
  }

  checked_pthread_mutex_unlock(&(deque->lck));
}

void cilk_push_tail(struct cilk_deque* deque, void* data) {
  checked_pthread_mutex_lock(&(deque->lck));
  
  struct cilk_deque_item* newItem = cilk_malloc(sizeof(struct cilk_deque_item));
  newItem->data = data;

  newItem->next = NULL;
  newItem->prev = deque->tail;

  deque->tail = newItem;

  if (deque->head == NULL) {
    deque->head = newItem;
  } else {
    newItem->prev->next = newItem;
  }

  checked_pthread_mutex_unlock(&(deque->lck));
}

int cilk_verify_pop_head(struct cilk_deque* deque, void* want) {
  int res = 0;
  checked_pthread_mutex_lock(&(deque->lck));
  
  if (deque->head != NULL) {
    if (deque->head->data == want) {
      res = 1;

      struct cilk_deque_item* toRemove = deque->head;
      deque->head = toRemove->next;
      if (deque->head == NULL) {
        deque->tail = NULL;
      } else {
        deque->head->prev = NULL;
      }

      cilk_free(toRemove, sizeof(struct cilk_deque_item));
    }
  }

  checked_pthread_mutex_unlock(&(deque->lck));
  return res;
}
void* cilk_pop_head(struct cilk_deque* deque) {
  void* res = NULL;
  checked_pthread_mutex_lock(&(deque->lck));

  if (deque->head != NULL) {
    struct cilk_deque_item* toRemove = deque->head;
    res = toRemove->data;

    deque->head = toRemove->next;
    if (deque->head == NULL) {
      deque->tail = NULL;
    } else {
      deque->head->prev = NULL;
    }

    cilk_free(toRemove, sizeof(struct cilk_deque_item));
  }

  checked_pthread_mutex_unlock(&(deque->lck));
  return res;
}

void* cilk_pop_tail(struct cilk_deque* deque) {
  void* res = NULL;
  checked_pthread_mutex_lock(&(deque->lck));

  if (deque->tail != NULL) {
    struct cilk_deque_item* toRemove = deque->tail;
    res = toRemove->data;

    deque->tail = toRemove->prev;
    if (deque->tail == NULL) {
      deque->head = NULL;
    } else {
      deque->tail->next = NULL;
    }

    cilk_free(toRemove, sizeof(struct cilk_deque_item));
  }

  checked_pthread_mutex_unlock(&(deque->lck));
  return res;
}
