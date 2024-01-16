package Config;
  parameter int BIAS = 0;
  parameter A_BITWIDTH = 8;
  parameter W_BITWIDTH = 8;
  parameter P_BITWIDTH = 24;
  //systolic array configuration
  parameter int sys_rows = 50;
  parameter int sys_cols = 50;
  //

  //matrix A config
  parameter int A_rows = 50;
  parameter int A_cols = sys_rows;
  //matrix A config
  parameter int W_rows = sys_rows;
  parameter int W_cols = sys_cols;
  //Instruction Memory Size
  parameter int IBUFF_SIZE = 16;
  parameter int INSTR_SIZE = 2;
  //Buffer depths
  parameter int w_buffer_depth = sys_rows;
  parameter int input_buffer_depth = A_rows;
  parameter int Accumulator_depth = A_rows;
  //
  //These are original matrix sizes that we want to multiply and have to tile in case of bigger size,
  //not being used anywhere yet
  parameter int super_A_rows = 12;
  parameter int super_B_rows = 12;
  parameter int super_w_rows = 8;
  parameter int super_w_cols = 8;
  parameter int counter_width = get_counter_width();
  parameter int no_of_tiles = (super_w_rows / sys_rows) * (super_w_cols / sys_cols);
  parameter int weight_dump_length = no_of_tiles * sys_rows;
  parameter int actications_dump_length = no_of_tiles * super_A_rows;
  function automatic int get_counter_width();
    if (sys_rows > sys_cols) return $clog2(sys_rows);
    else return $clog2(sys_cols);
  endfunction

  typedef int Mat_result[A_rows][sys_cols];
  typedef int act_t[A_rows][sys_rows];
  typedef int weights_t[sys_rows][sys_cols];

  function Mat_result matMul(act_t A, weights_t B);
    int i;
    int j;
    int k;
    Mat_result result_matrix;
    for (i = 0; i < A_rows; i++) begin
      for (j = 0; j < sys_cols; j++) begin
        result_matrix[i][j] = 0;
        for (k = 0; k < sys_rows; k++) begin
          result_matrix[i][j] += A[i][k] * B[k][j];
        end
      end
    end
    return result_matrix;
  endfunction

  function weights_t generate_weights();
    weights_t matrix;
    for (int i = 0; i < sys_rows; i++) begin
      for (int j = 0; j < sys_cols; j++) begin
        matrix[i][j] = $urandom_range(0, 255);
      end
    end
    return matrix;
  endfunction

  function act_t generate_activations();
    act_t matrix;
    for (int i = 0; i < A_rows; i++) begin
      for (int j = 0; j < A_cols; j++) begin
        matrix[i][j] = $urandom_range(0, 255);
      end
    end
    return matrix;
  endfunction

endpackage : Config
