# SPDX-License-Identifier: CERN-OHL-S-2.0
#
# Copyright (c) 2025 FPGA Ninja, LLC
#
# Authors:
# - Alex Forencich
#

set base_name {taxi_eth_phy_25g_us_gth}

set preset {GTH-10GBASE-R}

set freerun_freq {125}
set line_rate {10.3125}
set refclk_freq {156.25}
set sec_line_rate {0}
set sec_refclk_freq $refclk_freq
set qpll_fracn [expr {int(fmod($line_rate*1000/2 / $refclk_freq, 1)*pow(2, 24))}]
set sec_qpll_fracn [expr {int(fmod($sec_line_rate*1000/2 / $sec_refclk_freq, 1)*pow(2, 24))}]
set user_data_width {64}
set int_data_width {32}
set rx_eq_mode {DFE}
set extra_ports [list]
set extra_pll_ports [list {qpll0lock_out}]
# channel polarity
lappend extra_ports txpolarity_in rxpolarity_in

set config [dict create]

dict set config TX_LINE_RATE $line_rate
dict set config TX_REFCLK_FREQUENCY $refclk_freq
dict set config TX_QPLL_FRACN_NUMERATOR $qpll_fracn
dict set config TX_USER_DATA_WIDTH $user_data_width
dict set config TX_INT_DATA_WIDTH $int_data_width
dict set config RX_LINE_RATE $line_rate
dict set config RX_REFCLK_FREQUENCY $refclk_freq
dict set config RX_QPLL_FRACN_NUMERATOR $qpll_fracn
dict set config RX_USER_DATA_WIDTH $user_data_width
dict set config RX_INT_DATA_WIDTH $int_data_width
dict set config RX_EQ_MODE $rx_eq_mode
if {$sec_line_rate != 0} {
    dict set config SECONDARY_QPLL_ENABLE true
    dict set config SECONDARY_QPLL_FRACN_NUMERATOR $sec_qpll_fracn
    dict set config SECONDARY_QPLL_LINE_RATE $sec_line_rate
    dict set config SECONDARY_QPLL_REFCLK_FREQUENCY $sec_refclk_freq
} else {
    dict set config SECONDARY_QPLL_ENABLE false
}
dict set config ENABLE_OPTIONAL_PORTS $extra_ports
dict set config LOCATE_COMMON {CORE}
dict set config LOCATE_RESET_CONTROLLER {CORE}
dict set config LOCATE_TX_USER_CLOCKING {CORE}
dict set config LOCATE_RX_USER_CLOCKING {CORE}
dict set config LOCATE_USER_DATA_WIDTH_SIZING {CORE}
dict set config FREERUN_FREQUENCY $freerun_freq
dict set config DISABLE_LOC_XDC {1}

proc create_gtwizard_ip {name preset config} {
    create_ip -name gtwizard_ultrascale -vendor xilinx.com -library ip -module_name $name
    set ip [get_ips $name]
    set_property CONFIG.preset $preset $ip
    set config_list {}
    dict for {name value} $config {
        lappend config_list "CONFIG.${name}" $value
    }
    set_property -dict $config_list $ip
}

# variant with channel and common
dict set config ENABLE_OPTIONAL_PORTS [concat $extra_pll_ports $extra_ports]
dict set config LOCATE_COMMON {CORE}

create_gtwizard_ip "${base_name}_full" $preset $config

# variant with channel only
dict set config ENABLE_OPTIONAL_PORTS $extra_ports
dict set config LOCATE_COMMON {EXAMPLE_DESIGN}

create_gtwizard_ip "${base_name}_channel" $preset $config
