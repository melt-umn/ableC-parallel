#define ABLEC_NON_MAIN

#include <stdlib.h>

#include <ableC_workstlr_alloc.h>
#include <ableC_workstlr_deque.h>

int workstlr_init_deque(struct workstlr_deque* deque) {
  deque->head = NULL;
  deque->tail = NULL;
  return pthread_mutex_init(&(deque->lck), NULL);
}

int workstlr_destroy_deque(struct workstlr_deque* deque) {
  if (deque->head != NULL || deque->tail != NULL) {
    return -1;
  }
  return pthread_mutex_destroy(&(deque->lck));
}

void workstlr_push_head(struct workstlr_deque* deque, void* data) {
  checked_pthread_mutex_lock(&(deque->lck));

  struct workstlr_deque_item* newItem = workstlr_malloc(sizeof(struct workstlr_deque_item));
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

void workstlr_push_tail(struct workstlr_deque* deque, void* data) {
  checked_pthread_mutex_lock(&(deque->lck));
  
  struct workstlr_deque_item* newItem = workstlr_malloc(sizeof(struct workstlr_deque_item));
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

int workstlr_verify_pop_head(struct workstlr_deque* deque, void* want) {
  int res = 0;
  checked_pthread_mutex_lock(&(deque->lck));
  
  if (deque->head != NULL) {
    if (deque->head->data == want) {
      res = 1;

      struct workstlr_deque_item* toRemove = deque->head;
      deque->head = toRemove->next;
      if (deque->head == NULL) {
        deque->tail = NULL;
      } else {
        deque->head->prev = NULL;
      }

      workstlr_free(toRemove, sizeof(struct workstlr_deque_item));
    }
  }

  checked_pthread_mutex_unlock(&(deque->lck));
  return res;
}
void* workstlr_pop_head(struct workstlr_deque* deque) {
  void* res = NULL;
  checked_pthread_mutex_lock(&(deque->lck));

  if (deque->head != NULL) {
    struct workstlr_deque_item* toRemove = deque->head;
    res = toRemove->data;

    deque->head = toRemove->next;
    if (deque->head == NULL) {
      deque->tail = NULL;
    } else {
      deque->head->prev = NULL;
    }

    workstlr_free(toRemove, sizeof(struct workstlr_deque_item));
  }

  checked_pthread_mutex_unlock(&(deque->lck));
  return res;
}

void* workstlr_pop_tail(struct workstlr_deque* deque) {
  void* res = NULL;
  checked_pthread_mutex_lock(&(deque->lck));

  if (deque->tail != NULL) {
    struct workstlr_deque_item* toRemove = deque->tail;
    res = toRemove->data;

    deque->tail = toRemove->prev;
    if (deque->tail == NULL) {
      deque->head = NULL;
    } else {
      deque->tail->next = NULL;
    }

    workstlr_free(toRemove, sizeof(struct workstlr_deque_item));
  }

  checked_pthread_mutex_unlock(&(deque->lck));
  return res;
}
