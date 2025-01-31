/* 
 * Datapath Module Description:
 * This module implements a systolic array-based processing datapath for matrix operations,
 * commonly used in neural network acceleration. It integrates input/weight buffering,
 * systolic computation, and result accumulation. Key components include:
 * - Weight Buffer: Stores and manages weight matrix data.
 * - Input Buffer: Stores and manages input feature data.
 * - Systolic Array: Performs parallel multiply-accumulate operations in a pipelined manner.
 * - Accumulator: Aggregates partial results and manages output data flow.
 * The module includes control logic for data loading, computation sequencing, and result collection.
 */
/*
  * Module: datapath
  * Description:
  *   This module implements the datapath for a systolic-based computation unit.
  *   It integrates multiple components, including weight and input buffers, a systolic array,
  *   and an accumulator. The primary function of this datapath is to process input data
  *   through a systolic architecture and accumulate the results.
  *
  * Components:
  *   1. Weight Buffer: Stores and provides weight values to the systolic array.
  *   2. Input Buffer: Stores and provides input data to the systolic array.
  *   3. Systolic Array: Performs matrix multiplication or convolutional operations.
  *   4. Accumulator: Aggregates the outputs from the systolic array.
  *
  * Key Signals:
  *   - clk, rst: Clock and reset signals.
  *   - w_buffer_read, if_buffer_read: Read enable signals for weight and input buffers.
  *   - clr_w, clr_if: Control signals to reset weight and input counters.
  *   - switch: A control signal affecting systolic computation.
  *   - w_valid, if_valid: Indicates valid data for weights and inputs.
  *   - wdata, if_data: Weight and input data buses.
  *   - w_done, if_done: Indicate completion of weight and input buffer processing.
  *   - rd_nxt_inst: Signal to indicate that the accumulator is ready for the next instruction.
  *   - read_out: Output read enable signals.
  *   - o_data: Final output data from the accumulator.
  */


// Import configuration parameters from Config package
import Config::*;

module datapath (
    // Global control signals
    input logic clk,              // Main clock
    input logic rst,              // Active-high reset
    // Weight buffer control
    input logic w_buffer_read,    // Read enable for weight buffer
    // Input buffer control
    input logic if_buffer_read,   // Read enable for input feature buffer
    // Clear signals
    input logic clr_w,            // Clear weight counter
    input logic clr_if,           // Clear input feature counter
    // Systolic array control
    input logic switch,           // Control signal for systolic operation mode
    input logic first,            // Marks first operation in sequence
    input logic last,             // Marks last operation in sequence
    // Weight data interface
    input logic [sys_cols-1:0] w_valid,          // Per-column weight valid flags
    input logic [sys_cols-1:0][W_BITWIDTH-1:0] wdata,  // Weight data bus
    // Input feature interface
    input logic [sys_cols-1:0] if_valid,         // Per-column input feature valid flags
    input logic [sys_cols-1:0][W_BITWIDTH-1:0] if_data,  // Input feature data
    // Status outputs
    output logic w_done,          // Weight loading complete
    output logic if_done,         // Input feature loading complete
    output logic rd_nxt_inst,     // Read next instruction signal
    // Output interface
    output logic [sys_cols-1:0] read_out,        // Per-column read enable
    output logic [sys_cols-1:0][P_BITWIDTH-1:0] o_data  // Final output data
);

  // Internal data buses
  logic [sys_cols-1:0][P_BITWIDTH-1:0] of_data;  // Systolic array output
  // Buffer control signals
  logic [sys_rows-1:0] if_en;         // Input feature enable for systolic array
  // Systolic array inputs
  logic [sys_rows-1:0][A_BITWIDTH-1:0] i_sys_ifdata;  // Processed input features
  logic [sys_cols-1:0][W_BITWIDTH-1:0] i_sys_wdata;   // Processed weights
  // Weight fetch control
  logic [sys_cols-1:0] wfetch;        // Weight fetch enable per column
  // Operation counters
  logic [$clog2(sys_rows+1)-1:0] count_w;    // Weight row counter
  logic [$clog2(A_rows+1)-1:0] count_if;     // Input feature row counter

  // Counter status assignments
  assign w_done = count_w == sys_rows;    // Weight counter completion
  assign if_done = count_if == A_rows;    // Input feature counter completion

  //----------------------------------------------------------
  // Weight Row Counter Always Block
  // Tracks number of weight rows loaded into the system
  // - Clears counter when clr_w is asserted
  // - Increments counter each cycle when not cleared
  //----------------------------------------------------------
  always_ff @(posedge clk) begin
    if (clr_w) count_w <= 0;          // Synchronous clear
    else count_w <= count_w + 1;      // Increment count
  end

  //----------------------------------------------------------
  // Input Feature Row Counter Always Block
  // Tracks number of input feature rows processed
  // - Clears counter when clr_if is asserted
  // - Increments counter each cycle when not cleared
  //----------------------------------------------------------
  always_ff @(posedge clk) begin
    if (clr_if) count_if <= 0;        // Synchronous clear
    else count_if <= count_if + 1;    // Increment count
  end

  // Weight Buffer Instance
  // Stores and manages weight matrix distribution to systolic array
  weight_buffer weight_buffer_instance (
      .rst(rst),              // Reset
      .clk(clk),              // Clock
      .read(w_buffer_read),   // Read enable
      .wr_en(w_valid),        // Per-column write enable
      .i_data(wdata),         // Input weight data
      .o_valid(wfetch),       // Output valid to systolic array
      .o_data(i_sys_wdata)    // Buffered weight data output
  );

  // Input Feature Buffer Instance
  // Stores and manages input feature distribution to systolic array
  input_buffer input_buffer_instance (
      .rst(rst),              // Reset
      .clk(clk),              // Clock
      .read(if_buffer_read),  // Read enable
      .wr_en(if_valid),       // Per-column write enable
      .i_data(if_data),       // Input feature data
      .o_valid(if_en),        // Output valid to systolic array
      .o_data(i_sys_ifdata)   // Buffered feature data output
  );

  // Systolic Array Instance
  // Core computation unit for matrix multiplication
  systolic sys_instance (
      .clk(clk),              // Clock
      .rst(rst),              // Reset
      .switch(switch),        // Operation mode control
      .if_en(if_en),          // Input feature enable
      .wfetch(wfetch),        // Weight fetch enable
      .if_data(i_sys_ifdata), // Preprocessed input features
      .i_wdata(i_sys_wdata),  // Preprocessed weights
      .bias(BIAS),            // Bias value from Config
      .of_data(of_data)       // Output feature data
  );

  // Accumulator Instance
  // Collects and processes systolic array outputs
  accumulator accumulator_instance (
      .rst(rst),              // Reset
      .clk(clk),              // Clock
      .start(first),          // Marks start of accumulation
      .last(last),            // Marks end of accumulation
      .enable(if_en[sys_rows-1]),  // Enable from last input buffer row
      .i_data(of_data),       // Input from systolic array
      .read_out(read_out),    // Output read enable
      .o_data(o_data),        // Final output data
      .done(rd_nxt_inst)      // Accumulation complete signal
  );

endmodule