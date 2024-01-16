//`include "systolic.sv"
//`include "input_buffer.sv"
//`include "weight_buffer.sv"
//`include "accumulator.sv"
import Config::*;
module datapath (
    input logic clk,
    rst,
    w_buffer_read,
    if_buffer_read,
    clr_w,
    clr_if,
    switch,
    first,
    last,
    input logic [sys_cols-1:0] w_valid,
    input logic [sys_cols-1:0][W_BITWIDTH-1:0] wdata,
    input logic [sys_cols-1:0] if_valid,
    input logic [sys_cols-1:0][W_BITWIDTH-1:0] if_data,
    output logic w_done,
    if_done,
    rd_nxt_inst,
    logic [sys_cols-1:0] read_out,
    logic [sys_cols-1:0][P_BITWIDTH-1:0] o_data
);
  logic [sys_cols-1:0][P_BITWIDTH-1:0] of_data;
  logic [sys_rows-1:0] if_en;
  logic [sys_rows-1:0][A_BITWIDTH-1:0] i_sys_ifdata;
  logic [sys_cols-1:0][W_BITWIDTH-1:0] i_sys_wdata;
  logic [sys_cols-1:0] wfetch;
  logic [$clog2(sys_rows+1)-1:0] count_w;
  logic [$clog2(A_rows+1)-1:0] count_if;
  assign w_done  = count_w == sys_rows;
  assign if_done = count_if == A_rows;
  always_ff @(posedge clk) begin
    if (clr_w) count_w <= 0;
    else count_w <= count_w + 1;
  end
  always_ff @(posedge clk) begin
    if (clr_if) count_if <= 0;
    else count_if <= count_if + 1;
  end


  weight_buffer weight_buffer_instance (
      .rst(rst),
      .clk(clk),
      .read(w_buffer_read),
      .wr_en(w_valid),
      .i_data(wdata),
      .o_valid(wfetch),
      .o_data(i_sys_wdata)
  );

  input_buffer input_buffer_instance (
      .rst(rst),
      .clk(clk),
      .read(if_buffer_read),
      .wr_en(if_valid),
      .i_data(if_data),
      .o_valid(if_en),
      .o_data(i_sys_ifdata)
  );

  systolic sys_instance (
      .clk(clk),
      .rst(rst),
      .switch(switch),
      .if_en(if_en),
      .wfetch(wfetch),
      .if_data(i_sys_ifdata),
      .i_wdata(i_sys_wdata),
      .bias(BIAS),
      .of_data(of_data)
  );

  accumulator accumulator_instance (
      .rst(rst),
      .clk(clk),
      .start(first),
      .last(last),
      .enable(if_en[sys_rows-1]),
      .i_data(of_data),
      .read_out(read_out),
      .o_data(o_data),
      .done(rd_nxt_inst)
      // .o_accum(o_accum)
  );

endmodule
