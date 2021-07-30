#ifndef INCLUDE_NQUEENS_H_
#define INCLUDE_NQUEENS_H_

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
  char* order; // Expected to encode as length n base-n integer (non-null terminated)
} chess_board;

// returns 1 on success or 0 if an error occured
int initialize_board(int n, chess_board* board);

// frees any memory allocated for the board
void destroy_board(chess_board* board);

// returns 0 if there's an error, otherwise performs the copy and returns 1
int copy_board(chess_board* src, chess_board* dst);

// Attempts to create the board specified by the string (which is assumed to
// be an n-digit number in base-n). Loads starting at row 0 until it cannot
// place a further queen, due to a conflict. Returns the number of queens
// placed onto the board or 0 if an error occurs (in which case the state
// of the board is undefined)
int load_board(const int n, char* str, chess_board* board);

// Attempts to create the board specified by the string (which is assumed to
// be an n-digit number in base-n where spaces are allowed in place of a
// character to represent that no queen is placed in that row). Returns 1 if
// the positions specified in the string are valid and 0 otherwise (in which
// case the state of the board is undefined)
int construct_board(const int n, char* str, chess_board* board);

#endif
