# BusBridge AXI4-Lite IP


## Overview

BusBridge is a synthesizable AXI4-Lite slave IP designed to provide a simple register interface for controlling and monitoring a peripheral.

The design implements an AXI4-Lite slave interface with control, status, data, and interrupt registers.

## Features

- AXI4-Lite slave interface
- Independent AXI write address and write data channels
- Read and write register access
- Byte write strobe support
- Invalid address detection
- SLVERR response for unsupported addresses
- Interrupt enable and status registers
- External event input
- Peripheral ready output
- SystemVerilog RTL
- Icarus Verilog simulation support

## Register Map

| Address | Register | Description |
|--------:|----------|-------------|
| 0x00 | CTRL | Control register |
| 0x04 | STATUS | Peripheral status |
| 0x08 | DATA | Data register |
| 0x0C | IRQ_EN | Interrupt enable |
| 0x10 | IRQ_STATUS | Interrupt status |

## Project Structure

```text
BusBridge-AXI4-Lite-IP/
├── rtl/
│   ├── busbridge_axi_lite.sv
│   └── busbridge_regs.sv
├── tb/
│   └── tb_busbridge.sv
├── sim/
├── constraints/
├── docs/
├── reports/
├── scripts/
└── README.md