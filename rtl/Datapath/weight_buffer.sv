/*
 * Weight Buffer Module Description:
 * This module implements a multi-column weight buffer for systolic array processing.
 * Key features:
 * - Manages weight data for multiple columns (sys_cols)
 * - Uses parameterized FIFO buffers for each column
 * - Propagates read valid signals across columns
 * - Supports synchronous reset and clocking
 * - Configurable buffer depth and data width
 */

// Import configuration parameters
import Config::*;

module weight_buffer (
    // Global control signals
    input logic rst,  // Active-high reset
    input logic clk,  // System clock
    // Read control
    input logic read, // Read enable signal
    // Write control
    input logic [sys_cols-1:0] wr_en,  // Per-column write enable
    // Data interface
    input logic [sys_cols-1:0][W_BITWIDTH-1:0] i_data,  // Input weight data
    // Output interface
    output logic [sys_cols-1:0] o_valid,  // Per-column output valid
    output logic [sys_cols-1:0][W_BITWIDTH-1:0] o_data  // Output weight data
);

  // Internal loop variable
  int j;

  //----------------------------------------------------------
  // Read Valid Signal Propagation
  // Propagates the read signal across columns with a one-cycle delay per column
  // - o_valid[0] is directly driven by the read signal
  // - Subsequent o_valid signals are delayed versions of the previous column's valid
  //----------------------------------------------------------
  assign o_valid[0] = read;  // First column valid is directly driven by read

  always @(posedge clk) begin
    if (rst) begin
      o_valid <= 0;  // Reset all valid signals
    end else begin
      // Propagate valid signal across columns
      for (j = 0; j < sys_cols - 1; j = j + 1) begin
        o_valid[j+1] <= o_valid[j];  // Delay valid signal by one cycle per column
      end
    end
  end

  //----------------------------------------------------------
  // Column 0 Buffer Instance
  // First column buffer with direct read control
  //----------------------------------------------------------
  buffer #(
      .filename(),  // No file initialization
      .DEPTH(w_buffer_depth),  // Buffer depth from Config
      .DWIDTH(W_BITWIDTH),     // Data width from Config
      .DUMP_LEN()              // No debug dump
  ) buffer_instance (
      .rstn(rst),      // Active-low reset
      .wr_clk(clk),    // Write clock
      .rd_clk(clk),    // Read clock
      .wr_en(wr_en[0]),  // Write enable for column 0
      .rd_en(read),    // Read enable for column 0
      .din(i_data[0]), // Input data for column 0
      .dout(o_data[0]),  // Output data for column 0
      .empty(),        // Unused empty flag
      .full()          // Unused full flag
  );

  //----------------------------------------------------------
  // Generate Block for Additional Columns
  // Instantiates buffers for columns 1 to sys_cols-1
  // - Uses propagated valid signals for read control
  // - Each column has its own write enable and data interface
  //----------------------------------------------------------
  genvar i;
  generate
    for (i = 1; i < sys_cols; i = i + 1) begin : FIFO
      buffer #(
          .filename(),  // No file initialization
          .DEPTH(w_buffer_depth),  // Buffer depth from Config
          .DWIDTH(W_BITWIDTH),     // Data width from Config
          .DUMP_LEN(0)             // No debug dump
      ) buffer_instance (
          .rstn(rst),        // Active-low reset
          .wr_clk(clk),      // Write clock
          .rd_clk(clk),      // Read clock
          .wr_en(wr_en[i]),  // Write enable for column i
          .rd_en(o_valid[i]),  // Read enable from propagated valid
          .din(i_data[i]),   // Input data for column i
          .dout(o_data[i]),  // Output data for column i
          .empty(),          // Unused empty flag
          .full()            // Unused full flag
      );
    end
  endgenerate

endmodule