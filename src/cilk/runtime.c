#define ABLEC_NON_MAIN

#include <stdio.h>
#include <stdlib.h>
#include <pthread.h>

#include <ableC_cilk_alloc.h>
#include <ableC_cilk_deque.h>
#include <ableC_cilk.h>

_Thread_local struct cilk_deque* cilk_thread_deque;
_Thread_local jmp_buf cilk_jmp_buf;

struct thread_info {
  struct __ableC_system_info* sysInfo;
  struct cilk_deque* deque;
};

void* cilk_scheduler(void* ptr) {
  struct thread_info* info = ptr;
  struct __ableC_system_info* sysInfo = info->sysInfo;
  struct cilk_system* system = (struct cilk_system*) sysInfo->system_data;
  struct cilk_deque* deque = info->deque;
  cilk_free(info, sizeof(struct thread_info));

  // Set the thread locals
  cilk_thread_deque = deque;
  // This results in bad errors about already held when we attempt to acquire
  // an unheld lock. We really should issue a TCB to every logical thread,
  // but this is a problem (FIXME)
  __ableC_thread_tcb = NULL;

  const int nThreads = system->nThreads;

  // Initialize the seed to be the # of the thread
  unsigned int seed = deque - system->deques;

  // Set the jump buffer (used to return to the scheduler when work is stolen)
  setjmp(cilk_jmp_buf);

  struct cilk_closure* closure;
  while (!system->shutdown) {
    closure = cilk_pop_head(deque);

    if (closure == NULL) {
      // Attempt to steal (This implementation avoid the problem Cilk5 has 
      // where we never check our own deque again)
      int n = rand_r(&seed) % nThreads;
      while (closure == NULL && !system->shutdown) {
        closure = cilk_pop_tail(&(system->deques[n]));
        n = (n + 1) % nThreads;
      }

      if (system->shutdown) break;
    }

    closure->func(closure);
  }

  // Need a barrier to ensure that none of the other threads are actively
  // accessing this thread's deque when it tries to destroy it (if there
  // is such a thread, it causes the destruction of the lock to fail)
  {
    int errnum = pthread_barrier_wait(&(system->barrier));
    if (__builtin_expect(errnum, 0) && errnum != PTHREAD_BARRIER_SERIAL_THREAD) {
      fprintf(stderr, "Error in pthread_barrier_wait: %s\n", strerror(errnum));
      exit(-1);
    }
  }

  if (cilk_destroy_deque(deque) != 0) {
    fprintf(stderr, "Failed to shutdown Cilk thread\n");
    exit(-1);
  }

  return NULL;
}

void cilk_block_func(struct __ableC_tcb* tcb) {
  fprintf(stderr, "The cilk system currently cannot use blocking locks/synchronization");
  exit(100);
}

void cilk_unblock_func(struct __ableC_tcb* tcb) {
  fprintf(stderr, "The cilk system currently cannot use blocking locks/synchronization");
  exit(100);
}

struct __ableC_system_info* start_cilk_system(int nThreads, int ableC_sys_id) {
  struct __ableC_system_info* sysInfo = 
    cilk_malloc(sizeof(struct __ableC_system_info));

  if (sysInfo == NULL) return NULL;

  struct cilk_system* newSystem = cilk_malloc(sizeof(struct cilk_system));
  if (newSystem == NULL) { cilk_free(sysInfo, sizeof(struct __ableC_system_info)); return NULL; }

  sysInfo->system_id = ableC_sys_id;
  sysInfo->system_data = newSystem;
  sysInfo->block = cilk_block_func;
  sysInfo->unblock = cilk_unblock_func;

  newSystem->nThreads = nThreads;
  newSystem->shutdown = 0;

  newSystem->deques = cilk_malloc(sizeof(struct cilk_deque) * nThreads);
  if (newSystem->deques == NULL) {
    cilk_free(newSystem, sizeof(struct cilk_system));
    cilk_free(sysInfo, sizeof(struct __ableC_system_info));
    return NULL;
  }

  newSystem->threads = cilk_malloc(sizeof(pthread_t) * nThreads);

  if (newSystem->threads == NULL) {
    cilk_free(newSystem->deques, sizeof(struct cilk_deque) * nThreads);
    cilk_free(newSystem, sizeof(struct cilk_system));
    cilk_free(sysInfo, sizeof(struct __ableC_system_info));
    return NULL;
  }

  if (pthread_barrier_init(&(newSystem->barrier), NULL, nThreads) != 0) {
    cilk_free(newSystem->threads, sizeof(pthread_t) * nThreads);
    cilk_free(newSystem->deques, sizeof(struct cilk_deque) * nThreads);
    cilk_free(newSystem, sizeof(struct cilk_system));
    cilk_free(sysInfo, sizeof(struct __ableC_system_info));
    return NULL;
  }

  // We have to initialize all the deques before any threads start to avoid
  // race conditions
  for (int i = 0; i < nThreads; i++) {
    if (cilk_init_deque(&(newSystem->deques[i])) != 0) {
      fprintf(stderr, "Failed to initialize deque when starting Cilk system\n");
      exit(-1);
    }
  }

  for (int i = 0; i < nThreads; i++) {
    struct thread_info* info = cilk_malloc(sizeof(struct thread_info));
    if (info == NULL) {
      fprintf(stderr, "Failed to allocate memory when starting Cilk system\n");
      exit(-1);
    }

    info->sysInfo = sysInfo;
    info->deque = &(newSystem->deques[i]);
    if (pthread_create(&(newSystem->threads[i]), NULL, cilk_scheduler, info) != 0) {
      fprintf(stderr, "Failed to create thread when starting Cilk system\n");
      exit(-1);
    }
  }

  return sysInfo;
}

void stop_cilk_system(struct __ableC_system_info* sysInfo) {
  struct cilk_system* system = (struct cilk_system*) sysInfo->system_data;
  system->shutdown = 1;

  for (int i = 0; i < system->nThreads; i++) {
    int errnum = pthread_join(system->threads[i], NULL);
    if (errnum) {
      fprintf(stderr, "Failed to stop cilk, error in pthread_join: %s\n", strerror(errnum));
      exit(-1);
    }
  }

  int errnum = pthread_barrier_destroy(&(system->barrier));
  if (errnum) {
    fprintf(stderr, "Failed to stop cilk, error in pthread_barrier_destroy: %s\n", strerror(errnum));
    exit(-1);
  }

  cilk_free(system->deques, sizeof(struct deque) * system->nThreads);
  cilk_free(system->threads, sizeof(pthread_t) * system->nThreads);
  cilk_free(system, sizeof(struct cilk_system));
  cilk_free(sysInfo, sizeof(struct __ableC_system_info));
}
