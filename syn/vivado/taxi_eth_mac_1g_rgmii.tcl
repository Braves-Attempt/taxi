# SPDX-License-Identifier: CERN-OHL-S-2.0
#
# Copyright (c) 2019-2025 FPGA Ninja, LLC
#
# Authors:
# - Alex Forencich
#

# RGMII Gigabit Ethernet MAC timing constraints

foreach inst [get_cells -hier -regexp -filter {(ORIG_REF_NAME =~ "taxi_eth_mac_1g_rgmii(__\w+__\d+)?" ||
        REF_NAME =~ "taxi_eth_mac_1g_rgmii(__\w+__\d+)?")}] {
    puts "Inserting timing constraints for taxi_eth_mac_1g_rgmii instance $inst"

    set select_ffs [get_cells -hier -regexp ".*/tx_mii_select_sync_reg\\\[\\d\\\]" -filter "PARENT == $inst"]

    if {[llength $select_ffs]} {
        set_property ASYNC_REG TRUE $select_ffs

        set src_clk [get_clocks -of_objects [get_pins $inst/mii_select_reg_reg/C]]

        set src_clk_period [if {[llength $src_clk]} {get_property -min PERIOD $src_clk} {expr 8.0}]

        set_max_delay -from [get_cells $inst/mii_select_reg_reg] -to [get_cells $inst/tx_mii_select_sync_reg[0]] -datapath_only $src_clk_period
    }

    set select_ffs [get_cells -hier -regexp ".*/rx_mii_select_sync_reg\\\[\\d\\\]" -filter "PARENT == $inst"]

    if {[llength $select_ffs]} {
        set_property ASYNC_REG TRUE $select_ffs

        set src_clk [get_clocks -of_objects [get_pins $inst/mii_select_reg_reg/C]]

        set src_clk_period [if {[llength $src_clk]} {get_property -min PERIOD $src_clk} {expr 8.0}]

        set_max_delay -from [get_cells $inst/mii_select_reg_reg] -to [get_cells $inst/rx_mii_select_sync_reg[0]] -datapath_only $src_clk_period
    }

    set prescale_ffs [get_cells -hier -regexp ".*/rx_prescale_sync_reg\\\[\\d\\\]" -filter "PARENT == $inst"]

    if {[llength $prescale_ffs]} {
        set_property ASYNC_REG TRUE $prescale_ffs

        set src_clk [get_clocks -of_objects [get_pins $inst/rx_prescale_reg[2]/C]]

        set src_clk_period [if {[llength $src_clk]} {get_property -min PERIOD $src_clk} {expr 8.0}]

        set_max_delay -from [get_cells $inst/rx_prescale_reg[2]] -to [get_cells $inst/rx_prescale_sync_reg[0]] -datapath_only $src_clk_period
    }
}
