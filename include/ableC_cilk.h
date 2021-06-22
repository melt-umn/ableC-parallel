#ifndef INCLUDE_ABLEC_CILK_H_
#define INCLUDE_ABLEC_CILK_H_

#include <stdlib.h>
#include <pthread.h>
#include <cilk.h>
#include <cilk-internal.h>
#include <cilk-cilk2c-pre.h>
#include <ableC_parallel.h>

#include "cilk-statics.h"

struct __ableC_system_info* init_ableC_parallel_cilk(int threads, int system_id) {
  CilkContext* context;

  Cilk_create_context(&context);

  Cilk_options cilk_default_options = CILK_DEFAULT_OPTIONS;
  *USE_PARAMETER1(options) = cilk_default_options;
  USE_PARAMETER1(options)->nproc = threads;

#ifdef HAVE_SCHED_SETAFFINITY
  if(USE_PARAMETER1(options)->pinned_mask > 1023) {
    /* do nothing (use the mask that was inherited) */
  } else {
    if(sched_setaffinity(0, sizeof(USE_PARAMETER1(options)->pinned_mask), &(USE_PARAMETER1(options)->pinned_mask))) {
      fprintf(stderr, "Failed pinning process, continuing on default mask...\n");
    }
  }
#endif

  Cilk_global_init(context);

  Cilk_scheduler_init(context);

  Cilk_create_children(context, Cilk_child_main);
  
  /* TODO: Not sure if I need these, they were in my old files */
  Cilk_global_init_2(context);
  Cilk_scheduler_init_2(context);
  context->Cilk_RO_params->invoke_main = NULL;

  struct __ableC_system_info* sys_info = malloc(sizeof(struct __ableC_system_info));
  sys_info->system_id = system_id;
  sys_info->system_data = context;
  sys_info->block = NULL;
  sys_info->unblock = NULL;

  return sys_info;
}

void stop_ableC_parallel_cilk(struct __ableC_system_info* sys_info) {
  CilkContext* context = sys_info->system_data;
  context->Cilk_global_state->done = 1;
  Cilk_terminate(context);
  free(sys_info);
}

// TODO: Does this actually improve performance?
_Atomic int ableC_cilk_counter = 0;

void ableC_parallel_cilk_spawn(CilkContext* context, CilkProcInfo* sig, CilkStackFrame* f) {
  Closure* t = Cilk_Closure_create_malloc(context, NULL);
  t->parent = NULL;
  t->join_counter = 0;
  t->status = CLOSURE_READY;

  f->entry = 0;
  WHEN_CILK_DEBUG(f->magic = CILK_STACKFRAME_MAGIC);
  f->sig = sig;

  t->frame = f;

  int target = ableC_cilk_counter++ % USE_PARAMETER1(active_size); //rand() % USE_PARAMETER1(active_size); // rand() isn't thread-safe
  Cilk_mutex_wait(context, NULL, &USE_PARAMETER1(deques)[target].mutex);
  t->next_ready = USE_PARAMETER1(deques)[target].top;
  t->prev_ready = NULL;
  USE_PARAMETER1(deques)[target].top = t;

  if(USE_PARAMETER1(deques)[target].bottom) {
    (t->next_ready)->prev_ready = t;
  } else {
    USE_PARAMETER1(deques)[target].bottom = t;
  }
  Cilk_mutex_signal(context, &USE_PARAMETER1(deques)[target].mutex);

  context->Cilk_global_state->nothing_to_do = 0;
  pthread_cond_broadcast(&(context->Cilk_global_state->wakeup_first_worker_cond));
}

#endif
