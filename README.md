
# Universal Structural and Behavioral Comparator (using Verilog HDL)

## Overview

This project involves designing and implementing a **Universal Comparator** that supports both **signed** and **unsigned** 6-bit inputs.  
The comparator determines if one input is greater than, equal to, or smaller than another input based on a selection line.  
Both structural (gate-level) and behavioral Verilog HDL designs are developed, verified, and tested.

---

## Files

| File | Description |
|:-----|:------------|
| `code.v` | Verilog HDL code implementing the universal comparator (both structural and behavioral) |
| `block_diagram.bde` | Block diagram representation of the comparator architecture |
| `report.pdf` | Full formal report including theory, design, results, and future work |
| `project.pdf` | Official project description and requirements |

---

## Design Details

- Inputs:
  - `A`: 6-bit input
  - `B`: 6-bit input
  - `S`: Selection line (0 = Unsigned, 1 = Signed)

- Outputs:
  - `Equal`: 1 if A == B
  - `Greater`: 1 if A > B
  - `Smaller`: 1 if A < B

- The structural design is fully built using only basic logic gates:
  - INV, NAND, NOR, AND, OR, XNOR, XOR (with max 4 inputs each)

- Registers are added to synchronize inputs and outputs with a clock.

- Behavioral model is developed to verify correctness.

- A **Linear Feedback Shift Register (LFSR)** is used to generate random test vectors for verification.

---


## Requirements

- Verilog HDL Simulator (e.g., ModelSim, Vivado, etc)
- Basic knowledge of digital design and combinational circuits




