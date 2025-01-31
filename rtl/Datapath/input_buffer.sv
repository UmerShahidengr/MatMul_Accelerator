// Full Description of this file:
// This module, `input_buffer`, serves as a buffering mechanism for input data.
// It ensures proper sequencing and storage of incoming data using a set of FIFO buffers.
// The buffer instances store and propagate data while maintaining read and write control.
//
// The design consists of the following key elements:
// - A shift register (`o_valid`) that propagates read enable signals across `sys_rows` stages.
// - An instantiation of a `buffer` module to manage storage and retrieval of input data.
// - A generate loop that instantiates multiple buffer instances dynamically.
//
// Comments have been added after each line and above always blocks to help a second-hand user understand the code.


import Config::*;
module input_buffer (
    input logic rst,  // Active-high reset signal
    clk,  // Clock signal for synchronization
    read,  // Read enable signal
    input logic [sys_rows-1:0] wr_en,  // Write enable signals for each row
    input logic [sys_rows-1:0][A_BITWIDTH-1:0] i_data,  // Input data
    output logic [sys_rows-1:0] o_valid,  // Output valid signals
    output logic [sys_rows-1:0][A_BITWIDTH-1:0] o_data  // Output data
);
  
  int j;  // Loop variable for sequential logic
  
  // Assign read signal to first element of o_valid
  assign o_valid[0] = read;

  // Always block to propagate o_valid signals through a shift register-like mechanism
  always @(posedge (clk)) begin
    if (rst) 
      o_valid <= 0;  // Reset the valid signals to zero
    else begin
      for (j = 0; j < sys_rows - 1; j = j + 1) begin
        o_valid[j+1] <= o_valid[j];  // Shift the valid signal across rows
      end
    end
  end

  // Instantiate the first buffer instance
  buffer #(
      .filename(),  // Optional filename parameter
      .DEPTH(input_buffer_depth),  // Buffer depth defined by config
      .DWIDTH(A_BITWIDTH),  // Data width configuration
      .DUMP_LEN()  // Optional dump length parameter
  ) buffer_instance (
      .rstn(rst),  // Active-low reset
      .wr_clk(clk),  // Write clock
      .rd_clk(clk),  // Read clock
      .wr_en(wr_en[0]),  // Write enable for first buffer
      .rd_en(read),  // Read enable signal
      .din(i_data[0]),  // Input data
      .dout(o_data[0]),  // Output data
      .empty(),  // Empty status output
      .full()  // Full status output
  );

  // Generate multiple buffer instances for all rows
  genvar i;
  generate
    for (i = 1; i < sys_rows; i = i + 1) begin : FIFO  // Generate FIFO buffers per row
      buffer #(
          .filename(),  // Optional filename parameter
          .DEPTH(input_buffer_depth),  // Buffer depth
          .DWIDTH(A_BITWIDTH),  // Data width
          .DUMP_LEN()  // Optional dump length parameter
      ) buffer_instance (
          .rstn(rst),  // Active-low reset
          .wr_clk(clk),  // Write clock
          .rd_clk(clk),  // Read clock
          .wr_en(wr_en[i]),  // Write enable for this buffer instance
          .rd_en(o_valid[i]),  // Read enable signal from previous row
          .din(i_data[i]),  // Input data
          .dout(o_data[i]),  // Output data
          .empty(),  // Empty status output
          .full()  // Full status output
      );
    end
  endgenerate
endmodule
