//`include "buffer.sv"
import Config::*;
module accumulator (
    input logic rst,
    clk,
    start,
    last,
    enable,
    [sys_cols-1:0][P_BITWIDTH-1:0] i_data,
    output logic [sys_cols-1:0] read_out,
    output logic [sys_cols-1:0][P_BITWIDTH-1:0] o_data,
    output logic done
);
  // localparam string filenames[3] = {"file1.txt", "file2.txt", "file3.txt"};
  //parametrize it
  logic [sys_cols-1:0] rd_en,wr_en,mux_sel;
  
  int j;
  always @(posedge (clk)) begin
    if (rst) begin rd_en[sys_cols-1:1] <= '0;
    wr_en[sys_cols-1:1] <= '0;
    mux_sel[sys_cols-1:1] <= '0;
    read_out[sys_cols-1:1] <= '0;
    end
    else begin
      for (j = 0; j < sys_cols - 1; j = j + 1) begin
        rd_en[j+1] <= rd_en[j];
        wr_en[j+1] <= wr_en[j];
        mux_sel[j+1] <= mux_sel[j];
        read_out[j+1] <= read_out[j];
      end
    end
  end

  //decoder
  logic enable_q;
  always_ff @( posedge clk ) begin
    if (rst) enable_q<=0;
    else enable_q<=enable;
  end

  assign done= enable==0 && enable_q==1;

  always_comb begin

    if(enable_q==0) begin
    rd_en[0]=0;
    wr_en[0]=0;
    mux_sel[0]=1'bx;
    read_out[0]=0;
    end
    else if(enable_q && ~start && ~last) begin
    rd_en[0]=1;
    wr_en[0]=1;
    mux_sel[0]=1'b0;
    read_out[0]=1'b0;
    end
    else if(enable_q && ~start && last) begin
    rd_en[0]=1;
    wr_en[0]=0;
    mux_sel[0]=0;
    read_out[0]=1;
    end
    else if(enable_q && start && ~last) begin
    rd_en[0]=0;
    wr_en[0]=1;
    mux_sel[0]=1;
    read_out[0]=0;
    end
    else if(enable_q && start && last) begin
    rd_en[0]=1;
    wr_en[0]=1;
    mux_sel[0]=1;
    read_out[0]=1;
    end
  end

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
