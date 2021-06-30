#define ABLEC_NON_MAIN
// Must also link with ableC_parallel_thrdpool

#include <ableC_bthrdpool.h>
#include <ableC_parallel.h>
#include <stdio.h>
#include <stdlib.h>
#include <pthread.h>
#include <setjmp.h>

void* __bthrdpool_additional(void* inpt);

void* __bthrdpool_launcher(void* inpt) {
  struct __ableC_system_info* sys_info = (struct __ableC_system_info*) inpt;
  struct __bthrdpool_system_info* system = 
    (struct __bthrdpool_system_info*) sys_info->system_data;
  struct __balancer* balancer = system->bal;

  __ableC_thread_tcb = NULL;

  if (setjmp(__thrdpool_return) != 0) {
    if (__thrdpool_please_free != NULL) {
      free(__thrdpool_please_free);
      __thrdpool_please_free = NULL;
    }

    if (__ableC_thread_tcb != NULL) {
      __ableC_thread_tcb->status = BLOCKED;
      __ableC_spinlock_release(&(((struct __thrdpool_work_item*) __ableC_thread_tcb->thread_info)->spinlock));
      __ableC_thread_tcb = NULL;
    }
  }

  while (1) {
    checked_pthread_mutex_lock(&(system->lk));
    while (system->work_head == NULL && !system->shutdown) {
      // The initial thread won't ever yield so that we make sure to keep
      // at least one running at all times
      checked_pthread_cond_wait(&(system->cv), &(system->lk));
    }

    if (system->work_head == NULL && system->shutdown) {
      checked_pthread_mutex_unlock(&(system->lk));
      system->num_thrds--;
      balancer->release_thread(balancer);
      return NULL;
    }
    
    struct __thrdpool_work_item* work = system->work_head;
    system->work_head = work->next;

    if (system->work_head == NULL) {
      system->work_tail = NULL;
    } else { // Since there's more work, might as well try to spin up a new thread
      if (balancer->request_thread(balancer, __bthrdpool_additional, inpt)) {
        system->num_thrds++;
      }
    }

    checked_pthread_mutex_unlock(&(system->lk));

    if (work->started == 1) {
      __ableC_thread_tcb = &(work->contents.resume.tcb);
     
      longjmp(work->contents.resume.env, 1);

      fprintf(stderr, "Internal error in bthrdpool. Incorrectly returned to bthread-pool control\n");
      exit(-1);
    } else { // stared == 0, thread needs to be allocated a TCB and stack
      work->started = 1;
      work->spinlock = 0;
      work->next = NULL;

      void (*func)(void*) = work->contents.start.f;
      void* args = work->contents.start.args;
      struct __ableC_tcb* parent = work->contents.start.parent;

      work->contents.resume.stack = malloc(__ableC_stack_size);
      if (__builtin_expect(work->contents.resume.stack == NULL, 0)) {
        fprintf(stderr, "Failed to allocate stack for bthread-pool task\n");
        exit(-1);
      }
      
      work->contents.resume.tcb.status = RUNNING;
      work->contents.resume.tcb.system = sys_info;
      work->contents.resume.tcb.thread_info = work;
      work->contents.resume.tcb.parent = parent;
      work->contents.resume.tcb.next = NULL;

      __ableC_thread_tcb = &(work->contents.resume.tcb);

      // Jump to new thread
      #ifdef __x86_64__
      asm ( "movq  %[stack], %%rsp\n"
            //"pushq %%rsp\n" // push 8 bytes so that the call produces a 16B alignment
            "movq  %[args],  %%rdi\n"
            "callq *%[func]\n"
          : /* no outputs */
          : [func] "r"(func), [args] "r"(args), [stack] "r"(work->contents.resume.stack + __ableC_stack_size)
          : "rdi" );
      #else
        #error "Code for jumping to a new stack and logical thread only implemented for x86-64"
      #endif

      // We never reach here... (If all goes well)
      fprintf(stderr, "Internal error in bthrdpool. Should not be here.\n");
      exit(-1);
    }
  }
}

