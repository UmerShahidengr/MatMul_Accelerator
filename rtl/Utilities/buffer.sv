import Config::*;
module buffer #(
    parameter filename = "",
    parameter DEPTH = 8,
    parameter DWIDTH = 16,
    parameter DUMP_LEN = 3

) (
    input rstn,  //
    wr_clk,  //
    rd_clk,  //
    wr_en,  //
    rd_en,  //
    input [DWIDTH-1:0] din,  //
    output reg [DWIDTH-1:0] dout,  //
    output empty,  //
    full  //
);
  reg [$clog2(DEPTH)-1:0] wptr;
  reg [$clog2(DEPTH)-1:0] rptr;
  reg [DWIDTH-1 : 0] fifo[DEPTH];

  // initial begin
  //   fifo = '{default: '0};
  //   $readmemh(filename, fifo);
  //   wptr <= DUMP_LEN;
  //   rptr <= 0;
  // end

  always @(posedge wr_clk) begin
    if (rstn) begin
      wptr <= '0;
    end else begin
      if (wr_en & !full) begin
        fifo[wptr] <= din;
        wptr <= wptr + 1;
      end
    end
  end
  always @(posedge rd_clk) begin
    if (rstn) begin
      rptr <= 0;
    end else begin
      if (rd_en & !empty) begin
        rptr <= rptr + 1;
      end
      // else if (empty) dout <= 0;
    end
  end
  assign dout  = fifo[rptr];
  assign full  = (wptr + 1) == rptr;
  assign empty = wptr == rptr;
endmodule
