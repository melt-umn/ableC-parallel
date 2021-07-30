#include <ableC_cilk.h>
#include <ableC_posix.h>
#include <stdio.h>
#include <stdlib.h>

#include "nqueens.h"

cilk parallel fibSys;
cilk parallel qnsSys;

parallel by fibSys int fib(int n);
parallel by qnsSys int count_nqueens(int n);

int main() {
  fibSys = new cilk parallel(4);
  qnsSys = new cilk parallel(4);

  posix group grp; grp = new posix group();

  int nFib = 0, nQns = 0, tmp;

  srand(314159);
  for (int i = 0; i < 10; i++) {
    int type = rand() % 2;
    int inpt = rand() % 4;

    if (type == 0) {
      nFib++;
      spawn tmp = fib(30 + inpt); by fibSys; in grp;
    } else {
      nQns++;
      spawn tmp = count_nqueens(10 + inpt); by qnsSys; in grp;
    }
  }

  sync grp;

  printf("Fib Queries: %d\n", nFib);
  printf("nQn Queries: %d\n", nQns);

  delete grp;
  delete fibSys;
  delete qnsSys;

  return 0;
}

/* Fibonacci Code */
parallel by fibSys int fib(int n) {
  if (n <= 1) return n;

  int x, y;
  spawn x = fib(n-1);
  spawn y = fib(n-2);
  sync;

  return x + y;
}

/* N-Queens Code */
parallel by qnsSys int count_helper(int n, chess_board* board, int r);
parallel by qnsSys int count_body(int n, chess_board* board, int r, int c, int* ret) {
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

parallel by qnsSys int count_helper(int n, chess_board* board, int r) {
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

parallel by qnsSys int count_nqueens(int n) {
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
