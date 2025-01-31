/*
 * Buffer Module Description:
 * This module implements a parameterized FIFO (First-In-First-Out) buffer.
 * Key features:
 * - Configurable depth, data width, and debug dump length
 * - Supports separate read/write clocks for asynchronous operation
 * - Provides full/empty status flags
 * - Optional initialization from a file (commented out)
 * - Synchronous reset and enable controls
 */

// Import configuration parameters
import Config::*;

module buffer #(
    parameter filename = "",  // File for initializing buffer (optional)
    parameter DEPTH = 8,      // Depth of the FIFO buffer
    parameter DWIDTH = 16,    // Width of each data entry
    parameter DUMP_LEN = 3    // Length of data to dump for debugging
) (
    // Control signals
    input rstn,               // Active-low reset
    input wr_clk,             // Write clock
    input rd_clk,             // Read clock
    input wr_en,              // Write enable
    input rd_en,              // Read enable
    // Data interface
    input [DWIDTH-1:0] din,   // Input data
    output reg [DWIDTH-1:0] dout,  // Output data
    // Status flags
    output empty,             // Buffer empty flag
    output full               // Buffer full flag
);

  // Internal pointers and storage
  reg [$clog2(DEPTH)-1:0] wptr;  // Write pointer
  reg [$clog2(DEPTH)-1:0] rptr;  // Read pointer
  reg [DWIDTH-1 : 0] fifo[DEPTH];  // FIFO storage array

  //----------------------------------------------------------
  // Initialization Block (Commented Out)
  // Can be used to initialize the buffer from a file
  // Uncomment to enable:
  // - Initialize FIFO memory with zeros
  // - Load initial data from 'filename'
  // - Set write pointer to DUMP_LEN
  // - Reset read pointer to 0
  //----------------------------------------------------------
  // initial begin
  //   fifo = '{default: '0};  // Initialize all entries to 0
  //   $readmemh(filename, fifo);  // Load data from file
  //   wptr <= DUMP_LEN;  // Set write pointer after loaded data
  //   rptr <= 0;  // Reset read pointer
  // end

  //----------------------------------------------------------
  // Write Logic Always Block
  // Handles data writing to the FIFO:
  // - Resets write pointer on active-low reset
  // - Writes data to FIFO when wr_en is high and buffer is not full
  // - Increments write pointer after write
  //----------------------------------------------------------
  always @(posedge wr_clk) begin
    if (rstn) begin
      wptr <= '0;  // Reset write pointer
    end else begin
      if (wr_en & !full) begin  // Write only if enabled and not full
        fifo[wptr] <= din;  // Store input data
        wptr <= wptr + 1;   // Increment write pointer
      end
    end
  end

  //----------------------------------------------------------
  // Read Logic Always Block
  // Handles data reading from the FIFO:
  // - Resets read pointer on active-low reset
  // - Increments read pointer when rd_en is high and buffer is not empty
  // - Outputs data from FIFO at current read pointer
  //----------------------------------------------------------
  always @(posedge rd_clk) begin
    if (rstn) begin
      rptr <= 0;  // Reset read pointer
    end else begin
      if (rd_en & !empty) begin  // Read only if enabled and not empty
        rptr <= rptr + 1;  // Increment read pointer
      end
      // Optional: Clear output when empty (commented out)
      // else if (empty) dout <= 0;
    end
  end

  //----------------------------------------------------------
  // Output and Status Assignments
  // - dout: Outputs data at current read pointer
  // - full: Flag indicating buffer is full
  // - empty: Flag indicating buffer is empty
  //----------------------------------------------------------
  assign dout  = fifo[rptr];  // Output data at read pointer
  assign full  = (wptr + 1) == rptr;  // Full when next write equals read
  assign empty = wptr == rptr;        // Empty when write equals read

endmodule