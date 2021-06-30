#ifndef INCLUDE_NQUEENS_H_
#define INCLUDE_NQUEENS_H_

#include <stdlib.h>
#include <string.h>
#include "base64.h"

#define VACANT 0
#define FILLED 1

/*
 * Considering the case of 4 x 4, the following diagram labels each row
 * 3 3 3 3
 * 2 2 2 2
 * 1 1 1 1
 * 0 0 0 0
 *
 * This diagram labels each column
 * 0 1 2 3
 * 0 1 2 3
 * 0 1 2 3
 * 0 1 2 3
 *
 * This diagram labels the pos(itive) diagonals
 * 0 1 2 3
 * 1 2 3 4
 * 2 3 4 5
 * 3 4 5 6
 *
 * This diagram labels the neg(ative) diagonals
 * 3 4 5 6
 * 2 3 4 5
 * 1 2 3 4
 * 0 1 2 3
 *
 * To calculate the positive diagonal, compute: (N-1) + c - r
 * To calculate the negative diagonal, compute: r + c
 */
typedef struct {
  int n;
  char* cols;
  char* posDiagonal;
  char* negDiagonal;
  char* order;
} chess_board;

// returns 1 on success or 0 if an error occured
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

// frees any memory allocated for the board
void destroy_board(chess_board* board) {
  free(board->cols);
  free(board->posDiagonal);
  free(board->negDiagonal);
  free(board->order);

  board->n = 0;
  board->cols = NULL;
  board->posDiagonal = NULL;
  board->negDiagonal = NULL;
  board->order = NULL;
}

// returns 0 if there's an error, otherwise performs the copy and returns 1
int copy_board(chess_board* src, chess_board* dst) {
  if (src == dst)
    return 1;

  if (src->n != dst->n)
    return 0;

  const int n = src->n;

  memcpy(dst->cols, src->cols, sizeof(char) * n);
  memcpy(dst->posDiagonal, src->posDiagonal, sizeof(char) * (2 * n - 1));
  memcpy(dst->negDiagonal, src->negDiagonal, sizeof(char) * (2 * n - 1));
  memcpy(dst->order, src->order, sizeof(char) * n);

  return 1;
}

// Attempts to create the board specified by the string (which is assumed to
// be an n-digit number in base-n). Loads starting at row 0 until it cannot
// place a further queen, due to a conflict. Returns the number of queens
// placed onto the board or 0 if an error occurs (in which case the state
// of the board is undefined)
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

// Attempts to create the board specified by the string (which is assumed to
// be an n-digit number in base-n where spaces are allowed in place of a
// character to represent that no queen is placed in that row). Returns 1 if
// the positions specified in the string are valid and 0 otherwise (in which
// case the state of the board is undefined)
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

#endif // INCLUDE_NQUEENS_H_
