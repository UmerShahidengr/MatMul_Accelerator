#include <stdio.h>

#define ROWS 3
#define COLS 3
static int matrix[ROWS][COLS];
int main()
{

    // Assigning values to the matrix for better visualization
    int value = 1;
    for (int i = 0; i < ROWS; i++)
    {
        for (int j = 0; j < COLS; j++)
        {
            matrix[i][j] = value++;
        }
    }

    // Printing the addresses of all elements in the matrix
    printf("Addresses of elements in the matrix:\n");
    for (int i = 0; i < ROWS; i++)
    {
        for (int j = 0; j < COLS; j++)
        {
            printf("Address of matrix[%d][%d]: %p\n", i, j, (void *)&matrix[i][j]);
        }
    }

    return 0;
}
