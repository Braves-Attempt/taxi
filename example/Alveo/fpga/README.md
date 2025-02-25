# Taxi Example Design for Alveo

## Introduction

This example design targets the Xilinx Alveo series.

The design places looped-back MACs on the Ethernet ports as well as a looped-back UART on on the USB UART connections.

* USB UART
  * Looped-back UART
* DSFP/QSFP28
  * Looped-back 10GBASE-R or 25GBASE-R MACs via GTY transceivers

## Board details

* FPGA
  * AU45N/SN1000: xcu26-vsva1365-2LV-e
  * AU50: xcu50-fsvh2104-2-e
  * AU55C: xcu55c-fsvh2892-2L-e
  * AU55N/C1100: xcu55n-fsvh2892-2L-e
  * AU200: xcu200-fsgd2104-2-e
  * AU250: xcu250-fsgd2104-2-e
  * AU280: xcu280-fsvh2892-2L-e
  * VCU1525: xcvu9p-fsgd2104-2L-e
  * X3/X3522: xcux35-vsva1365-3-e
* 25GBASE-R PHY: Soft PCS with GTY transceivers

## Licensing

* Toolchain
  * Vivado Standard (enterprise license not required)
* IP
  * No licensed vendor IP or 3rd party IP

## How to build

Run `make` in the appropriate `fpga*` subdirectory to build the bitstream.  Ensure that the Xilinx Vivado toolchain components are in PATH.

## How to test

Run `make program` to program the board with Vivado.

To test the looped-back UART, use any serial terminal software like minicom, screen, etc.  The looped-back UART will echo typed text back without modification.

To test the looped-back MAC, it is recommended to use a network tester like the Viavi T-BERD 5800 that supports basic layer 2 tests with a loopback.  Do not connect the looped-back MAC to a network as the reflected packets may cause problems.
