#include <ableC_cilk.h>
#include <ableC_posix.h>
#include <stdlib.h>
#include <time.h>

#include "nqueens.h"

cilk parallel sys;

parallel by sys int count_helper(int n, chess_board* board, int r);
parallel by sys int count_nqueens(int n);

int main(int argc, char** argv) {
  if (argc != 2) {
    fprintf(stderr, "Usage: %s <n>\n", argv[0]);
    fprintf(stderr, "Where:\n");
    fprintf(stderr, "\tn is the size of the board\n");
    exit(1);
  }

  const int n = atoi(argv[1]);
  if (n < 1) {
    fprintf(stderr, "Value of n must be a positive integer, given '%s'\n", argv[1]);
    exit(2);
  }
  
  sys = new cilk parallel(4);
  posix thread thd; thd = new posix thread();

  int res;

  struct timespec begin, end;
  int retBegin, retEnd;
  retBegin = clock_gettime(CLOCK_MONOTONIC, &begin);
  
  spawn res = count_nqueens(n); by sys; as thd;
  sync thd;

  retEnd = clock_gettime(CLOCK_MONOTONIC, &end);

  if (retBegin || retEnd) {
    fprintf(stderr, "Error in clock_gettime\n");
    exit(3);
  }

  long diff_nsec = end.tv_nsec - begin.tv_nsec;
  time_t diff_sec = end.tv_sec - begin.tv_sec;
  if (diff_nsec < 0) {
    diff_sec -= 1;
    diff_nsec += 1000000000L;
  }

  printf("Elapsed Time: %ld.%09ld\n", diff_sec, diff_nsec);
  printf("Total Arrangements: %d\n", res);

  delete thd;
  delete sys;

  return 0;
}

parallel by sys int count_body(int n, chess_board* board, int r, int c, int* ret) {
  if (board->cols[c] == FILLED) { return 0; }

  int posDiagonal = (n-1) - r + c;
  int negDiagonal = r + c;

  if (board->posDiagonal[posDiagonal] == FILLED
      || board->negDiagonal[negDiagonal] == FILLED) { return 0; }

  chess_board* new_board = malloc(sizeof(chess_board));
  if (new_board == NULL || initialize_board(n, new_board) != 1) exit(50);
  if (copy_board(board, new_board) != 1) exit(50);
  new_board->cols[c] = FILLED;
  new_board->posDiagonal[posDiagonal] = FILLED;
  new_board->negDiagonal[negDiagonal] = FILLED;

  int res;
  spawn res = count_helper(n, new_board, r+1);
  sync;

  destroy_board(new_board);
  free(new_board);

  *ret = res;
  return 0;
}

parallel by sys int count_helper(int n, chess_board* board, int r) {
  if (r == n) {
    return 1;
  }

  int* cnts = calloc(n, sizeof(int));
  parallel for (int c = 0; c < n; c++) {
    count_body(n, board, r, c, &cnts[c]);
  }
  sync;

  int cnt = 0;
  for (int i = 0; i < n; i++)
    cnt += cnts[i];
  free(cnts);
  
  return cnt;
}

parallel by sys int count_nqueens(int n) {
  chess_board* board = malloc(sizeof(chess_board));
  if (board == NULL || initialize_board(n, board) != 1) exit(50);

  int res;
  spawn res = count_helper(n, board, 0);
  sync;

  destroy_board(board);
  free(board);

  return res;
}

int initialize_board(int n, chess_board* board) {
  if (n < 1) {
    return 0;
  }
  
  board->n = n;
  
  if ((board->cols = calloc(n, sizeof(char))) == NULL) {
    return 0;
  }
  
  if ((board->posDiagonal = calloc(2* n - 1, sizeof(char))) == NULL) {
    free(board->cols);
    return 0;
  }
  
  if ((board->negDiagonal = calloc(2* n - 1, sizeof(char))) == NULL) {
    free(board->cols);
    free(board->posDiagonal);
    return 0;
  }
  
  return 1;
}

void destroy_board(chess_board* board) {
  free(board->cols);
  free(board->posDiagonal);
  free(board->negDiagonal);
  
  board->n = 0;
  board->cols = NULL;
  board->posDiagonal = NULL;
  board->negDiagonal = NULL;
}

int copy_board(chess_board* src, chess_board* dst) {
  if (src == dst)
    return 1;
  
  if (src->n != dst->n)
    return 0;
  
  const int n = src->n;
  
  memcpy(dst->cols, src->cols, sizeof(char) * n);
  memcpy(dst->posDiagonal, src->posDiagonal, sizeof(char) * (2 * n - 1));
  memcpy(dst->negDiagonal, src->negDiagonal, sizeof(char) * (2 * n - 1));
  
  return 1;
}
