#define ABLEC_NON_MAIN

#include <stdio.h>
#include <stdlib.h>
#include <pthread.h>

#include <ableC_workstlr.h>
#include <ableC_workstlr_alloc.h>
#include <ableC_bworkstlr_deque.h>
#include <ableC_bworkstlr.h>

#include <ableC_balancer.h>

void* bworkstlr_additional(void*);

// Special function for the first thread we invoke, since it will not yield
// (to ensure don't get rid of all our threads)
void* bworkstlr_scheduler(void* ptr) {
  struct bworkstlr_system* system = ptr;
  struct __balancer* balancer = system->bal;

  const int nDeques = system->maxThreads;
  
  if (system->shutdown) {
    system->numThreads--;
    
    balancer->release_thread(balancer);
    return NULL;
  }
  
  struct bworkstlr_deque* deque = system->deques;
  if (!bworkstlr_claim_deque(deque)) { 
    fprintf(stderr, "Initial bworkstlr thread failed to acquire its deque\n");
    exit(1);
  }

  // Set the thread locals
  workstlr_thread_deque = (struct workstlr_deque*) deque;
  // This results in bad errors about already held when we attempt to acquire
  // an unheld lock. We really should issue a TCB to every logical thread,
  // but this is a problem (FIXME)
  __ableC_thread_tcb = NULL;


  // Initialize the seed to be the # of the thread
  unsigned int seed = 0;

  // Set the jump buffer (used to return to the scheduler when work is stolen)
  setjmp(workstlr_jmp_buf);

  struct workstlr_closure* closure;
  while (!system->shutdown) {
    closure = workstlr_pop_head((struct workstlr_deque*) deque);

    if (closure == NULL) {
      // Attempt to steal (This implementation avoid the problem Cilk5 has 
      // where we never check our own deque again)
      int n = rand_r(&seed) % nDeques;

      while (closure == NULL && !system->shutdown) {
        closure = workstlr_pop_tail((struct workstlr_deque*) &(system->deques[n]));
        n = (n + 1) % nDeques;
      }

      if (system->shutdown) break;
    }

    // Because this if the first thread (and it's deque receives all the
    // work, we'll just make the request every time we find work)
    if (balancer->request_thread(balancer, bworkstlr_additional, system)) {
      system->numThreads++;
    }

    closure->func(closure);
  }

  bworkstlr_release_deque(deque);
  system->numThreads--;

  balancer->release_thread(balancer);
  return NULL;
}


struct bworkstlr_yield_in {
  struct bworkstlr_deque* deque;
  struct bworkstlr_system* system;
};
void bworkstlr_yield(void* arg) {
  struct bworkstlr_yield_in* input = arg;
  bworkstlr_release_deque(input->deque);
  input->system->numThreads--;
}

void* bworkstlr_additional(void* ptr) {
  struct bworkstlr_system* system = ptr;
  struct __balancer* balancer = system->bal;

  const int nDeques = system->maxThreads;
  
  if (system->shutdown) {
    system->numThreads--;
    
    balancer->release_thread(balancer);
    return NULL;
  }

  int i;
  for (i = 0; i < system->maxThreads; i++) {
    if (bworkstlr_claim_deque(system->deques + i)) break;
  }
  // If there are no available deques, this is an error, we scream and exit
  if (__builtin_expect(i == nDeques, 0)) {
    fprintf(stderr, "bworkstlr thread does not have a deque\n");
    exit(1);
  }

  struct bworkstlr_deque* deque = system->deques + i;

  // Set the thread locals
  workstlr_thread_deque = (struct workstlr_deque*) deque;
  // This results in bad errors about already held when we attempt to acquire
  // an unheld lock. We really should issue a TCB to every logical thread,
  // but this is a problem (FIXME)
  __ableC_thread_tcb = NULL;


  // Initialize the seed to be the # of the thread
  unsigned int seed = i;

  // Set the jump buffer (used to return to the scheduler when work is stolen)
  setjmp(workstlr_jmp_buf);

  struct workstlr_closure* closure;
  while (!system->shutdown) {
    closure = workstlr_pop_head((struct workstlr_deque*) deque);

    if (closure == NULL) {
      // Attempt to steal (This implementation avoid the problem Cilk5 has 
      // where we never check our own deque again)
      int n = rand_r(&seed) % nDeques;
      int cnt = 0;

      while (closure == NULL && !system->shutdown) {
        closure = workstlr_pop_tail((struct workstlr_deque*) &(system->deques[n]));
        n = (n + 1) % nDeques;
        cnt++;

        // If we've gone all the way around and not found any work, offer to
        // yield
        if (closure == NULL && cnt >= nDeques) {
          cnt = 0;
          
          // offer to yield
          struct bworkstlr_yield_in input = {deque, system};
          balancer->yield_thread(balancer, bworkstlr_yield, &input);
        }
      }

      if (system->shutdown) break;
      
      // If we've found work to steal, there's probably other work (maybe)
      if (balancer->request_thread(balancer, bworkstlr_additional, system)) {
        system->numThreads++;
      }
    }

    closure->func(closure);
  }

  bworkstlr_release_deque(deque);
  system->numThreads--;
  
  balancer->release_thread(balancer);
  return NULL;
}

