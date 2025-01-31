//`include "buffer.sv"
import Config::*;

// Accumulator module: Collects and processes incoming data streams.
// The module manages data storage and retrieval, allowing sequential processing.
// It includes control logic for handling start, last, and enable signals.
module accumulator (
    input logic rst,    // Reset signal
    clk,                // Clock signal
    start,              // Start processing
    last,               // Last data element signal
    enable,             // Enable signal
    [sys_cols-1:0][P_BITWIDTH-1:0] i_data,  // Input data
    output logic [sys_cols-1:0] read_out,   // Read output control
    output logic [sys_cols-1:0][P_BITWIDTH-1:0] o_data, // Output data
    output logic done  // Completion flag
);
  // Internal control signals
  logic [sys_cols-1:0] rd_en, wr_en, mux_sel;
  int j;

  // Sequentially shifting control signals across columns
  always @(posedge (clk)) begin
    if (rst) begin 
      rd_en[sys_cols-1:1] <= '0;
      wr_en[sys_cols-1:1] <= '0;
      mux_sel[sys_cols-1:1] <= '0;
      read_out[sys_cols-1:1] <= '0;
    end else begin
      for (j = 0; j < sys_cols - 1; j = j + 1) begin
        rd_en[j+1] <= rd_en[j];
        wr_en[j+1] <= wr_en[j];
        mux_sel[j+1] <= mux_sel[j];
        read_out[j+1] <= read_out[j];
      end
    end
  end

  // Register to store previous enable state
  logic enable_q;
  always_ff @(posedge clk) begin
    if (rst) enable_q <= 0;
    else enable_q <= enable;
  end

  // Detect transition from enable=1 to enable=0 to set done signal
  assign done = (enable == 0 && enable_q == 1);

  // Combinational logic to control read, write, and selection signals
  always_comb begin
    if (enable_q == 0) begin
      rd_en[0] = 0;
      wr_en[0] = 0;
      mux_sel[0] = 1'bx;
      read_out[0] = 0;
    end else if (enable_q && ~start && ~last) begin
      rd_en[0] = 1;
      wr_en[0] = 1;
      mux_sel[0] = 1'b0;
      read_out[0] = 1'b0;
    end else if (enable_q && ~start && last) begin
      rd_en[0] = 1;
      wr_en[0] = 0;
      mux_sel[0] = 0;
      read_out[0] = 1;
    end else if (enable_q && start && ~last) begin
      rd_en[0] = 0;
      wr_en[0] = 1;
      mux_sel[0] = 1;
      read_out[0] = 0;
    end else if (enable_q && start && last) begin
      rd_en[0] = 1;
      wr_en[0] = 1;
      mux_sel[0] = 1;
      read_out[0] = 1;
    end
  end

  // Generate block to instantiate buffer elements for each column
  genvar i;
  generate
    for (i = 0; i < sys_cols; i = i + 1) begin 
      acum_buffer acum_buffer_instance(
        .clk(clk),
        .rst(rst),
        .rd_en(rd_en[i]),
        .wr_en(wr_en[i]),
        .mux_sel(mux_sel[i]),
        .i_data(i_data[i]),
        .o_data(o_data[i])
      );
    end
  endgenerate
endmodule
