import numpy as np

# Creating a 4x3 array of integers
A = np.array([[9, 8, 7, 6],
              [5, 4, 3, 2],
              [1, 9, 8, 7]])
B = np.array([[1, 2, 3, 2],
              [4, 5, 6, 3],
              [7, 8, 9, 6],
              [1, 2, 3, 1]])

# Define system dimensions
sys_rows = 2
sys_cols = 2

# Get dimensions of matrices A and B
A_rows, A_cols = A.shape
B_rows, B_cols = B.shape
C=None
for i in range(0, A_cols, sys_cols):  # Iterate over B columns
    for j in range(0, B_rows, sys_rows):  # Iterate over A and B rows
        tile_A = A[:, j:min(j + sys_rows, A_cols)]
        tile_B = B[j:min(j + sys_rows, B_rows), i:min(i + sys_cols, B_cols)]
        print("A_tile= ",tile_A)
        print("B_tile= ",tile_B)
        if(C is None):
            C=np.dot(tile_A,tile_B)
        else:
            C+=np.dot(tile_A,tile_B)
        print("C=",np.dot(tile_A,tile_B))
        # Write columns of tile_A to separate files
        for col in range(tile_A.shape[1]):
            with open(f"activations_{col+1}.txt", 'w' if i==0 and j == 0 else 'a') as file_A:
                np.savetxt(file_A, tile_A[:, col], fmt='%d', newline="\n")
        
        # Invert the columns of tile_B and write to separate files
        for col in range(tile_B.shape[1]):
            inverted_col = np.flip(tile_B[:, col])  # Invert column using np.flip
            with open(f"w{col+1}.txt", 'w' if i==0 and j == 0 else 'a') as file_B:
                np.savetxt(file_B, inverted_col, fmt='%d', newline="\n")
print("answer=",np.dot(A,B))