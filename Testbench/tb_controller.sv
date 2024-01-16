`include "controller.sv"

module tb_controller;
  logic clk, rst, start, w_done, if_done;
  logic w_read, if_read, clr_w, clr_if, switch, ready;
  controller DUT (
      .clk(clk),
      .rst(rst),
      .start(start),
      .w_done(w_done),
      .if_done(if_done),
      .w_read(w_read),
      .if_read(if_read),
      .clr_w(clr_w),
      .clr_if(clr_if),
      .switch(switch),
      .ready(ready)
  );

  //clock generation
  localparam CLK_PERIOD = 10;
  initial begin
    clk = 0;
    forever begin
      #(CLK_PERIOD / 2);
      clk = ~clk;
    end
  end
  //Testbench

  initial begin
    rst = 1;
    start = 0;
    w_done = 0;
    if_done = 0;
    @(posedge clk);
    // @(posedge clk);
    rst   = 0;
    start = 1;

    repeat (6) @(posedge clk);
    start  = 1;
    w_done = 1;
    //
    repeat (1) @(posedge clk);
    w_done = 0;
    repeat (6) @(posedge clk);
    if_done = 1;
    repeat (1) @(posedge clk);
    rst = 1;
    start = 0;
    w_done = 0;
    if_done = 0;
    $finish;
  end

  //Monitor values at posedge
  always @(posedge clk) begin
    $display(" ");
    $display("----------------------------------------------------------");
  end

  //Value change dump

  initial begin
    $dumpfile("tb_controller_dump.vcd");
    $dumpvars(0, DUT);
  end
endmodule
