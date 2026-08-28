# BusBridge AXI4-Lite IP Integration Guide

## 1. Overview

BusBridge is a reusable AXI4-Lite slave peripheral IP.

The IP provides a standard AXI4-Lite interface for register-based control and monitoring of a peripheral.

It also provides interrupt and status signaling through dedicated registers and external signals.

## 2. Top-Level Interface

### Clock and Reset

| Signal | Direction | Description |
|---|---|---|
| `clk` | Input | System clock |
| `rst_n` | Input | Active-low reset |

### AXI4-Lite Write Address Channel

| Signal | Direction | Description |
|---|---|---|
| `s_axi_awaddr` | Input | Write address |
| `s_axi_awvalid` | Input | Write address valid |
| `s_axi_awready` | Output | Write address ready |

### AXI4-Lite Write Data Channel

| Signal | Direction | Description |
|---|---|---|
| `s_axi_wdata` | Input | Write data |
| `s_axi_wstrb` | Input | Byte write strobes |
| `s_axi_wvalid` | Input | Write data valid |
| `s_axi_wready` | Output | Write data ready |

### AXI4-Lite Write Response Channel

| Signal | Direction | Description |
|---|---|---|
| `s_axi_bresp` | Output | Write response |
| `s_axi_bvalid` | Output | Write response valid |
| `s_axi_bready` | Input | Write response ready |

### AXI4-Lite Read Address Channel

| Signal | Direction | Description |
|---|---|---|
| `s_axi_araddr` | Input | Read address |
| `s_axi_arvalid` | Input | Read address valid |
| `s_axi_arready` | Output | Read address ready |

### AXI4-Lite Read Data Channel

| Signal | Direction | Description |
|---|---|---|
| `s_axi_rdata` | Output | Read data |
| `s_axi_rresp` | Output | Read response |
| `s_axi_rvalid` | Output | Read data valid |
| `s_axi_rready` | Input | Read data ready |

### Peripheral Signals

| Signal | Direction | Description |
|---|---|---|
| `event_i` | Input | External event input |
| `ready_o` | Output | Peripheral ready/status signal |
| `irq` | Output | Interrupt output |

## 3. Register Map

| Address | Register | Access | Description |
|---:|---|---|---|
| `0x00` | CTRL | RW | Control register |
| `0x04` | STATUS | RO | Peripheral status |
| `0x08` | DATA | RW | Data register |
| `0x0C` | IRQ_EN | RW | Interrupt enable |
| `0x10` | IRQ_STATUS | RW | Interrupt status |

### CTRL — 0x00

Bit 0 controls the peripheral ready output.

```text
CTRL[0] = 1 → ready_o = 1
CTRL[0] = 0 → ready_o = 0