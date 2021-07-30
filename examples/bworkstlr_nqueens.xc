#include <stdio.h>
#include <stdlib.h>

#include <ableC_posix.h>
#include <ableC_bworkstlr.h>
#include <ableC_bthrdpool.h>
#include <ableC_fcfs.h>

#include "nqueens.h"
#include "timing.h"
#include "base64.h"

#define N_FIND 48
#define N_CNT 16

bworkstlr parallel wrks;
bthrdpool parallel thdp;

int nqueens_next(const int n, char* init);
parallel by wrks int count_nqueens(int n, char* init);

void find_test(bthrdpool parallel* thdp) {
  posix group grp; grp = new posix group();

  unsigned int seed = 314159;

  int* n   = malloc(sizeof(int) * N_FIND);
  int* res = malloc(sizeof(int) * N_FIND);
  char** inits = malloc(sizeof(char*) * N_FIND);

  for (int i = 0; i < N_FIND; i++) {
    n[i] = rand_r(&seed) % 3 + 29; // 29 - 31
    inits[i] = malloc(sizeof(char) * n[i]);
    memset(inits[i], '0', sizeof(char) * n[i]);
  }

  for (int i = 0; i < N_FIND; i++) {
    spawn nqueens_next(n[i], inits[i]);
      by *thdp; in grp; private inits, n, i, res; global nqueens_next;
  }
  sync grp;
  
  free(n);
  free(res);
  for (int i = 0; i < N_FIND; i++)
    free(inits[i]);
  free(inits);

  delete grp;
}

void count_test(bworkstlr parallel* wrks) {
  posix group grp; grp = new posix group();

  unsigned int seed = 217828;

  int* n = malloc(sizeof(int) * N_CNT);
  int* res = malloc(sizeof(int) * N_CNT);
  char* init = "              ";

  for (int i = 0; i < N_CNT; i++) {
    n[i] = rand_r(&seed) % 3 + 12; // 12 - 14
  }

  for (int i = 0; i < N_CNT; i++) {
    spawn res[i] = count_nqueens(n[i], init);
      by *wrks; in grp;
  }
  sync grp;

  free(n);
  free(res);
  delete grp;
}

int main() {
  fcfs balancer blncr = new fcfs balancer(8);
  wrks = new bworkstlr parallel(blncr, 8);
  thdp = new bthrdpool parallel(blncr);

  posix parallel thds = new posix parallel();

  posix group grp; grp = new posix group();
  
  START_TIMING
  spawn find_test(&thdp); by thds; in grp; public thdp; global find_test;
  spawn count_test(&wrks); by thds; in grp; public wrks; global count_test;
  sync grp;
  STOP_TIMING

  delete grp;
  delete wrks;
  delete thdp;
  delete blncr;

  return 0;
}

/******************************************************************************
 * NQueens Problems
 ******************************************************************************/
int nqueens_find_next(const int n, chess_board* board, int iR, int iC, int goUp);

// Returns 1 on success, 0 if no next solution exists, and -1 if there's an 
// error
int nqueens_next(const int n, char* init) {
  // First we increment init
  for (int i = n - 1; i >= 0; i--) {
    int v = base64_to_int(init[i]) + 1;
    
    if (v < n) {
      init[i] = int_to_base64(v);
      break;
    } else {
      init[i] = '0';

      // If we reach the front and set everything to 0, we've hit the end
      if (i == 0)
        return 0;
    }
  }

  chess_board board;
  if (initialize_board(n, &board) == 0)
    return -1;

  // Now we determine how many of the rows specify a valid board configuration
  int valid_rows = load_board(n, init, &board);

  if (valid_rows == 0)
    return -1;

  int res =
    nqueens_find_next(n, &board, valid_rows, base64_to_int(init[valid_rows]), 1);
  if (res == 0) {
    destroy_board(&board);
    return 0;
  }

  memcpy(init, board.order, sizeof(char) * n);
  destroy_board(&board);
  return 1;
}

// Find the next solution starting in row iR and with column iC, traversing
// upward and changing already set rows if goUp = 1. Returns 1 on sucess and
// the board is updated to reflect the solution, otherwise returns 0 and the
// state of the board is undefined
int nqueens_find_next(const int n, chess_board* board, int iR, int iC, int goUp) {
  if (iR == n)
    return 1;

  const int posDiagonalBase = (n - 1) - iR;

  for (int c = iC; c < n; c++) {
    if (board->cols[c] == FILLED)
      continue;

    int posDiagonal = posDiagonalBase + c;
    int negDiagonal = iR + c;

    if (board->posDiagonal[posDiagonal] == FILLED
        || board->negDiagonal[negDiagonal] == FILLED)
      continue;

    board->cols[c] = FILLED;
    board->posDiagonal[posDiagonal] = FILLED;
    board->negDiagonal[negDiagonal] = FILLED;
    board->order[iR] = int_to_base64(c);

    if (nqueens_find_next(n, board, iR + 1, 0, 0) == 1) {
      return 1;
    }

    board->cols[c] = VACANT;
    board->posDiagonal[posDiagonal] = VACANT;
    board->negDiagonal[negDiagonal] = VACANT;
    board->order[iR] = 0;
  }
  
  // If nothing in this row produces a solution, try changing the previous row
  // if we're allowed to (the goUp variable is 1)
  // If this is the first row, we're done
  if (goUp) {
    if (iR == 0)
      return 0;

    // Column of previous row
    int pC = base64_to_int(board->order[iR-1]);
    int pR = iR - 1;

    board->cols[pC] = VACANT;
    board->posDiagonal[(n - 1) - pR + pC] = VACANT;
    board->negDiagonal[pR + pC] = VACANT;
    board->order[pR] = 0;

    return nqueens_find_next(n, board, pR, pC + 1, 1);
  } else {
    return 0;
  }
}

