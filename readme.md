# easySmallRisvTestgen

A lightweight, space-constrained, output-only bare-metal RISC-V (RV64IM) test generator. It is specifically designed for custom CPU design and computer architecture courses (e.g., Difftest, Verilator, or Vivado BRAM simulation).

When building a custom RISC-V CPU from scratch, we often face strict memory constraints, lack of standard peripheral support, and the inability to run complex operating systems. This project provides a **minimalist C++ cross-compilation environment** without any standard library dependencies. It allows you to compile C++ test code into raw machine code (`.bin`, `.coe`) with a single click natively on Windows.

## ✨ Features

- **Extremely Lightweight**: Stripped of all C++ standard libraries (`<iostream>`, etc.), running in a pure bare-metal environment.
- **Native Windows Support**: No need for WSL, MSYS2, or bulky Make toolchains. A native batch script handles everything.
- **Multi-Format Output**: Compiles into `.bin` (for Difftest/NEMU), `.S` (for assembly debugging), and `.coe` (strictly formatted for Vivado Block Memory Generator) simultaneously.
- **Configurable MMIO**: Built-in physical address mapping for UART output and hardware clock reading.

## 🛠️ Environment Setup

This project requires the RISC-V GNU cross-compilation toolchain. To run smoothly on Windows, please follow these steps:

1. **Download the Toolchain**:

   Go to the SiFive Freedom Tools releases page and download the v2020.12 Windows pre-compiled package:

   [riscv64-unknown-elf-toolchain-10.2.0-2020.12.8-x86_64-w64-mingw32.zip](https://static.dev.sifive.com/dev-tools/freedom-tools/v2020.12/riscv64-unknown-elf-toolchain-10.2.0-2020.12.8-x86_64-w64-mingw32.zip)

2. **Extract**:

   Unzip the downloaded file to your local drive (e.g., `D:\riscv64-unknown-elf-toolchain-10.2.0-2020.12.8-x86_64-w64-mingw32`).

3. **Set Environment Variables**:

   You can add the `bin` directory to your system's global `PATH` variable manually, OR execute the following command in your terminal before building:

   *Note: If you are using **PowerShell**, you must type `cmd` first to enter the Command Prompt environment before setting the variable.*

   ```
   set PATH=D:\riscv64-unknown-elf-toolchain-10.2.0-2020.12.8-x86_64-w64-mingw32\bin;%PATH%
   ```

## 🚀 Quick Start

1. **Write Your Test Program**:

   Create a new `.cc` file (or modify the included example `testicg.cc`) with your bare-metal C++ code. Pay attention to the formatting and constraints.

2. **Build**:

   In the CMD terminal, run the build script with your filename (without the extension):

   ```
   .\build.bat testicg
   ```

   *(If you run `.\build.bat` without arguments, it defaults to building `testicg.cc`)*

3. **Get Artifacts**:

   Once successfully built, you will find:

   - `testicg.bin`: Pure machine code for Difftest/Verilator simulation.
   - `testicg.S`: Disassembly file for PC pointer debugging.
   - `testicg.coe`: 64-bit aligned memory initialization file ready for Vivado.

## ⚠️ Configuration & Limitations (Important!)

Before deploying the generated code to your Vivado Simulation or FPGA, please be aware of the following:

**1. Hardcoded MMIO Settings:**

The example program `testicg.cc` contains hardcoded default Memory-Mapped I/O (MMIO) addresses:

- `UART_ADDR` is set to `0x40600004ULL`
- `TIMER_ADDR` is set to `0x20003000ULL`

**You MUST modify these macros in the source code to match your specific CPU architecture's memory map.** If your behavioral simulation does not support peripherals at these addresses, the AXI/SRAM bus may hang while waiting for a `READY` signal.

**2. Output-Only Constraint:**

Currently, `testicg.cc` is an output-only implementation. It **does not support any program input functions** (such as `getchar` or `scanf`) due to space constraints and peripheral simplicity.

**3. Custom Trap Instruction:**

When the `main()` function returns `0`, the `start.S` script will catch it and execute a custom Fudan/NJU architecture trap instruction (`.word 0x0005006b`). This places the exit code in the `a0` register to notify the simulation framework (like NEMU) to halt gracefully.

## 📄 License

This project is licensed under the [MIT License](./LICENSE).