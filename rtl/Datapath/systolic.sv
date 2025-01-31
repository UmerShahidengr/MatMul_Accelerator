/*
 * Systolic Array Module Description:
 * This module implements a systolic array for matrix multiplication and accumulation.
 * Key features:
 * - 2D array of MAC (Multiply-Accumulate) units
 * - Supports pipelined computation with data flowing rightward and downward
 * - Configurable dimensions (sys_rows x sys_cols)
 * - Handles input feature (if_data), weight (i_wdata), and bias data
 * - Propagates control signals (switch, if_en, wfetch) through the array
 * - Outputs partial sums (of_data) for each column
 */

// Import configuration parameters
import Config::*;

module systolic (
    // Global control signals
    input logic clk,  // System clock
    input logic rst,  // Active-high reset
    // Control signals
    input logic switch,  // Switch signal for weight loading/computation
    input logic [sys_rows-1:0] if_en,  // Input feature enable for each row
    input logic [sys_cols-1:0] wfetch,  // Weight fetch enable for each column
    // Data inputs
    input logic [sys_rows-1:0][A_BITWIDTH-1:0] if_data,  // Input feature data
    input logic [sys_cols-1:0][A_BITWIDTH-1:0] i_wdata,  // Input weight data
    input logic [P_BITWIDTH-1:0] bias,  // Bias value
    // Data outputs
    output logic [sys_cols-1:0][P_BITWIDTH-1:0] of_data  // Output feature data
);

  // Internal signals for data and control propagation
  logic [sys_rows-1:0][sys_cols-2:0][A_BITWIDTH-1:0] A_data;  // Propagated input feature data
  logic [sys_rows-1:0][sys_cols-2:0]                 A_ready; // Input feature ready signals
  logic [sys_rows-1:0][sys_cols-1:0]                 W_switch; // Weight switch signals
  logic [sys_rows-2:0][sys_cols-1:0][W_BITWIDTH-1:0] W_data;  // Propagated weight data
  logic [sys_rows-2:0][sys_cols-1:0]                 W_ready; // Weight ready signals
  logic [sys_rows-2:0][sys_cols-1:0][P_BITWIDTH-1:0] P_data;  // Partial sum data

  //----------------------------------------------------------
  // Switch Signal Propagation Always Block
  // Propagates the switch signal downward through the array
  // - W_switch[1][0] is driven by the input switch signal
  // - Each subsequent row's switch signal is delayed by one cycle
  //----------------------------------------------------------
  always_ff @(posedge clk) begin
    W_switch[1][0] <= switch;  // First row switch signal
    for (int i = 1; i < sys_rows - 1; i = i + 1) begin
      W_switch[i+1][0] <= W_switch[i][0];  // Propagate switch signal downward
    end
  end

  //----------------------------------------------------------
  // MAC Unit Instantiation
  // Generates a 2D array of MAC units using nested generate blocks
  // - Handles boundary conditions for first/last rows and columns
  // - Propagates data and control signals through the array
  //----------------------------------------------------------
  genvar i, j;
  generate
    for (i = 0; i < sys_rows; i++) begin : ROW
      for (j = 0; j < sys_cols; j++) begin : COL
        // First row, first column (top-left corner)
        if (i == 0 && j == 0) begin
          mac mac_instance (
              .clk(clk),
              .rst(rst),
              .switch_in(switch),  // Input switch signal
              .switch_out(W_switch[i][j+1]),  // Propagate switch right
              .A_en(if_en[i]),  // Input feature enable
              .A_ready(A_ready[i][j]),  // Output feature ready
              .A_in(if_data[i]),  // Input feature data
              .A_out(A_data[i][j]),  // Propagated feature data
              .W_en(wfetch[j]),  // Weight fetch enable
              .W_ready(W_ready[i][j]),  // Weight ready signal
              .W_in(i_wdata[j]),  // Input weight data
              .W_out(W_data[i][j]),  // Propagated weight data
              .P_in(bias),  // Bias input
              .P_out(P_data[i][j])  // Partial sum output
          );
        end
        // First row, last column (top-right corner)
        else if (i == 0 && j == sys_cols - 1) begin
          mac mac_instance (
              .clk(clk),
              .rst(rst),
              .switch_in(W_switch[i][j]),  // Switch from left
              .switch_out(),  // No propagation (end of row)
              .A_en(A_ready[i][j-1]),  // Feature ready from left
              .A_ready(),  // No propagation (end of row)
              .A_in(A_data[i][j-1]),  // Feature data from left
              .A_out(),  // No propagation (end of row)
              .W_en(wfetch[j]),  // Weight fetch enable
              .W_ready(W_ready[i][j]),  // Weight ready signal
              .W_in(i_wdata[j]),  // Input weight data
              .W_out(W_data[i][j]),  // Propagated weight data
              .P_in(bias),  // Bias input
              .P_out(P_data[i][j])  // Partial sum output
          );
        end
        // First row, middle columns
        else if (i == 0) begin
          mac mac_instance (
              .clk(clk),
              .rst(rst),
              .switch_in(W_switch[i][j]),  // Switch from left
              .switch_out(W_switch[i][j+1]),  // Propagate switch right
              .A_en(A_ready[i][j-1]),  // Feature ready from left
              .A_ready(A_ready[i][j]),  // Propagate feature ready right
              .A_in(A_data[i][j-1]),  // Feature data from left
              .A_out(A_data[i][j]),  // Propagate feature data right
              .W_en(wfetch[j]),  // Weight fetch enable
              .W_ready(W_ready[i][j]),  // Weight ready signal
              .W_in(i_wdata[j]),  // Input weight data
              .W_out(W_data[i][j]),  // Propagated weight data
              .P_in(bias),  // Bias input
              .P_out(P_data[i][j])  // Partial sum output
          );
        end
        // Last row, first column (bottom-left corner)
        if (i == sys_rows - 1 && j == 0) begin
          mac mac_instance (
              .clk(clk),
              .rst(rst),
              .switch_in(W_switch[i][j]),  // Switch from above
              .switch_out(W_switch[i][j+1]),  // Propagate switch right
              .A_en(if_en[i]),  // Input feature enable
              .A_ready(A_ready[i][j]),  // Output feature ready
              .A_in(if_data[i]),  // Input feature data
              .A_out(A_data[i][j]),  // Propagate feature data right
              .W_en(W_ready[i-1][j] & wfetch[j]),  // Weight enable from above
              .W_ready(),  // No propagation (last row)
              .W_in(W_data[i-1][j]),  // Weight data from above
              .W_out(),  // No propagation (last row)
              .P_in(P_data[i-1][j]),  // Partial sum from above
              .P_out(of_data[j])  // Final output for column
          );
        end
        // Last row, last column (bottom-right corner)
        else if (i == sys_rows - 1 && j == sys_cols - 1) begin
          mac mac_instance (
              .clk(clk),
              .rst(rst),
              .switch_in(W_switch[i][j]),  // Switch from left
              .switch_out(),  // No propagation (end of row)
              .A_en(A_ready[i][j-1]),  // Feature ready from left
              .A_ready(),  // No propagation (end of row)
              .A_in(A_data[i][j-1]),  // Feature data from left
              .A_out(),  // No propagation (end of row)
              .W_en(W_ready[i-1][j] & wfetch[j]),  // Weight enable from above
              .W_ready(),  // No propagation (last row)
              .W_in(W_data[i-1][j]),  // Weight data from above
              .W_out(),  // No propagation (last row)
              .P_in(P_data[i-1][j]),  // Partial sum from above
              .P_out(of_data[j])  // Final output for column
          );
        end
        // Last row, middle columns
        else if (i == sys_rows - 1) begin
          mac mac_instance (
              .clk(clk),
              .rst(rst),
              .switch_in(W_switch[i][j]),  // Switch from left
              .switch_out(W_switch[i][j+1]),  // Propagate switch right
              .A_en(A_ready[i][j-1]),  // Feature ready from left
              .A_ready(A_ready[i][j]),  // Propagate feature ready right
              .A_in(A_data[i][j-1]),  // Feature data from left
              .A_out(A_data[i][j]),  // Propagate feature data right
              .W_en(W_ready[i-1][j] & wfetch[j]),  // Weight enable from above
              .W_ready(),  // No propagation (last row)
              .W_in(W_data[i-1][j]),  // Weight data from above
              .W_out(),  // No propagation (last row)
              .P_in(P_data[i-1][j]),  // Partial sum from above
              .P_out(of_data[j])  // Final output for column
          );
        end
        // Middle rows, first column
        else if (i != sys_rows - 1 && i != 0 && j == 0) begin
          mac mac_instance (
              .clk(clk),
              .rst(rst),
              .switch_in(W_switch[i][j]),  // Switch from above
              .switch_out(W_switch[i][j+1]),  // Propagate switch right
              .A_en(if_en[i]),  // Input feature enable
              .A_ready(A_ready[i][j]),  // Output feature ready
              .A_in(if_data[i]),  // Input feature data
              .A_out(A_data[i][j]),  // Propagate feature data right
              .W_en(W_ready[i-1][j] & wfetch[j]),  // Weight enable from above
              .W_ready(W_ready[i][j]),  // Propagate weight ready downward
              .W_in(W_data[i-1][j]),  // Weight data from above
              .W_out(W_data[i][j]),  // Propagate weight data downward
              .P_in(P_data[i-1][j]),  // Partial sum from above
              .P_out(P_data[i][j])  // Propagate partial sum downward
          );
        end
        // Middle rows, last column
        else if (i != sys_rows - 1 && i != 0 && j == sys_cols - 1) begin
          mac mac_instance (
              .clk(clk),
              .rst(rst),
              .switch_in(W_switch[i][j]),  // Switch from left
              .switch_out(),  // No propagation (end of row)
              .A_en(A_ready[i][j-1]),  // Feature ready from left
              .A_ready(),  // No propagation (end of row)
              .A_in(A_data[i][j-1]),  // Feature data from left
              .A_out(),  // No propagation (end of row)
              .W_en(W_ready[i-1][j] & wfetch[j]),  // Weight enable from above
              .W_ready(W_ready[i][j]),  // Propagate weight ready downward
              .W_in(W_data[i-1][j]),  // Weight data from above
              .W_out(W_data[i][j]),  // Propagate weight data downward
              .P_in(P_data[i-1][j]),  // Partial sum from above
              .P_out(P_data[i][j])  // Propagate partial sum downward
          );
        end
        // Middle rows, middle columns
        else if (i != sys_rows - 1 && i != 0 && j != 0 && j != sys_cols - 1) begin
          mac mac_instance (
              .clk(clk),
              .rst(rst),
              .switch_in(W_switch[i][j]),  // Switch from left
              .switch_out(W_switch[i][j+1]),  // Propagate switch right
              .A_en(A_ready[i][j-1]),  // Feature ready from left
              .A_ready(A_ready[i][j]),  // Propagate feature ready right
              .A_in(A_data[i][j-1]),  // Feature data from left
              .A_out(A_data[i][j]),  // Propagate feature data right
              .W_en(W_ready[i-1][j] & wfetch[j]),  // Weight enable from above
              .W_ready(W_ready[i][j]),  // Propagate weight ready downward
              .W_in(W_data[i-1][j]),  // Weight data from above
              .W_out(W_data[i][j]),  // Propagate weight data downward
              .P_in(P_data[i-1][j]),  // Partial sum from above
              .P_out(P_data[i][j])  // Propagate partial sum downward
          );
        end
      end
    end
  endgenerate
endmodule