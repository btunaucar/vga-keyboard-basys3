# Simple VGA Keyboard on Basys3

A modular FPGA system built in VHDL on the **Basys3 (Artix-7)** board. Takes ASCII character input via onboard switches and push buttons, and renders text in real time on a VGA monitor using a custom font ROM and VGA timing controller.

---

## Features

- 7-bit ASCII input via onboard switches (SW[6:0])
- Push button controls: Enter, Clear, Save, Load
- 1 ms debounce logic for reliable button presses at 100 MHz
- Real-time VGA output at 640×480 @ 60 Hz
- Custom 8×16 pixel font ROM covering all 128 ASCII characters
- Two-row text display with tab and line-feed support
- Save and recall message functionality

---

## Demo

YouTube: https://youtu.be/D44ysD2qB30

---

## Button Map

| Button | Function |
|--------|----------|
| BTN_C  | Active-low reset |
| BTN[0] | Enter — append current SW[6:0] to display buffer |
| BTN[1] | Clear — reset display buffer |
| BTN[2] | Save — copy buffer to saved slot |
| BTN[3] | Load — restore saved slot to display |

---

## Hardware

| Component | Description |
|-----------|-------------|
| Basys3    | Artix-7 FPGA board |
| VGA port  | 640×480 @ 60 Hz, 4-bit R/G/B |
| Switches  | SW[6:0] — 7-bit ASCII code input |
| Buttons   | BTN[3:0] + BTN_C |

---

## Pin Constraints (const.xdc)

| Signal   | Package Pin | Function |
|----------|-------------|----------|
| clk100   | W5          | 100 MHz board clock |
| reset_n  | U18         | BTN_C — reset |
| BTN[0]   | T18         | Enter |
| BTN[1]   | T17         | Clear |
| BTN[2]   | W19         | Save |
| BTN[3]   | U17         | Load |
| SW[0–6]  | V17–W14     | ASCII input |
| VGA_HS   | P19         | Horizontal sync |
| VGA_VS   | R19         | Vertical sync |
| VGA_R[3:0] | G19–N19   | Red channel |
| VGA_G[3:0] | J17–D17   | Green channel |
| VGA_B[3:0] | N18–J18   | Blue channel |

---

## Module Overview

| File | Description |
|------|-------------|
| `top.vhd` | Top-level: wires all modules together |
| `vga.vhd` | VGA controller: clock divider, pixel output |
| `vga_timing.vhd` | HS/VS sync generation for 640×480 @ 60 Hz |
| `char_buffer.vhd` | 32-char active buffer + saved buffer |
| `line_buffer.vhd` | Maps buffer to screen coordinates, handles special chars |
| `char_rom.vhd` | 128-glyph 8×16 font bitmap ROM |
| `debounce.vhd` | 1 ms one-shot pulse generator for all buttons |
| `const.xdc` | Vivado pin and clock constraints |

---

## Build

- **Tool:** Vivado (Xilinx)
- **Target:** Basys3 — xc7a35tcpg236-1
- Add all `.vhd` files as design sources and `const.xdc` as a constraint
- Run Synthesis → Implementation → Generate Bitstream → Program Device

---

## Project Page

Full write-up with block diagram and annotated source: **[btunaucar.github.io/projects/vga-keyboard](https://btunaucar.github.io/projects/vga-keyboard)**

---

*Baran Tuna Uçar — Bilkent University, Electrical and Electronics Engineering*
