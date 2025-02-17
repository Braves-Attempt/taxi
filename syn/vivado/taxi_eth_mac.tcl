# SPDX-License-Identifier: CERN-OHL-S-2.0
#
# Copyright (c) 2019-2025 FPGA Ninja, LLC
#
# Authors:
# - Alex Forencich
#

# Ethernet MAC timing constraints

foreach inst [get_cells -hier -regexp -filter {(ORIG_REF_NAME =~ "taxi_eth_mac_(1g|10g)(__\w+__\d+)?" ||
        REF_NAME =~ "taxi_eth_mac_(1g|10g)(__\w+__\d+)?")}] {
    puts "Inserting timing constraints for Ethernet MAC instance $inst"

    set sync_ffs [get_cells -quiet -hier -regexp ".*/mac_ctrl.tx_lfc_req_sync_reg_\[1234\]_reg" -filter "PARENT == $inst"]

    if {[llength $sync_ffs]} {
        set_property ASYNC_REG TRUE $sync_ffs

        set src_clk [get_clocks -of_objects [get_pins $inst/mac_ctrl.tx_lfc_req_sync_reg_1_reg/C]]

        set src_clk_period [if {[llength $src_clk]} {get_property -min PERIOD $src_clk} {expr 1.0}]

        set_max_delay -from [get_cells $inst/mac_ctrl.tx_lfc_req_sync_reg_1_reg] -to [get_cells $inst/mac_ctrl.tx_lfc_req_sync_reg_2_reg] -datapath_only $src_clk_period
    }

    set sync_ffs [get_cells -quiet -hier -regexp ".*/mac_ctrl.rx_lfc_ack_sync_reg_\[1234\]_reg" -filter "PARENT == $inst"]

    if {[llength $sync_ffs]} {
        set_property ASYNC_REG TRUE $sync_ffs

        set src_clk [get_clocks -of_objects [get_pins $inst/mac_ctrl.rx_lfc_ack_sync_reg_1_reg/C]]

        set src_clk_period [if {[llength $src_clk]} {get_property -min PERIOD $src_clk} {expr 1.0}]

        set_max_delay -from [get_cells $inst/mac_ctrl.rx_lfc_ack_sync_reg_1_reg] -to [get_cells $inst/mac_ctrl.rx_lfc_ack_sync_reg_2_reg] -datapath_only $src_clk_period
    }
}
