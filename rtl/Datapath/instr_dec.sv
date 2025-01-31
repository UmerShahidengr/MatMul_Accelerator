/*
 * Instruction Decoder Module Description:
 * This module decodes instructions for the systolic array processing system.
 * Key features:
 * - Interfaces with instruction buffer to fetch instructions
 * - Extracts control signals (start/last) from instruction format
 * - Uses a parameterized buffer for instruction storage
 * - Handles instruction flow control with read/write enables
 */

// Import configuration parameters
import Config::*;

module instr_dec (
    // Global control signals
    input logic clk,          // System clock
    input logic rst,          // Active-high reset
    // Buffer control
    input logic wr_en,        // Write enable for instruction buffer
    input logic rd_nxt_inst,  // Read next instruction signal
    // Instruction interface
    input logic [INSTR_SIZE-1:0] instr,  // Input instruction bus
    // Decoded control signals
    output logic start,       // Start operation signal
    output logic last         // Last operation signal
);

  // Internal instruction register
  logic [INSTR_SIZE-1:0] current_instr;  // Currently decoded instruction

  //----------------------------------------------------------
  // Instruction Buffer Instance
  // Parameterized FIFO buffer for instruction storage
  // Configuration:
  // - filename: Debug dump file
  // - DEPTH: Buffer depth from Config
  // - DWIDTH: Instruction width from Config
  // - DUMP_LEN: Debug dump length
  //----------------------------------------------------------
  buffer #(
      .filename("instr.txt"),  // Debug output file
      .DEPTH(IBUFF_SIZE),      // Instruction buffer size
      .DWIDTH(INSTR_SIZE),     // Instruction width
      .DUMP_LEN(4)             // Debug dump length
  ) buffer_instance(
      .rstn(rst),              // Active-low reset
      .wr_clk(clk),            // Write clock
      .rd_clk(clk),            // Read clock
      .wr_en(wr_en),           // Write enable
      .rd_en(rd_nxt_inst),     // Read enable
      .din(instr),             // Input instruction
      .dout(current_instr),    // Output instruction
      .empty(),                // Buffer empty flag (unused)
      .full()                  // Buffer full flag (unused)
  );

  //----------------------------------------------------------
  // Instruction Decoding Logic
  // Extracts control signals from instruction format:
  // - start: Bit 0 of current instruction
  // - last: Bit 1 of current instruction
  //----------------------------------------------------------
  assign start = current_instr[0];  // Start operation flag
  assign last  = current_instr[1];  // Last operation flag

endmodule