# Taxi Example Design for Alveo

## Introduction

This example design targets the Xilinx Alveo series.

The design places looped-back MACs on the Ethernet ports, as well as XFCP on the USB UART for monitoring and control.

*  USB UART
    *  XFCP (3 Mbaud)
*  DSFP/QSFP28
    *  Looped-back 10GBASE-R or 25GBASE-R MACs via GTY transceivers

## Board details

*  FPGA
   *  AU45N/SN1000: xcu26-vsva1365-2LV-e
   *  AU50: xcu50-fsvh2104-2-e
   *  AU55C: xcu55c-fsvh2892-2L-e
   *  AU55N/C1100: xcu55n-fsvh2892-2L-e
   *  AU200: xcu200-fsgd2104-2-e
   *  AU250: xcu250-fsgd2104-2-e
   *  AU280: xcu280-fsvh2892-2L-e
   *  VCU1525: xcvu9p-fsgd2104-2L-e
   *  X3/X3522: xcux35-vsva1365-3-e
*  USB UART
   *  AU45N/SN1000: FTDI FT4232H (DMB-2)
   *  AU50: FTDI FT4232H (3 via DMB-1)
   *  AU55C: FTDI FT4232H (2 onboard, all 3 via DMB-1)
   *  AU55N/C1100: FTDI FT4232H (2 onboard, all 3 via DMB-1)
   *  AU200: FTDI FT4232H
   *  AU250: FTDI FT4232H
   *  AU280: FTDI FT4232H
   *  VCU1525: FTDI FT4232H
   *  X3/X3522: FTDI FT4232H (DMB-2)
*  25GBASE-R PHY: Soft PCS with GTY transceivers

## Licensing

*  Toolchain
    *  Vivado Standard (enterprise license not required)
*  IP
    *  No licensed vendor IP or 3rd party IP

## How to build

Run `make` in the appropriate `fpga*` subdirectory to build the bitstream.  Ensure that the Xilinx Vivado toolchain components are in PATH.

## How to test

Run `make program` to program the board with Vivado.

To test the looped-back MAC, it is recommended to use a network tester like the Viavi T-BERD 5800 that supports basic layer 2 tests with a loopback.  Do not connect the looped-back MAC to a network as the reflected packets may cause problems.
