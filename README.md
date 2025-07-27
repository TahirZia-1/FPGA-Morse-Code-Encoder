# FPGA-Based Morse Code Communication System

## Overview
This project implements a Morse code encoder on the Nexys 4 DDR FPGA board, designed to convert decimal digits (0-9) into Morse code, displayed via an LED (LD0). The system supports two operational modes: **Single-Digit Mode** for encoding one digit at a time and **Number Mode** for storing and encoding up to six digits using a FIFO buffer. The design leverages Verilog HDL, a finite state machine (FSM), and a debouncer to ensure reliable operation. This README provides a comprehensive guide to the project's functionality, setup, and usage.

## Features
- **Two Operating Modes**:
  - **Single-Digit Mode**: Converts a single digit (set via switches SW0-SW3) into its Morse code equivalent when BTN1 is pressed.
  - **Number Mode**: Stores up to six digits in a FIFO buffer (using SW0-SW3 and BTN1) and encodes them sequentially when BTN2 is pressed.
- **Inputs**:
  - 100 MHz clock (clk)
  - Reset button (BTN0)
  - Start/Store button (BTN1)
  - Encode Number button (BTN2)
  - 5-bit switches (SW4 for mode selection, SW0-SW3 for digit input)
- **Outputs**:
  - LED (LD0): Displays Morse code (dot: 1s ON, dash: 3s ON, element space: 0.5s OFF, inter-digit gap: 2s OFF)
  - State LED (LD1): Indicates active encoding state
- **Timing**:
  - Dot: 1 second
  - Dash: 3 seconds
  - Space between elements: 0.5 seconds
  - Inter-digit gap: 2 seconds
- **Debouncing**: Ensures reliable button inputs using a 10ms debounce circuit at 100 MHz.
- **FIFO Buffer**: Stores up to six digits in Number Mode for sequential encoding.

## Project Structure
- **Morse.sv**: Contains the Verilog modules:
  - `debouncer`: Debounces button inputs to eliminate noise.
  - `morse_encoder`: Core FSM and logic for Morse code encoding, including FIFO management.
  - `morse_top`: Top-level module integrating debouncers and encoder.
- **Morse_xdc.xdc**: Constraints file mapping inputs (SW0-SW4, BTN0-BTN2) and outputs (LD0, LD1) to Nexys 4 DDR board pins.
- **Report.pdf**: Detailed design report, including hardware implementation, testing phases, and conclusions.

## Morse Code Patterns
The system encodes digits 0-9 into Morse code as follows (dots and dashes are represented as 1s and 0s in a 5-bit pattern):

| Digit | Morse Pattern | Verilog Pattern (5-bit) |
|-------|---------------|------------------------|
| 0     | -----         | 00000                  |
| 1     | .----         | 10000                  |
| 2     | ..---         | 11000                  |
| 3     | ...--         | 11100                  |
| 4     | ....-         | 11110                  |
| 5     | .....         | 11111                  |
| 6     | -....         | 01111                  |
| 7     | --...         | 00111                  |
| 8     | ---..         | 00011                  |
| 9     | ----.         | 00001                  |

## Hardware Requirements
- **FPGA Board**: Nexys 4 DDR (or compatible Nexys A7 board)
- **Software**: Xilinx Vivado Design Suite for synthesis and implementation
- **Inputs**:
  - Switches: SW0-SW3 for digit input, SW4 for mode selection (0: Single-Digit Mode, 1: Number Mode)
  - Buttons: BTN0 (reset), BTN1 (start/store), BTN2 (encode number)
- **Outputs**:
  - LD0: Morse code output
  - LD1: Encoding state indicator

## Setup and Installation
1. **Clone the Repository**:
   ```bash
   git clone <repository_url>
   ```
2. **Open Vivado**:
   - Launch Xilinx Vivado and create a new project targeting the Nexys 4 DDR board (XC7A100T-1CSG324C).
3. **Add Source Files**:
   - Add `Morse.sv` as the design source.
   - Add `Morse_xdc.xdc` as the constraints file.
4. **Synthesis and Implementation**:
   - Run synthesis, implementation, and generate the bitstream in Vivado.
   - Program the Nexys 4 DDR board with the generated bitstream.
5. **Verify Pin Assignments**:
   - Ensure the pin mappings in `Morse_xdc.xdc` match the Nexys 4 DDR board specifications:
     - Clock: E3
     - Switches: J15 (SW0), L16 (SW1), M13 (SW2), R15 (SW3), R17 (SW4)
     - Buttons: M17 (BTN0), P17 (BTN1), M18 (BTN2)
     - LEDs: H17 (LD0), V11 (LD1)

## Usage
### Single-Digit Mode (SW4 = 0)
1. Set SW4 to 0 to select Single-Digit Mode.
2. Configure SW0-SW3 to represent a digit (0-9) in binary (e.g., 0010 for 2).
3. Press BTN1 to start encoding.
4. Observe the Morse code output on LD0 (e.g., for digit 2, see `..---`).
5. LD1 lights up during encoding.
6. Press BTN0 to reset the system.

### Number Mode (SW4 = 1)
1. Set SW4 to 1 to select Number Mode.
2. Configure SW0-SW3 to a digit (0-9) and press BTN1 to store (up to 6 digits).
3. Repeat step 2 for additional digits.
4. Press BTN2 to encode all stored digits sequentially.
5. Observe the Morse code output on LD0 with a 2-second gap between digits.
6. LD1 lights up during encoding.
7. Press BTN0 to reset the system.

### Example Test Cases
- **Single-Digit Mode**:
  - Set SW0-SW3 to 0010 (digit 2), SW4 to 0, press BTN1: LD0 displays `..---` (2s ON, 0.5s OFF, 2s ON, 0.5s OFF, 1s ON, 0.5s OFF, 1s ON, 0.5s OFF, 1s ON).
- **Number Mode**:
  - Set SW4 to 1, enter digits 3 (0011) and 5 (0101) with BTN1, then press BTN2: LD0 displays `...--` (for 3), 2s gap, then `.....` (for 5).

## Design Details
- **Debouncer**: Eliminates button bounce with a 10ms delay (1,000,000 cycles at 100 MHz).
- **FSM States**:
  - IDLE: Waiting for input, LED off.
  - ENCODING_DIGIT: Outputs Morse code for the current digit.
  - INTER_DIGIT_GAP: Inserts a 2-second gap between digits in Number Mode.
- **FIFO Buffer**: Stores up to six 4-bit digits in Number Mode, managed by write and read pointers.
- **Timing**: Precise timing for dots, dashes, spaces, and gaps is achieved using a 100 MHz clock and cycle counts.

## Testing and Validation
- **Phase 1**: Verified Single-Digit Mode by encoding digit 2 (SW0-SW3 = 0010), confirming `..---` on LD0 and LD1 indicating active encoding.
- **Phase 2**: Verified Number Mode by storing digits 3 (0011) and 5 (0101), then encoding with BTN2, confirming `...--` followed by a 2s gap and `.....` on LD0.
- **Simulation**: Waveforms validated FSM transitions and timing.
- **Synthesis Metrics**: Efficient resource usage confirmed via Vivado reports.

## Challenges and Solutions
- **Button Bounce**: Addressed by implementing a debouncer module.
- **FIFO Management**: Optimized write and read pointers to prevent overflow and ensure correct digit sequencing.
- **Timing Accuracy**: Calibrated cycle counts for precise Morse code timing at 100 MHz.
