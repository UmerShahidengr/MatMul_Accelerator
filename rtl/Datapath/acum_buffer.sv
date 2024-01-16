import Config::*;
module acum_buffer (
    input logic clk,
    rst,
    rd_en,
    wr_en,
    mux_sel,
    input logic [P_BITWIDTH-1:0] i_data,
    output logic [P_BITWIDTH-1:0] o_data
);
  logic [P_BITWIDTH-1:0] dout;
  buffer #(
      .filename(),
      .DEPTH(16),
      .DWIDTH(P_BITWIDTH),
      .DUMP_LEN('b0)
  ) buffer_instance (
      .rstn(rst),
      .wr_clk(clk),
      .rd_clk(clk),
      .wr_en(wr_en),
      .rd_en(rd_en),
      .din(o_data),
      .dout(dout),
      .empty(),
      .full()
  );
  assign o_data = mux_sel == 0 ? dout + i_data : i_data;

endmodule