void __bthrdpool_yield(void* arg) {
  struct __bthrdpool_system_info* system =
    (struct __bthrdpool_system_info*) arg;

  checked_pthread_mutex_unlock(&(system->lk));
  system->num_thrds--;
}

void* __bthrdpool_additional(void* inpt) {
  struct __ableC_system_info* sys_info = (struct __ableC_system_info*) inpt;
  struct __bthrdpool_system_info* system = 
    (struct __bthrdpool_system_info*) sys_info->system_data;
  struct __balancer* balancer = system->bal;

  __ableC_thread_tcb = NULL;

  if (system->shutdown) {
    system->num_thrds--;
    balancer->release_thread(balancer);
    return NULL;
  }

  if (setjmp(__thrdpool_return) != 0) {
    if (__thrdpool_please_free != NULL) {
      free(__thrdpool_please_free);
      __thrdpool_please_free = NULL;
    }

    if (__ableC_thread_tcb != NULL) {
      __ableC_thread_tcb->status = BLOCKED;
      __ableC_spinlock_release(&(((struct __thrdpool_work_item*) __ableC_thread_tcb->thread_info)->spinlock));
      __ableC_thread_tcb = NULL;
    }
  }

  while (1) {
    checked_pthread_mutex_lock(&(system->lk));
    while (system->work_head == NULL & !system->shutdown) {
      balancer->yield_thread(balancer, __bthrdpool_yield, system);
      checked_pthread_cond_wait(&(system->cv), &(system->lk));
    }
    
    if (system->work_head == NULL && system->shutdown) {
      checked_pthread_mutex_unlock(&(system->lk));
      system->num_thrds--;
      balancer->release_thread(balancer);
      return NULL;
    }
    
    struct __thrdpool_work_item* work = system->work_head;
    system->work_head = work->next;

    if (system->work_head == NULL) {
      system->work_tail = NULL;
    } else { // Since there's more work, might as well try to spin up a new thread
      if (balancer->request_thread(balancer, __bthrdpool_additional, inpt)) {
        system->num_thrds++;
      }
    }

    checked_pthread_mutex_unlock(&(system->lk));
    
    if (work->started == 1) {
      __ableC_thread_tcb = &(work->contents.resume.tcb);
     
      longjmp(work->contents.resume.env, 1);

      fprintf(stderr, "Internal error in bthrdpool. Incorrectly returned to bthread-pool control\n");
      exit(-1);
    } else { // stared == 0, thread needs to be allocated a TCB and stack
      work->started = 1;
      work->spinlock = 0;
      work->next = NULL;

      void (*func)(void*) = work->contents.start.f;
      void* args = work->contents.start.args;
      struct __ableC_tcb* parent = work->contents.start.parent;

      work->contents.resume.stack = malloc(__ableC_stack_size);
      if (__builtin_expect(work->contents.resume.stack == NULL, 0)) {
        fprintf(stderr, "Failed to allocate stack for bthread-pool task\n");
        exit(-1);
      }
      
      work->contents.resume.tcb.status = RUNNING;
      work->contents.resume.tcb.system = sys_info;
      work->contents.resume.tcb.thread_info = work;
      work->contents.resume.tcb.parent = parent;
      work->contents.resume.tcb.next = NULL;

      __ableC_thread_tcb = &(work->contents.resume.tcb);

      // Jump to new thread
      #ifdef __x86_64__
      asm ( "movq  %[stack], %%rsp\n"
            //"pushq %%rsp\n" // push 8 bytes so that the call produces a 16B alignment
            "movq  %[args],  %%rdi\n"
            "callq *%[func]\n"
          : /* no outputs */
          : [func] "r"(func), [args] "r"(args), [stack] "r"(work->contents.resume.stack + __ableC_stack_size)
          : "rdi" );
      #else
        #error "Code for jumping to a new stack and logical thread only implemented for x86-64"
      #endif

      // We never reach here... (If all goes well)
      fprintf(stderr, "Internal error in bthrdpool. Should not be here.\n");
      exit(-1);
    }
  }
}
