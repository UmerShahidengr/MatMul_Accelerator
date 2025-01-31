/*
 * Controller Module Description:
 * Main control unit for systolic array-based processing system. Manages:
 * - Instruction decoding and sequencing
 * - Weight/input feature buffer coordination
 * - Systolic array operation modes
 * - State machine for: 
 *   * Weight loading (FETCH state)
 *   * Concurrent weight/input loading (FetchAndConv)
 *   * Computation phases (CONV/W_WAIT)
 * Interfaces with datapath through control signals and handles instruction pipeline.
 */

// Import configuration parameters
import Config::*;

module controller (
    // Global control
    input clk,              // System clock
    input rst,              // Active-high reset
    // Operation control
    input start,            // Start processing command
    input w_done,           // Weight loading complete from datapath
    input if_done,          // Input feature loading complete from datapath
    input rd_nxt_inst,      // Ready for next instruction from datapath
    // Instruction interface
    input logic instr_valid,// Valid instruction available
    input logic [INSTR_SIZE-1:0] instr,  // Instruction input
    // Buffer control outputs
    output logic w_read,    // Read weight buffer
    output logic if_read,   // Read input feature buffer
    // Counter control
    output logic clr_w,     // Clear weight counter
    output logic clr_if,    // Clear input feature counter
    // Systolic control
    output logic switch,    // Switch systolic mode (load/compute)
    output logic ready,     // System ready for new command
    // Sequence control
    output logic first,     // First operation in sequence
    output logic last       // Last operation in sequence
);

  // FSM state definitions
  localparam int IDLE = 0;         // Waiting for start command
  localparam int FETCH = 1;        // Weight loading state
  localparam int FetchAndConv = 2; // Concurrent weight/input loading & computation
  localparam int CONV = 3;         // Computation state
  localparam int W_WAIT = 4;       // Weight loading wait state
  logic [2:0] cs, ns;              // Current/next state registers

  //----------------------------------------------------------
  // Combinational State Logic Always Block
  // Main control logic for:
  // - Buffer read/write controls
  // - Counter management
  // - State transitions
  // - Systolic array mode switching
  //----------------------------------------------------------
  always_comb begin
    // Default assignments
    ready   = 0;          // System not ready
    clr_w   = 0;          // Don't clear weight counter
    clr_if  = 0;          // Don't clear input counter
    switch  = 0;          // Systolic in compute mode
    w_read  = 0;          // Don't read weights
    if_read = 0;          // Don't read inputs

    case (cs)
      IDLE: begin
        if (~start) begin
          ready = 1;      // System ready for new command
          ns = IDLE;      // Maintain idle state
        end else begin
          clr_w = 1;      // Initialize weight counter
          ns = FETCH;     // Transition to weight loading
        end
      end

      FETCH: begin
        if (~w_done) begin
          w_read = 1;     // Continue weight loading
          ns = FETCH;     // Stay in fetch
        end else if (w_done & start) begin
          switch = 1;     // Switch to load mode
          clr_if = 1;     // Reset input counter
          clr_w = 1;      // Reset weight counter
          ns = FetchAndConv; // Concurrent loading
        end else begin
          switch = 1;     // Switch to load mode
          clr_if = 1;     // Reset input counter
          ns = CONV;      // Proceed to computation
        end
      end

      FetchAndConv: begin
        if (start & if_done & w_done) begin
          switch = 1;     // Maintain load mode
          clr_if = 1;     // Reset input counter
          clr_w = 1;      // Reset weight counter
          ns = FetchAndConv; // Continue concurrent
        end else if (~if_done & ~w_done) begin
          w_read = 1;     // Read weights
          if_read = 1;    // Read inputs
          ns = FetchAndConv; // Stay in concurrent
        end else if (if_done & ~w_done) begin
          w_read = 1;     // Continue weight load
          ns = FETCH;     // Return to weight-only
        end else begin
          if_read = 1;    // Continue input load
          ns = W_WAIT;    // Enter weight wait
        end
      end

      CONV: begin
        if (~start & ~if_done) begin
          if_read = 1;    // Continue input load
        end else if (if_done & start) begin
          clr_w = 1;      // Reset weight counter
          ns = FETCH;     // Start new weight load
        end else if (~if_done & start) begin
          clr_w = 1;      // Reset weight counter
          ns = FetchAndConv; // Concurrent mode
        end else begin
          ready = 1;      // Mark system ready
          ns = IDLE;      // Return to idle
        end
      end

      W_WAIT: begin
        if (~if_done) begin
          if_read = 1;    // Continue input load
        end else if (start & if_done) begin
          switch = 1;     // Enter load mode
          clr_if = 1;     // Reset input counter
          clr_w = 1;      // Reset weight counter
          ns = FetchAndConv; // Concurrent loading
        end else begin
          clr_w = 1;      // Reset weight counter
          clr_if = 1;     // Reset input counter
          ns = CONV;      // Proceed to computation
        end
      end
    endcase
  end

  //----------------------------------------------------------
  // State Register Always Block
  // Manages state transitions with synchronous reset
  //----------------------------------------------------------
  always_ff @(posedge clk) begin
    if (rst) cs <= 0;         // Reset to IDLE state
    else cs <= ns;            // Normal state transition
  end

  // Instruction Decoder Instance
  // Translates incoming instructions to control signals
  instr_dec instr_dec_instance (
      .clk(clk),            // Clock
      .rst(rst),            // Reset
      .wr_en(instr_valid),  // Valid instruction input
      .rd_nxt_inst(rd_nxt_inst), // Ready for next instruction
      .instr(instr),        // Instruction bus
      .start(first),        // Output: Sequence start
      .last(last)           // Output: Sequence end
  );

endmodule : controller