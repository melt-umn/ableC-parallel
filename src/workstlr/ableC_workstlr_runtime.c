#define ABLEC_NON_MAIN

#include <stdio.h>
#include <stdlib.h>
#include <pthread.h>

#include <ableC_workstlr_alloc.h>
#include <ableC_workstlr_deque.h>
#include <ableC_workstlr.h>

_Thread_local struct workstlr_deque* workstlr_thread_deque;
_Thread_local jmp_buf workstlr_jmp_buf;

struct thread_info {
  struct __ableC_system_info* sysInfo;
  struct workstlr_deque* deque;
};

void* workstlr_scheduler(void* ptr) {
  struct thread_info* info = ptr;
  struct __ableC_system_info* sysInfo = info->sysInfo;
  struct workstlr_system* system = (struct workstlr_system*) sysInfo->system_data;
  struct workstlr_deque* deque = info->deque;
  workstlr_free(info, sizeof(struct thread_info));

  // Set the thread locals
  workstlr_thread_deque = deque;
  // This results in bad errors about already held when we attempt to acquire
  // an unheld lock. We really should issue a TCB to every logical thread,
  // but this is a problem (FIXME)
  __ableC_thread_tcb = NULL;

  const int nThreads = system->nThreads;

  // Initialize the seed to be the # of the thread
  unsigned int seed = deque - system->deques;

  // Set the jump buffer (used to return to the scheduler when work is stolen)
  setjmp(workstlr_jmp_buf);

  struct workstlr_closure* closure;
  while (!system->shutdown) {
    closure = workstlr_pop_head(deque);

    if (closure == NULL) {
      // Attempt to steal (This implementation avoid the problem Cilk5 has 
      // where we never check our own deque again)
      int n = rand_r(&seed) % nThreads;
      while (closure == NULL && !system->shutdown) {
        closure = workstlr_pop_tail(&(system->deques[n]));
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

  if (workstlr_destroy_deque(deque) != 0) {
    fprintf(stderr, "Failed to shutdown Workstlr thread\n");
    exit(-1);
  }

  return NULL;
}

void workstlr_block_func(struct __ableC_tcb* tcb) {
  fprintf(stderr, "The workstlr system currently cannot use blocking locks/synchronization");
  exit(100);
}

void workstlr_unblock_func(struct __ableC_tcb* tcb) {
  fprintf(stderr, "The workstlr system currently cannot use blocking locks/synchronization");
  exit(100);
}

struct __ableC_system_info* start_workstlr_system(int nThreads, int ableC_sys_id) {
  struct __ableC_system_info* sysInfo = 
    workstlr_malloc(sizeof(struct __ableC_system_info));

  if (sysInfo == NULL) return NULL;

  struct workstlr_system* newSystem = workstlr_malloc(sizeof(struct workstlr_system));
  if (newSystem == NULL) { workstlr_free(sysInfo, sizeof(struct __ableC_system_info)); return NULL; }

  sysInfo->system_id = ableC_sys_id;
  sysInfo->system_data = newSystem;
  sysInfo->block = workstlr_block_func;
  sysInfo->unblock = workstlr_unblock_func;

  newSystem->nThreads = nThreads;
  newSystem->shutdown = 0;

  newSystem->deques = workstlr_malloc(sizeof(struct workstlr_deque) * nThreads);
  if (newSystem->deques == NULL) {
    workstlr_free(newSystem, sizeof(struct workstlr_system));
    workstlr_free(sysInfo, sizeof(struct __ableC_system_info));
    return NULL;
  }

  newSystem->threads = workstlr_malloc(sizeof(pthread_t) * nThreads);

  if (newSystem->threads == NULL) {
    workstlr_free(newSystem->deques, sizeof(struct workstlr_deque) * nThreads);
    workstlr_free(newSystem, sizeof(struct workstlr_system));
    workstlr_free(sysInfo, sizeof(struct __ableC_system_info));
    return NULL;
  }

  if (pthread_barrier_init(&(newSystem->barrier), NULL, nThreads) != 0) {
    workstlr_free(newSystem->threads, sizeof(pthread_t) * nThreads);
    workstlr_free(newSystem->deques, sizeof(struct workstlr_deque) * nThreads);
    workstlr_free(newSystem, sizeof(struct workstlr_system));
    workstlr_free(sysInfo, sizeof(struct __ableC_system_info));
    return NULL;
  }

  // We have to initialize all the deques before any threads start to avoid
  // race conditions
  for (int i = 0; i < nThreads; i++) {
    if (workstlr_init_deque(&(newSystem->deques[i])) != 0) {
      fprintf(stderr, "Failed to initialize deque when starting Workstlr system\n");
      exit(-1);
    }
  }

  for (int i = 0; i < nThreads; i++) {
    struct thread_info* info = workstlr_malloc(sizeof(struct thread_info));
    if (info == NULL) {
      fprintf(stderr, "Failed to allocate memory when starting Workstlr system\n");
      exit(-1);
    }

    info->sysInfo = sysInfo;
    info->deque = &(newSystem->deques[i]);
    if (pthread_create(&(newSystem->threads[i]), NULL, workstlr_scheduler, info) != 0) {
      fprintf(stderr, "Failed to create thread when starting Workstlr system\n");
      exit(-1);
    }
  }

  return sysInfo;
}

void stop_workstlr_system(struct __ableC_system_info* sysInfo) {
  struct workstlr_system* system = (struct workstlr_system*) sysInfo->system_data;
  system->shutdown = 1;

  for (int i = 0; i < system->nThreads; i++) {
    int errnum = pthread_join(system->threads[i], NULL);
    if (errnum) {
      fprintf(stderr, "Failed to stop workstlr, error in pthread_join: %s\n", strerror(errnum));
      exit(-1);
    }
  }

  int errnum = pthread_barrier_destroy(&(system->barrier));
  if (errnum) {
    fprintf(stderr, "Failed to stop workstlr, error in pthread_barrier_destroy: %s\n", strerror(errnum));
    exit(-1);
  }

  workstlr_free(system->deques, sizeof(struct workstlr_deque) * system->nThreads);
  workstlr_free(system->threads, sizeof(pthread_t) * system->nThreads);
  workstlr_free(system, sizeof(struct workstlr_system));
  workstlr_free(sysInfo, sizeof(struct __ableC_system_info));
}
