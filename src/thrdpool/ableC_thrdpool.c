#define ABLEC_NON_MAIN

#include <ableC_thrdpool.h>
#include <ableC_parallel.h>
#include <stdio.h>
#include <stdlib.h>
#include <pthread.h>
#include <setjmp.h>

_Thread_local jmp_buf __thrdpool_return;
_Thread_local void* __thrdpool_please_free = NULL;

void* __thrdpool_launcher(void* inpt) {
  struct __ableC_system_info* sys_info = (struct __ableC_system_info*) inpt;
  struct __thrdpool_system_info* system = 
    (struct __thrdpool_system_info*) sys_info->system_data;

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
    while (system->work_head == NULL) {
      checked_pthread_cond_wait(&(system->cv), &(system->lk));
    }
    
    struct __thrdpool_work_item* work = system->work_head;
    system->work_head = work->next;

    if (system->work_head == NULL) {
      system->work_tail = NULL;
    }

    checked_pthread_mutex_unlock(&(system->lk));

    if (work->started == -1) {
      free(work);
      return NULL;
    } else if (work->started == 1) {
      __ableC_thread_tcb = &(work->contents.resume.tcb);
     
      longjmp(work->contents.resume.env, 1);

      fprintf(stderr, "Internal error in thrdpool. Incorrectly returned to thread-pool control\n");
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
        fprintf(stderr, "Failed to allocate stack for thread-pool task\n");
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
      fprintf(stderr, "Internal error in thrdpool. Should not be here.\n");
      exit(-1);
    }
  }
}

void __thrdpool_block_func(struct __ableC_tcb* tcb) {
  struct __thrdpool_work_item* work = (struct __thrdpool_work_item*) tcb->thread_info;

  __ableC_spinlock_acquire(&(work->spinlock));
  while (tcb->status != UNBLOCKING) {
    tcb->status = BLOCKING;
    if (setjmp(work->contents.resume.env) == 0) {
      longjmp(__thrdpool_return, 1);
      
      fprintf(stderr, "Internal Error: thrdpool longjmp failed\n");
      exit(-1);
    } else {
      __ableC_spinlock_acquire(&(work->spinlock));
    }
  }

  tcb->status = RUNNING;
  __ableC_spinlock_release(&(work->spinlock));
}

void __thrdpool_unblock_func(struct __ableC_tcb* tcb) {
  struct __thrdpool_work_item* work = 
    (struct __thrdpool_work_item*) tcb->thread_info;
  struct __thrdpool_system_info* sysInfo = 
    (struct __thrdpool_system_info*) tcb->system->system_data;
  
  __ableC_spinlock_acquire(&(work->spinlock));
  if (tcb->status == BLOCKED) {
    tcb->status = UNBLOCKING;
    __ableC_spinlock_release(&(work->spinlock));
    
    work->next = NULL;
    checked_pthread_mutex_lock(&(sysInfo->lk));
    if (sysInfo->work_head == NULL) {
      sysInfo->work_head = work;
      sysInfo->work_tail = work;
    } else {
      sysInfo->work_tail->next = work;
      sysInfo->work_tail = work;
    }

    checked_pthread_cond_signal(&(sysInfo->cv));
    checked_pthread_mutex_unlock(&(sysInfo->lk));

  } else {
    tcb->status = UNBLOCKING;
    __ableC_spinlock_release(&(work->spinlock));
  }
}
