#ifndef NQUEENS_HEADER_
#define NQUEENS_HEADER_

#include <stdlib.h>
#include <string.h>

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
  // we don't track rows, since our algorithm will increase the row monotonically
  char* cols;
  char* posDiagonal;
  char* negDiagonal;
} chess_board;

// returns 1 on success or 0 if an error occured
int initialize_board(int n, chess_board* board);

// frees any memory allocated for the board
void destroy_board(chess_board* board);

// returns 0 if there's an error, otherwise performs the copy and returns 1
int copy_board(chess_board* src, chess_board* dst);

#endif // NQUEENS_HEADER_
