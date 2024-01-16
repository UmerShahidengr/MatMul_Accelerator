`include "input_buffer.sv"

module tb_sysbuffer;
  logic rst, clk, start;
  logic [2:0] o_valid;

  logic [2:0][7:0] o_data;
  input_buffer DUT (
      .rst(rst),
      .clk(clk),
      .read(start),
      .o_valid(o_valid),
      .o_data(o_data)
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
    rst   = 1;
    start = 0;
    @(posedge clk);
    @(posedge clk);
    rst   = 0;
    start = 1;
    @(posedge clk);
    @(posedge clk);

    @(posedge clk);
    start = 0;
    @(posedge clk);
    repeat (15) @(posedge clk);
    $finish;
  end

  //Monitor values at posedge
  always @(posedge clk) begin
    $display("valid=%p data=%p", o_valid, o_data);
    $display("----------------------------------------------------------");
  end

  //Value change dump

  initial begin
    $dumpfile("tb_sysbuffer_dump.vcd");
    $dumpvars(1, DUT);
  end
endmodule
