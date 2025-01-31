# Matrix Multiplication using Systolic Arrays

## Overview
This project implements a hardware accelerator for matrix multiplication using a systolic array architecture. The design is optimized for high-throughput and low-latency matrix operations, making it suitable for applications such as neural network inference, signal processing, and scientific computing. The systolic array is a 2D grid of processing elements (PEs) that perform multiply-accumulate (MAC) operations in a pipelined manner, enabling efficient computation of large matrices.

The design is implemented in SystemVerilog and consists of several modules that work together to manage data flow, control, and computation. The project is modular and scalable, allowing for easy customization of array dimensions and data widths.

---

## Table of Contents
1. [Project Structure](#project-structure)
2. [Architecture Overview](#architecture-overview)
3. [Module Descriptions](#module-descriptions)
   - [Controller](#controller)
   - [Datapath](#datapath)
   - [Systolic Array](#systolic-array)
   - [Input Buffer](#input-buffer)
   - [Weight Buffer](#weight-buffer)
   - [Accumulator](#accumulator)
   - [Instruction Decoder](#instruction-decoder)
   - [Buffer](#buffer)
4. [Configuration](#configuration)
5. [Simulation and Testing](#simulation-and-testing)
6. [Future Work](#future-work)

---

## Project Structure
The project is organized into the following directories:
- **`rtl/Controller/`**: Contains the control logic for the systolic array.
- **`rtl/Datapath/`**: Contains the datapath modules, including the systolic array, buffers, and accumulator.
- **`rtl/Utilities/`**: Contains utility modules such as the FIFO buffer.

---

## Architecture Overview
The design consists of three main components:
1. **Controller**: Manages the overall operation of the systolic array, including instruction decoding, buffer control, and state transitions.
2. **Datapath**: Handles data movement and computation, including input/weight buffering, systolic array processing, and result accumulation.
3. **Systolic Array**: A 2D grid of MAC units that perform matrix multiplication in a pipelined manner.

Data flows through the system as follows:
1. Input matrices (feature and weight) are loaded into their respective buffers.
2. The controller coordinates the flow of data into the systolic array.
3. The systolic array computes partial results, which are accumulated and output.

---

## Module Descriptions

### Controller
The `controller` module is the brain of the system. It decodes instructions, manages buffer reads/writes, and controls the operation of the systolic array. It uses a finite state machine (FSM) to handle different phases of computation, such as weight loading, input loading, and computation.

### Datapath
The `datapath` module integrates all datapath components, including the systolic array, input buffer, weight buffer, and accumulator. It manages data flow between these components and ensures correct timing and synchronization.

### Systolic Array
The `systolic` module implements the 2D systolic array. It consists of a grid of MAC units that perform matrix multiplication. Data flows through the array in a pipelined manner, with partial results propagated downward and rightward.

### Input Buffer
The `input_buffer` module stores input feature data and feeds it into the systolic array. It supports multiple columns and ensures data is available when needed.

### Weight Buffer
The `weight_buffer` module stores weight data and feeds it into the systolic array. Like the input buffer, it supports multiple columns and ensures data availability.

### Accumulator
The `accumulator` module aggregates partial results from the systolic array and produces the final output. It handles the accumulation of results across multiple computation cycles.

### Instruction Decoder
The `instr_dec` module decodes instructions and generates control signals for the controller. It interfaces with an instruction buffer and extracts start/last signals for computation sequences.

### Buffer
The `buffer` module is a parameterized FIFO used for storing instructions, input data, and weights. It supports configurable depth and data width.

---

## Configuration
The design is highly configurable through the `Config` package. Key parameters include:
- **`sys_rows`**: Number of rows in the systolic array.
- **`sys_cols`**: Number of columns in the systolic array.
- **`A_BITWIDTH`**: Bitwidth of input feature data.
- **`W_BITWIDTH`**: Bitwidth of weight data.
- **`P_BITWIDTH`**: Bitwidth of partial results.
- **`IBUFF_SIZE`**: Depth of the instruction buffer.
- **`w_buffer_depth`**: Depth of the weight buffer.

To customize the design, modify the parameters in the `Config` package and recompile the design.

---

## Simulation and Testing
The design can be simulated using any SystemVerilog-compatible simulator. Testbenches should be developed to verify the functionality of each module and the overall system. Key test scenarios include:
- Loading input and weight matrices into buffers.
- Verifying correct operation of the systolic array.
- Testing accumulation of partial results.
- Validating control logic and state transitions.

---

## Future Work
1. **Performance Optimization**: Explore techniques to further improve throughput and reduce latency.
2. **Scalability**: Extend the design to support larger matrices and higher dimensions.
3. **Power Optimization**: Investigate low-power design techniques for energy-efficient operation.
4. **Integration**: Integrate the design into a larger system-on-chip (SoC) for real-world applications.
---

## Contributing
Contributions are welcome! Please open an issue or submit a pull request for any improvements or bug fixes.

---