void bworkstlr_block_func(struct __ableC_tcb* tcb) {
  fprintf(stderr, "The bworkstlr system currently cannot use blocking locks/synchronization");
  exit(100);
}

void bworkstlr_unblock_func(struct __ableC_tcb* tcb) {
  fprintf(stderr, "The bworkstlr system currently cannot use blocking locks/synchronization");
  exit(100);
}

struct __ableC_system_info* start_bworkstlr_system(struct __balancer* bal,
                                            int maxThreads, int ableC_sys_id) {
  struct __ableC_system_info* sysInfo = 
    workstlr_malloc(sizeof(struct __ableC_system_info));

  if (sysInfo == NULL) return NULL;

  struct bworkstlr_system* newSystem = workstlr_malloc(sizeof(struct bworkstlr_system));
  if (newSystem == NULL) { workstlr_free(sysInfo, sizeof(struct __ableC_system_info)); return NULL; }

  sysInfo->system_id = ableC_sys_id;
  sysInfo->system_data = newSystem;
  sysInfo->block = bworkstlr_block_func;
  sysInfo->unblock = bworkstlr_unblock_func;

  newSystem->maxThreads = maxThreads;
  newSystem->numThreads = 1;
  newSystem->shutdown = 0;
  newSystem->bal = bal;

  newSystem->deques = workstlr_malloc(sizeof(struct bworkstlr_deque) * maxThreads);
  if (newSystem->deques == NULL) {
    workstlr_free(newSystem, sizeof(struct bworkstlr_system));
    workstlr_free(sysInfo, sizeof(struct __ableC_system_info));
    return NULL;
  }

  // We have to initialize all the deques before any threads start to avoid
  // race conditions
  for (int i = 0; i < maxThreads; i++) {
    if (bworkstlr_init_deque(&(newSystem->deques[i])) != 0) {
      fprintf(stderr, "Failed to initialize deque when starting bworkstlr system\n");
      exit(-1);
    }
  }

  bal->demand_thread(bal, bworkstlr_scheduler, newSystem);

  return sysInfo;
}

void stop_bworkstlr_system(struct __ableC_system_info* sysInfo) {
  struct bworkstlr_system* system = (struct bworkstlr_system*) sysInfo->system_data;
  system->shutdown = 1;

  __sync_synchronize();

  while (system->numThreads > 0) ;
  
  for (int i = 0; i < system->maxThreads; i++) {
    if (bworkstlr_destroy_deque(system->deques + i)) {
      fprintf(stderr, "Failed to destroy bworkstlr deque\n");
      exit(-1);
    }
  }

  workstlr_free(system->deques, sizeof(struct bworkstlr_deque) * system->maxThreads);
  workstlr_free(system, sizeof(struct bworkstlr_system));
  workstlr_free(sysInfo, sizeof(struct __ableC_system_info));
}
