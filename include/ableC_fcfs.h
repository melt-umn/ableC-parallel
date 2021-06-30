#ifndef ABLEC_FCFS_H_
#define ABLEC_FCFS_H_

#include <ableC_parallel.h>
#include <ableC_balancer.h>
#include <stdlib.h>
#include <pthread.h>

struct __attribute__((refId("edu:umn:cs:melt:exts:ableC:parallel:exts:balancer:impl:fcfs:balancer"))) __fcfs_balancer {
  unsigned int maxThreads;
  volatile unsigned int curThreads;
  unsigned int recentRequests;
  unsigned int numDemands;
  pthread_attr_t attr;
  pthread_mutex_t lck;
  pthread_cond_t cv;
};

int _fcfs_request_thread(struct __balancer* bal,
                    void* (*start_routine)(void*), void* arg) {
  struct __fcfs_balancer* balancr = (struct __fcfs_balancer*) (bal->sysInfo);

  int granted = 0;
  checked_pthread_mutex_lock(&(balancr->lck));

  if (balancr->curThreads < balancr->maxThreads) {
    granted = 1;
    balancr->curThreads++;

    checked_pthread_mutex_unlock(&(balancr->lck));

    pthread_t thd;
    checked_pthread_create(&thd, &(balancr->attr), start_routine, arg);
  } else {
    balancr->recentRequests++;
    checked_pthread_mutex_unlock(&(balancr->lck));
  }

  return granted;
}

void _fcfs_demand_thread(struct __balancer* bal,
                    void* (*start_routine)(void*), void* arg) {
  struct __fcfs_balancer* balancr = (struct __fcfs_balancer*) (bal->sysInfo);
  
  checked_pthread_mutex_lock(&(balancr->lck));
  
  balancr->numDemands++;
  while (balancr->curThreads >= balancr->maxThreads) {
    checked_pthread_cond_wait(&(balancr->cv), &(balancr->lck));
  }
  balancr->numDemands--;
  balancr->curThreads++;

  checked_pthread_mutex_unlock(&(balancr->lck));

  pthread_t thd;
  checked_pthread_create(&thd, &(balancr->attr), start_routine, arg);
}

void _fcfs_yield_thread(struct __balancer* bal,
                    void (*stop_routine)(void*), void* arg) {
  struct __fcfs_balancer* balancr = (struct __fcfs_balancer*) (bal->sysInfo);
  checked_pthread_mutex_lock(&(balancr->lck));

  if (balancr->numDemands > 0 || balancr->recentRequests > 0) {
    balancr->curThreads--;
    
    // Basically just use recentRequests to know whether there has been one or
    // not; a better implementation might just decrease this by some number, not
    // set it to 0
    if (balancr->numDemands == 0) {
      balancr->recentRequests = 0;
    } else {
      checked_pthread_cond_signal(&(balancr->cv));
    }

    checked_pthread_mutex_unlock(&(balancr->lck));
    stop_routine(arg);
    pthread_exit(0);
  } else {
    checked_pthread_mutex_unlock(&(balancr->lck));
  }
}

void _fcfs_release_thread(struct __balancer* bal) {
  struct __fcfs_balancer* balancr = (struct __fcfs_balancer*) (bal->sysInfo);
  
  checked_pthread_mutex_lock(&(balancr->lck));
  
  balancr->curThreads--;
  if (balancr->numDemands != 0) {
    checked_pthread_cond_signal(&(balancr->cv));
  }

  checked_pthread_mutex_unlock(&(balancr->lck));
  pthread_exit(0);
}

#endif // ABLEC_FCFS_H_
