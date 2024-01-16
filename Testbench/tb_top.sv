//`include "top.sv"
import Config::*;
module tb_top;
  logic clk, rst, start, ready;
  logic [sys_cols-1:0][P_BITWIDTH-1:0] result;
  logic [sys_cols-1:0] read_out;
  // logic [sys_cols-1:0][W_BITWIDTH-1:0] o_data;
  logic [sys_cols-1:0] w_valid;
  logic [sys_cols-1:0][W_BITWIDTH-1:0] wdata;
  logic [sys_cols-1:0] if_valid;
  logic [sys_cols-1:0][W_BITWIDTH-1:0] if_data;
  logic instr_valid;
  logic [INSTR_SIZE-1:0] instr;
  top dut (
      .clk(clk),
      .rst(rst),
      .start(start),
      .w_valid(w_valid),
      .wdata(wdata),
      .if_valid(if_valid),
      .if_data(if_data),
      .instr_valid(instr_valid),
      .instr(instr),
      .ready(ready),
      .read_out(read_out),
      .o_data(result)
  );

  logic [sys_rows-2:0][sys_cols-1:0][W_BITWIDTH-1:0] W_data;

  assign W_data = dut.datapath_instance.sys_instance.W_data;

  Mat_result golden_model;
  act_t activations;
  weights_t weights;
  int counter[sys_cols];
  int j;
  /////////////////////////////////////////////Unit Testing/////////////////////////////////////////////
  initial begin
    rst   <= 1;
    start <= 0;
    @(posedge clk);
    rst <= 0;
    @(posedge clk);
    for (int test_no = 0; test_no < 20; test_no++) begin
      activations = generate_activations;
      weights = generate_weights;
      golden_model = matMul(activations, weights);
      counter = '{default: 0};
      //////////////////////////////////////////send weights///////////////////////////////////////////////
      for (int i = sys_rows - 1; i >= 0; i--) begin
        for (int j = 0; j < sys_cols; j++) begin
          wdata[j] <= weights[i][j];
        end
        w_valid <= '{default: 1'b1};
        @(posedge clk);
      end
      w_valid <= '{default: 1'b0};
      @(posedge clk);
      /////////////////////////////////////////send activations////////////////////////////////////////////////
      for (int i = 0; i < A_rows; i++) begin
        for (int j = 0; j < A_cols; j++) begin
          if_data[j] <= activations[i][j];
        end
        if_valid <= '{default: 1'b1};
        @(posedge clk);
      end
      if_valid <= '{default: 1'b0};
      @(posedge clk);
      /////////////////////////////////////Instruction send//////////////////////////////////////////
      instr_valid <= 1'b1;
      instr <= 2'b11;
      @(posedge clk);
      ////////////////////Start for one instr/////////////////////////////////////
      instr_valid <= 1'b0;
      start <= 1;
      @(posedge clk);
      start <= 0;
      while (counter[sys_cols-1] < A_rows) begin
        @(posedge clk);
        //check each coloumn output equality
        for (j = 0; j < sys_cols; j = j + 1) begin
          if (read_out[j]) begin
            if (golden_model[counter[j]][j] != result[j]) begin
              $display("Test Failed");
              $display("golden=%d", golden_model[counter[j]][j]);
              $display("counter=%p,j=%d", counter, j);
              $display("actual=%d", result[j]);
              $fatal(1);
            end
            counter[j] = counter[j] + 1;
          end
        end
      end
      $display("---------------------Test%dPassed-------------------", test_no);
    end
    $finish;
  end

  /////////////////////////////////////////////clock generation/////////////////////////////////////////////
  localparam CLK_PERIOD = 10;
  initial begin
    clk = 0;
    forever begin
      #(CLK_PERIOD / 2);
      clk = ~clk;
    end
  end

  /////////////////////////////////////////////////Testbench/////////////////////////////////////////////

  // int i;
  // initial begin
  //   rst   <= 1;
  //   start <= 0;
  //   @(posedge clk);
  //   rst <= 0;
  //   //send weights
  //   for (int i = sys_rows - 1; i >= 0; i--) begin
  //     for (int j = 0; j < sys_cols; j++) begin
  //       wdata[j] <= weights[i][j];
  //     end
  //     w_valid <= '{default: 1'b1};
  //     @(posedge clk);
  //   end
  //   w_valid <= '{default: 1'b0};
  //   @(posedge clk)
  //   //send activations
  //   for (
  //       int i = 0; i < A_rows; i++
  //   ) begin
  //     for (int j = 0; j < A_cols; j++) begin
  //       if_data[j] <= activations[i][j];
  //     end
  //     if_valid <= '{default: 1'b1};
  //     @(posedge clk);
  //   end
  //   if_valid <= '{default: 1'b0};
  //   @(posedge clk);
  //   //Instruction send
  //   instr_valid <= 1'b1;
  //   instr <= 2'b11;
  //   @(posedge clk);
  //   //Start
  //   instr_valid <= 1'b0;
  //   start <= 1;
  //   @(posedge clk);
  //   start <= 0;
  //   repeat (50) @(posedge clk);
  //   @(posedge ready);
  //   $finish;
  // end

  //Monitor values at posedge
  // always @(posedge clk) begin
  //   for (i = 0; i < 5; i = i + 1) $display(" %d %d %d", W_data[i][0], W_data[i][1], W_data[i][2]);
  //   $display("----------------------------------------------------------");
  // end
  ////////////////////////////////////////////////Value change dump///////////////////////////////////////////
  initial begin
    $dumpfile("tb_top_dump.vcd");
    $dumpvars(1, dut);
  end
endmodule
