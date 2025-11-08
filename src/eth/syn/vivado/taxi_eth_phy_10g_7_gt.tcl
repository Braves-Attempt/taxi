# SPDX-License-Identifier: CERN-OHL-S-2.0
#
# Copyright (c) 2025 FPGA Ninja, LLC
#
# Authors:
# - Alex Forencich
#

# 7-series 10GBASE-R PHY+GT timing constraints

foreach inst [get_cells -hier -regexp -filter {(ORIG_REF_NAME =~ "taxi_eth_phy_10g_7_gt(__\w+__\d+)?" ||
        REF_NAME =~ "taxi_eth_phy_10g_7_gt(__\w+__\d+)?")}] {
    puts "Inserting timing constraints for 7-series 10GBASE-R PHY+GT instance $inst"

    create_clock -period 3.10303 [get_pins -filter {REF_PIN_NAME=~*TXOUTCLK} -of_objects [get_cells $inst/xcvr.gthe2_i]]
    create_clock -period 6.4 [get_pins -filter {REF_PIN_NAME=~*TXOUTCLKFABRIC} -of_objects [get_cells $inst/xcvr.gthe2_i]]
    create_clock -period 3.10303 [get_pins -filter {REF_PIN_NAME=~*RXOUTCLK} -of_objects [get_cells $inst/xcvr.gthe2_i]]
    create_clock -period 6.4 [get_pins -filter {REF_PIN_NAME=~*RXOUTCLKFABRIC} -of_objects [get_cells $inst/xcvr.gthe2_i]]
}