parallel by wrks int count_helper(int n, chess_board* board, int r);
parallel by wrks int count_helper(int n, chess_board* board, int r) {
  while (r < n && board->order[r] != '\0')
    r++;

  if (r == n) {
    destroy_board(board);
    free(board);
    return 1;
  }

  int posDiagonalBase = (n - 1) - r;
  // TODO: I'd like to have a += inlet to use, but for now...
  int* cnts = calloc(n, sizeof(int));
  for (int c = 0; c < n; c++) {
    if (board->cols[c] == FILLED) continue;

    int posDiagonal = posDiagonalBase + c;
    int negDiagonal = r + c;

    if (board->posDiagonal[posDiagonal] == FILLED
        || board->negDiagonal[negDiagonal] == FILLED)
      continue;

    chess_board* new_board = malloc(sizeof(chess_board));
    if (new_board == NULL || initialize_board(n, new_board) != 1) exit(50);
    if (copy_board(board, new_board) != 1) exit(50);
    new_board->cols[c] = FILLED;
    new_board->posDiagonal[posDiagonal] = FILLED;
    new_board->negDiagonal[negDiagonal] = FILLED;
    new_board->order[r] = int_to_base64(c);

    spawn cnts[c] = count_helper(n, new_board, r+1);
  }
  sync;

  int cnt = 0;
  for (int i = 0; i < n; i++)
    cnt += cnts[i];
  free(cnts);

  destroy_board(board);
  free(board);
  return cnt;
}

parallel by wrks int count_nqueens(int n, char* init) {
  chess_board* board = malloc(sizeof(chess_board));
  if (board == NULL || initialize_board(n, board) != 1) exit(50);

  // If the initial configuration is invalid, there are 0 solutions
  if (construct_board(n, init, board) == 0) return 0;

  int res;
  spawn res = count_helper(n, board, 0);
  sync;

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

  if ((board->order = calloc(n, sizeof(char))) == NULL) {
    free(board->cols);
    free(board->posDiagonal);
    free(board->negDiagonal);
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

int load_board(const int n, char* str, chess_board* board) {
  if (board->n != n)
    return 0;

  memset(board->cols, 0, sizeof(char) * n);
  memset(board->posDiagonal, 0, sizeof(char) * (2 * n - 1));
  memset(board->negDiagonal, 0, sizeof(char) * (2 * n - 1));
  memset(board->order, 0, sizeof(char) * n);

  for (int r = 0; r < n; r++) {
    const int c = base64_to_int(str[r]);

    if (board->cols[c] == FILLED)
      return r;
    board->cols[c] = FILLED;

    int posDiagonal = (n - 1) - r + c;
    int negDiagonal = r + c;

    if (board->posDiagonal[posDiagonal] == FILLED
        || board->negDiagonal[negDiagonal] == FILLED)
      return r;
    board->posDiagonal[posDiagonal] = FILLED;
    board->negDiagonal[negDiagonal] = FILLED;

    board->order[r] = str[r];
  }

  return n;
}

int construct_board(const int n, char* str, chess_board* board) {
  if (board->n != n)
    return 0;

  memset(board->cols, 0, sizeof(char) * n);
  memset(board->posDiagonal, 0, sizeof(char) * (2 * n - 1));
  memset(board->negDiagonal, 0, sizeof(char) * (2 * n - 1));
  memset(board->order, 0, sizeof(char) * n);

  for (int r = 0; r < n; r++) {
    if (str[r] != ' ') {
      const int c = base64_to_int(str[r]);

      if (board->cols[c] == FILLED)
        return 0;
      board->cols[c] = FILLED;

      int posDiagonal = (n - 1) - r + c;
      int negDiagonal = r + c;

      if (board->posDiagonal[posDiagonal] == FILLED
          || board->negDiagonal[negDiagonal] == FILLED)
        return 0;
      board->posDiagonal[posDiagonal] = FILLED;
      board->negDiagonal[negDiagonal] = FILLED;

      board->order[r] = str[r];
    }
  }

  return 1;
}
