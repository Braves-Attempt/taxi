# Taxi Example Design for VCU108

## Introduction

This example design targets the Xilinx VCU108 FPGA board.

The design places a looped-back MAC on the BASE-T port as well as a looped-back UART on on the USB UART connection.

*  USB UART
    *  Looped-back UART
*  RJ-45 Ethernet port with Marvell 88E1111 PHY
    *  Looped-back MAC via SGMII via Xilinx PCS/PMA core and LVDS IOSERDES

## Board details

*  FPGA: xcvu095-ffva2104-2-e
*  1000BASE-T PHY: Marvell 88E1111 via SGMII

## How to build

Run `make` in the appropriate `fpga*` subdirectory to build the bitstream.  Ensure that the Xilinx Vivado toolchain components are in PATH.

## How to test

Run `make program` to program the board with Vivado.

To test the looped-back UART, use any serial terminal software like minicom, screen, etc.  The looped-back UART will echo typed text back without modification.

To test the looped-back MAC, it is recommended to use a network tester like the Viavi T-BERD 5800 that supports basic layer 2 tests with a loopback.  Do not connect the looped-back MAC to a network as the reflected packets may cause problems.
