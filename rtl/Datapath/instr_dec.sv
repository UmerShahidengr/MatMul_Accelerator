import Config::*;
module instr_dec (
    input  logic clk,
    rst,
    wr_en,
    rd_nxt_inst,
    input logic [INSTR_SIZE-1:0]instr,
    output logic start,
    last
);

logic [INSTR_SIZE-1:0]current_instr;
buffer #(
    .filename("instr.txt"),
    .DEPTH(IBUFF_SIZE),
    .DWIDTH(INSTR_SIZE),
    .DUMP_LEN(4)
) buffer_instance(
    .rstn(rst),
    .wr_clk(clk),
    .rd_clk(clk),
    .wr_en(wr_en),
    .rd_en(rd_nxt_inst),
    .din(instr),
    .dout(current_instr),
    .empty(),
    .full()
);
assign start=current_instr[0];
assign last=current_instr[1];
endmodule
