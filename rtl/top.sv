//`include "datapath.sv"
//`include "controller.sv"

import Config::*;
module top (
    input clk,
    input rst,
    start,
    input logic [sys_cols-1:0] w_valid,
    input logic [sys_cols-1:0][W_BITWIDTH-1:0] wdata,
    input logic [sys_cols-1:0] if_valid,
    input logic [sys_cols-1:0][W_BITWIDTH-1:0] if_data,
    input logic instr_valid,
    input logic [INSTR_SIZE-1:0] instr,
    output logic ready,
    logic [sys_cols-1:0] read_out,
    logic [sys_cols-1:0][P_BITWIDTH-1:0] o_data
);
  logic w_read, if_read, w_done, if_done;
  logic clr_w, clr_if, switch, rd_nxt_inst, first, last;
  controller controller_instance (
      .clk(clk),
      .rst(rst),
      .start(start),
      .w_done(w_done),
      .if_done(if_done),
      .rd_nxt_inst(rd_nxt_inst),
      .instr_valid(instr_valid),
      .instr(instr),
      .w_read(w_read),
      .if_read(if_read),
      .clr_w(clr_w),
      .clr_if(clr_if),
      .switch(switch),
      .ready(ready),
      .first(first),
      .last(last)
  );

  datapath datapath_instance (
      .clk(clk),
      .rst(rst),
      .w_buffer_read(w_read),
      .if_buffer_read(if_read),
      .clr_w(clr_w),
      .clr_if(clr_if),
      .switch(switch),
      .first(first),
      .last(last),
      .w_valid(w_valid),
      .wdata(wdata),
      .if_valid(if_valid),
      .if_data(if_data),
      .w_done(w_done),
      .if_done(if_done),
      .rd_nxt_inst(rd_nxt_inst),
      .read_out(read_out),
      .o_data(o_data)
  );


endmodule : top
