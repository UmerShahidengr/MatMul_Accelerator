// `include "mac.sv"
import Config::*;
module systolic (
    input logic clk,
    rst,
    switch,
    input logic [sys_rows-1:0] if_en,
    input logic [sys_cols-1:0] wfetch,
    input logic [sys_rows-1:0][A_BITWIDTH-1:0] if_data,
    input logic [sys_cols-1:0][A_BITWIDTH-1:0] i_wdata,
    input logic [P_BITWIDTH-1:0] bias,
    output logic [sys_cols-1:0][P_BITWIDTH-1:0] of_data
);
  /////////////////////////////////////////////////////////////////////
  logic [sys_rows-1:0][sys_cols-2:0][A_BITWIDTH-1:0] A_data;
  logic [sys_rows-1:0][sys_cols-2:0]                 A_ready;
  logic [sys_rows-1:0][sys_cols-1:0]                 W_switch;
  logic [sys_rows-2:0][sys_cols-1:0][W_BITWIDTH-1:0] W_data;
  logic [sys_rows-2:0][sys_cols-1:0]                 W_ready;
  logic [sys_rows-2:0][sys_cols-1:0][P_BITWIDTH-1:0] P_data;


  always_ff @(posedge clk) begin
    W_switch[1][0] <= switch;
    for (int i = 1; i < sys_rows - 1; i = i + 1) begin
      W_switch[i+1][0] <= W_switch[i][0];
    end
  end

  genvar i, j;
  for (i = 0; i < sys_rows; i++) begin
    for (j = 0; j < sys_cols; j++) begin
      //for control signals flowing downward
      if (i == 0 && j == 0)
        mac mac_instance (
            .clk(clk),
            .rst(rst),
            .switch_in(switch),
            .switch_out(W_switch[i][j+1]),
            .A_en(if_en[i]),
            .A_ready(A_ready[i][j]),
            .A_in(if_data[i]),
            .A_out(A_data[i][j]),
            .W_en(wfetch[j]),
            .W_ready(W_ready[i][j]),
            .W_in(i_wdata[j]),
            .W_out(W_data[i][j]),
            .P_in(bias),
            .P_out(P_data[i][j])
        );
      else if (i == 0 && j == sys_cols - 1)
        mac mac_instance (
            .clk(clk),
            .rst(rst),
            .switch_in(W_switch[i][j]),
            .switch_out(),
            .A_en(A_ready[i][j-1]),
            .A_ready(),
            .A_in(A_data[i][j-1]),
            .A_out(),
            .W_en(wfetch[j]),
            .W_ready(W_ready[i][j]),
            .W_in(i_wdata[j]),
            .W_out(W_data[i][j]),
            .P_in(bias),
            .P_out(P_data[i][j])
        );

      else if (i == 0)
        mac mac_instance (
            .clk(clk),
            .rst(rst),
            .switch_in(W_switch[i][j]),
            .switch_out(W_switch[i][j+1]),
            .A_en(A_ready[i][j-1]),
            .A_ready(A_ready[i][j]),
            .A_in(A_data[i][j-1]),
            .A_out(A_data[i][j]),
            .W_en(wfetch[j]),
            .W_ready(W_ready[i][j]),
            .W_in(i_wdata[j]),
            .W_out(W_data[i][j]),
            .P_in(bias),
            .P_out(P_data[i][j])
        );

      if (i == sys_rows - 1 && j == 0)
        mac mac_instance (
            .clk(clk),
            .rst(rst),
            .switch_in(W_switch[i][j]),
            .switch_out(W_switch[i][j+1]),
            .A_en(if_en[i]),
            .A_ready(A_ready[i][j]),
            .A_in(if_data[i]),
            .A_out(A_data[i][j]),
            .W_en(W_ready[i-1][j] & wfetch[j]),
            .W_ready(),
            .W_in(W_data[i-1][j]),
            .W_out(),
            .P_in(P_data[i-1][j]),
            .P_out(of_data[j])
        );

      else if (i == sys_rows - 1 && j == sys_cols - 1)
        mac mac_instance (
            .clk(clk),
            .rst(rst),
            .switch_in(W_switch[i][j]),
            .switch_out(),
            .A_en(A_ready[i][j-1]),
            .A_ready(),
            .A_in(A_data[i][j-1]),
            .A_out(),
            .W_en(W_ready[i-1][j] & wfetch[j]),
            .W_ready(),
            .W_in(W_data[i-1][j]),
            .W_out(),
            .P_in(P_data[i-1][j]),
            .P_out(of_data[j])
        );

      else if (i == sys_rows - 1)
        mac mac_instance (
            .clk(clk),
            .rst(rst),
            .switch_in(W_switch[i][j]),
            .switch_out(W_switch[i][j+1]),
            .A_en(A_ready[i][j-1]),
            .A_ready(A_ready[i][j]),
            .A_in(A_data[i][j-1]),
            .A_out(A_data[i][j]),
            .W_en(W_ready[i-1][j] & wfetch[j]),
            .W_ready(),
            .W_in(W_data[i-1][j]),
            .W_out(),
            .P_in(P_data[i-1][j]),
            .P_out(of_data[j])
        );

      //for control signals flowing rightward
      if (i != sys_rows - 1 && i != 0 && j == 0)
        mac mac_instance (
            .clk(clk),
            .rst(rst),
            .switch_in(W_switch[i][j]),
            .switch_out(W_switch[i][j+1]),
            .A_en(if_en[i]),
            .A_ready(A_ready[i][j]),
            .A_in(if_data[i]),
            .A_out(A_data[i][j]),
            .W_en(W_ready[i-1][j] & wfetch[j]),
            .W_ready(W_ready[i][j]),
            .W_in(W_data[i-1][j]),
            .W_out(W_data[i][j]),
            .P_in(P_data[i-1][j]),
            .P_out(P_data[i][j])
        );

      else if (i != sys_rows - 1 && i != 0 && j == sys_cols - 1)
        mac mac_instance (
            .clk(clk),
            .rst(rst),
            .switch_in(W_switch[i][j]),
            .switch_out(),
            .A_en(A_ready[i][j-1]),
            .A_ready(),
            .A_in(A_data[i][j-1]),
            .A_out(),
            .W_en(W_ready[i-1][j] & wfetch[j]),
            .W_ready(W_ready[i][j]),
            .W_in(W_data[i-1][j]),
            .W_out(W_data[i][j]),
            .P_in(P_data[i-1][j]),
            .P_out(P_data[i][j])
        );
      else if (i != sys_rows - 1 && i != 0 && j != 0 && j != sys_cols - 1)
        mac mac_instance (
            .clk(clk),
            .rst(rst),
            .switch_in(W_switch[i][j]),
            .switch_out(W_switch[i][j+1]),
            .A_en(A_ready[i][j-1]),
            .A_ready(A_ready[i][j]),
            .A_in(A_data[i][j-1]),
            .A_out(A_data[i][j]),
            .W_en(W_ready[i-1][j] & wfetch[j]),
            .W_ready(W_ready[i][j]),
            .W_in(W_data[i-1][j]),
            .W_out(W_data[i][j]),
            .P_in(P_data[i-1][j]),
            .P_out(P_data[i][j])
        );
    end
  end
endmodule
