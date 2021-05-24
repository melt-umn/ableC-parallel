#include <stdlib.h>
#include <string.h>

#include "base64.h"
#include "nqueens.h"

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
  free(board->order);

  board->n = 0;
  board->cols = NULL;
  board->posDiagonal = NULL;
  board->negDiagonal = NULL;
  board->order = NULL;
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
  memcpy(dst->order, src->order, sizeof(char) * n);

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
