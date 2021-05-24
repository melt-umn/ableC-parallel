#ifndef INCLUDE_ALLOC_H_
#define INCLUDE_ALLOC_H_

#include <stdlib.h>
#define cilk_malloc(s) malloc(s)
#define cilk_free(p, s) free(p)

#endif
