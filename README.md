# Taxi Transport Library

[![Regression Tests](https://github.com/fpganinja/taxi/actions/workflows/regression-tests.yml/badge.svg)](https://github.com/fpganinja/taxi/actions/workflows/regression-tests.yml)

AXI, AXI stream, Ethernet, and PCIe components in System Verilog.

GitHub repository: https://github.com/fpganinja/taxi

## Introduction

The goal of the Taxi transport library is to provide a set of performant, easy-to-use building blocks in modern System Verilog facilitating data transport and interfacing, both internally via AXI and AXI stream, and externally via Ethernet, PCI express, UART, and I2C.  The building blocks are accompanied by testbenches and simulation models utilizing Cocotb and Verilator.

This library is currently under development; more components will be added over time as they are developed.

## License

Taxi is provided by FPGA Ninja, LLC under either the CERN Open Hardware Licence Version 2 - Strongly Reciprocal (CERN-OHL-S 2.0), or a paid commercial license.  Contact info@fpga.ninja for commercial use.  Note that some components may be provided under less restrictive licenses (e.g. example designs).

Under the strongly-reciprocal CERN OHL, you must provide the source code of the entire digital design upon request, including all modifications, extensions, and customizations, such that the design can be rebuilt.  If this is not an acceptable restriction for your product, please contact info@fpga.ninja to inquire about a commercial license without this requirement.  License fees support the continued development and maintenance of this project and related projects.

To facilitate the dual-license model, contributions to the project can only be accepted under a contributor license agreement.

## Components

*  AXI stream
    *  SV interface for AXI stream
    *  Register slice
    *  Width converter
    *  Synchronous FIFO
    *  Asynchronous FIFO
    *  Combined FIFO + width converter
    *  Combined async FIFO + width converter
    *  Broadcaster
    *  COBS encoder
    *  COBS decoder
    *  Pipeline register
    *  Pipeline FIFO
*  Ethernet
    *  10/100 MII MAC
    *  10/100 MII MAC + FIFO
    *  10/100/1000 GMII MAC
    *  10/100/1000 GMII MAC + FIFO
    *  10/100/1000 RGMII MAC
    *  10/100/1000 RGMII MAC + FIFO
    *  1G MAC
    *  1G MAC + FIFO
    *  10G MAC
    *  10G MAC + FIFO
    *  10G MAC/PHY
    *  10G MAC/PHY + FIFO
    *  10G PHY
    *  MII PHY interface
    *  GMII PHY interface
    *  RGMII PHY interface
*  General input/output
    *  Switch debouncer
    *  Generic IDDR
    *  Generic ODDR
    *  Source-synchronous DDR input
    *  Source-synchronous DDR differential input
    *  Source-synchronous DDR output
    *  Source-synchronous DDR differential output
    *  Source-synchronous SDR input
    *  Source-synchronous SDR differential input
    *  Source-synchronous SDR output
    *  Source-synchronous SDR differential output
*  Linear-feedback shift register
    *  Parametrizable combinatorial LFSR/CRC module
    *  CRC computation module
    *  PRBS generator
    *  PRBS checker
    *  LFSR self-synchronizing scrambler
    *  LFSR self-synchronizing descrambler
*  Low-speed serial
    *  UART
*  Primitives
    *  Arbiter
    *  Priority encoder
*  Precision Time Protocol (PTP)
    *  PTP clock
    *  PTP CDC
    *  PTP period output
    *  PTP TD leaf clock
    *  PTP TD PHC
    *  PTP TD relative-to-ToD converter
*  Synchronization primitives
    *  Reset synchronizer
    *  Signal synchronizer

## Example designs

Example designs are provided for several different FPGA boards, showcasing many of the capabilities of this library.  Building the example designs will require the appropriate vendor toolchain and may also require tool and IP licenses.

*  Digilent Arty A7 (Xilinx Artix 7 XC7A35T)
*  Xilinx KC705 (Xilinx Kintex 7 XC7K325T)

## Testing

Running the included testbenches requires [cocotb](https://github.com/cocotb/cocotb), [cocotbext-axi](https://github.com/alexforencich/cocotbext-axi), [cocotbext-eth](https://github.com/alexforencich/cocotbext-eth), [cocotbext-uart](https://github.com/alexforencich/cocotbext-uart), [cocotbext-pcie](https://github.com/alexforencich/cocotbext-pcie), and [Verilator](https://www.veripool.org/verilator/).  The testbenches can be run with pytest directly (requires [cocotb-test](https://github.com/themperek/cocotb-test)), pytest via tox, or via cocotb makefiles.
