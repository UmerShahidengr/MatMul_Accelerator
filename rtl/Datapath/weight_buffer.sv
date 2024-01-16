//`include "buffer.sv"
import Config::*;
module weight_buffer (
    input logic rst,
    clk,
    input logic read,
    input logic [sys_cols-1:0] wr_en,
    input logic [sys_cols-1:0][W_BITWIDTH-1:0] i_data,
    output logic [sys_cols-1:0] o_valid,
    output logic [sys_cols-1:0][W_BITWIDTH-1:0] o_data
);
  // localparam string filenames[3] = {"file1.txt", "file2.txt", "file3.txt"};
  //parametrize it

  int j;
  assign o_valid[0] = read;
  always @(posedge (clk)) begin
    if (rst) o_valid <= 0;
    else begin
      for (j = 0; j < sys_cols - 1; j = j + 1) begin
        o_valid[j+1] <= o_valid[j];
      end
    end
  end

  buffer #(
      .filename(),
      .DEPTH(w_buffer_depth),
      .DWIDTH(W_BITWIDTH),
      .DUMP_LEN()
  ) buffer_instance (
      .rstn(rst),
      .wr_clk(clk),
      .rd_clk(clk),
      .wr_en(wr_en[0]),
      .rd_en(read),
      .din(i_data[0]),
      .dout(o_data[0]),
      .empty(),
      .full()
  );
  genvar i;
  generate
    for (i = 1; i < sys_cols; i = i + 1) begin : FIFO
      buffer #(
          .filename(),
          .DEPTH(w_buffer_depth),
          .DWIDTH(W_BITWIDTH),
          .DUMP_LEN(0)
      ) buffer_instance (
          .rstn(rst),
          .wr_clk(clk),
          .rd_clk(clk),
          .wr_en(wr_en[i]),
          .rd_en(o_valid[i]),
          .din(i_data[i]),
          .dout(o_data[i]),
          .empty(),
          .full()
      );
    end
  endgenerate
endmodule
