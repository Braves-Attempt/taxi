# SPDX-License-Identifier: MIT
#
# Copyright (c) 2014-2025 FPGA Ninja, LLC
#
# Authors:
# - Alex Forencich
#

# XDC constraints for the Xilinx VC709
# part: xc7vx690tffg1761-2

# General configuration
set_property CFGBVS GND                                [current_design]
set_property CONFIG_VOLTAGE 1.8                        [current_design]
set_property BITSTREAM.GENERAL.COMPRESS true           [current_design]
set_property BITSTREAM.CONFIG.UNUSEDPIN Pullup         [current_design]

# 200 MHz system clock (U51)
set_property -dict {LOC H19  IOSTANDARD DIFF_SSTL15_DCI} [get_ports clk_200mhz_p]
set_property -dict {LOC G18  IOSTANDARD DIFF_SSTL15_DCI} [get_ports clk_200mhz_n]
create_clock -period 5.0 -name clk_200mhz [get_ports clk_200mhz_p]

# User clock (U34)
#set_property -dict {LOC AL34 IOSTANDARD LVDS} [get_ports clk_user_p]
#set_property -dict {LOC AK34 IOSTANDARD LVDS} [get_ports clk_user_n]
#create_clock -period 6.4 -name clk_user [get_ports clk_user_p]

# User SMA clock (J31/J32)
#set_property -dict {LOC AJ32 IOSTANDARD LVDS} [get_ports clk_sma_p]
#set_property -dict {LOC AK32 IOSTANDARD LVDS} [get_ports clk_sma_n]
#create_clock -period 6.4 -name clk_sma [get_ports clk_sma_p]

# 233.33 MHz DDR3 MIG clock (U13)
#set_property -dict {LOC AY17 IOSTANDARD DIFF_SSTL15_DCI} [get_ports clk_233mhz_p]
#set_property -dict {LOC AY18 IOSTANDARD DIFF_SSTL15_DCI} [get_ports clk_233mhz_n]
#create_clock -period 4.285 -name clk_233mhz [get_ports clk_233mhz_p]

# EMC clock (U40)
#set_property -dict {LOC AP37 IOSTANDARD LVCMOS18} [get_ports emcclk]
#create_clock -period 1.25 -name emcclk [get_ports emcclk]

# LEDs
set_property -dict {LOC AM39 IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 12} [get_ports {led[0]}] ;# DS2
set_property -dict {LOC AN39 IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 12} [get_ports {led[1]}] ;# DS3
set_property -dict {LOC AR37 IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 12} [get_ports {led[2]}] ;# DS4
set_property -dict {LOC AT37 IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 12} [get_ports {led[3]}] ;# DS5
set_property -dict {LOC AR35 IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 12} [get_ports {led[4]}] ;# DS6
set_property -dict {LOC AP41 IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 12} [get_ports {led[5]}] ;# DS7
set_property -dict {LOC AP42 IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 12} [get_ports {led[6]}] ;# DS8
set_property -dict {LOC AU39 IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 12} [get_ports {led[7]}] ;# DS9

set_false_path -to [get_ports {led[*]}]
set_output_delay 0 [get_ports {led[*]}]

# Reset button
set_property -dict {LOC AV40 IOSTANDARD LVCMOS18} [get_ports reset] ;# from SW8

set_false_path -from [get_ports {reset}]
set_input_delay 0 [get_ports {reset}]

# Push buttons
set_property -dict {LOC AR40 IOSTANDARD LVCMOS18} [get_ports btnu] ;# from SW3
set_property -dict {LOC AW40 IOSTANDARD LVCMOS18} [get_ports btnl] ;# from SW7
set_property -dict {LOC AP40 IOSTANDARD LVCMOS18} [get_ports btnd] ;# from SW5
set_property -dict {LOC AU38 IOSTANDARD LVCMOS18} [get_ports btnr] ;# from SW4
set_property -dict {LOC AV39 IOSTANDARD LVCMOS18} [get_ports btnc] ;# from SW6

set_false_path -from [get_ports {btnu btnl btnd btnr btnc}]
set_input_delay 0 [get_ports {btnu btnl btnd btnr btnc}]

# DIP switches
set_property -dict {LOC AV30 IOSTANDARD LVCMOS18} [get_ports {sw[0]}] ;# from SW2.1
set_property -dict {LOC AY33 IOSTANDARD LVCMOS18} [get_ports {sw[1]}] ;# from SW2.2
set_property -dict {LOC BA31 IOSTANDARD LVCMOS18} [get_ports {sw[2]}] ;# from SW2.3
set_property -dict {LOC BA32 IOSTANDARD LVCMOS18} [get_ports {sw[3]}] ;# from SW2.4
set_property -dict {LOC AW30 IOSTANDARD LVCMOS18} [get_ports {sw[4]}] ;# from SW2.5
set_property -dict {LOC AY30 IOSTANDARD LVCMOS18} [get_ports {sw[5]}] ;# from SW2.6
set_property -dict {LOC BA30 IOSTANDARD LVCMOS18} [get_ports {sw[6]}] ;# from SW2.7
set_property -dict {LOC BB31 IOSTANDARD LVCMOS18} [get_ports {sw[7]}] ;# from SW2.8

set_false_path -from [get_ports {sw[*]}]
set_input_delay 0 [get_ports {sw[*]}]

# UART (U44 CP2103)
set_property -dict {LOC AU36 IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 8} [get_ports {uart_txd}] ;# U44.24 RXD_I
set_property -dict {LOC AU33 IOSTANDARD LVCMOS18} [get_ports {uart_rxd}] ;# U44.25 TXD_O
set_property -dict {LOC AT32 IOSTANDARD LVCMOS18} [get_ports {uart_rts}] ;# U44.23 RTS_O_B
set_property -dict {LOC AR34 IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 8} [get_ports {uart_cts}] ;# U44.22 CTS_I_B

set_false_path -to [get_ports {uart_txd uart_cts}]
set_output_delay 0 [get_ports {uart_txd uart_cts}]
set_false_path -from [get_ports {uart_rxd uart_rts}]
set_input_delay 0 [get_ports {uart_rxd uart_rts}]

# I2C interface
set_property -dict {LOC AT35 IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 8} [get_ports i2c_scl]
set_property -dict {LOC AU32 IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 8} [get_ports i2c_sda]
set_property -dict {LOC AY42 IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 8} [get_ports i2c_mux_reset]

set_false_path -to [get_ports {i2c_sda i2c_scl i2c_mux_reset}]
set_output_delay 0 [get_ports {i2c_sda i2c_scl i2c_mux_reset}]
set_false_path -from [get_ports {i2c_sda i2c_scl}]
set_input_delay 0 [get_ports {i2c_sda i2c_scl}]

# SFP+ Interfaces
# NOTE: modules 0 and 1 swapped relative to schematic net names to match board layout
set_property -dict {LOC AN2 } [get_ports {sfp_tx_p[0]}] ;# MGTHTXP2_113 GTHE2_CHANNEL_X1Y13 / GTHE2_COMMON_X1Y3
set_property -dict {LOC AN1 } [get_ports {sfp_tx_n[0]}] ;# MGTHTXN2_113 GTHE2_CHANNEL_X1Y13 / GTHE2_COMMON_X1Y3
set_property -dict {LOC AM8 } [get_ports {sfp_rx_p[0]}] ;# MGTHRXP2_113 GTHE2_CHANNEL_X1Y13 / GTHE2_COMMON_X1Y3
set_property -dict {LOC AM7 } [get_ports {sfp_rx_n[0]}] ;# MGTHRXN2_113 GTHE2_CHANNEL_X1Y13 / GTHE2_COMMON_X1Y3
set_property -dict {LOC AP4 } [get_ports {sfp_tx_p[1]}] ;# MGTHTXP3_113 GTHE2_CHANNEL_X1Y12 / GTHE2_COMMON_X1Y3
set_property -dict {LOC AP3 } [get_ports {sfp_tx_n[1]}] ;# MGTHTXN3_113 GTHE2_CHANNEL_X1Y12 / GTHE2_COMMON_X1Y3
set_property -dict {LOC AN6 } [get_ports {sfp_rx_p[1]}] ;# MGTHRXP3_113 GTHE2_CHANNEL_X1Y12 / GTHE2_COMMON_X1Y3
set_property -dict {LOC AN5 } [get_ports {sfp_rx_n[1]}] ;# MGTHRXN3_113 GTHE2_CHANNEL_X1Y12 / GTHE2_COMMON_X1Y3
set_property -dict {LOC AM4 } [get_ports {sfp_tx_p[2]}] ;# MGTHTXP1_113 GTHE2_CHANNEL_X1Y14 / GTHE2_COMMON_X1Y3
set_property -dict {LOC AM3 } [get_ports {sfp_tx_n[2]}] ;# MGTHTXN1_113 GTHE2_CHANNEL_X1Y14 / GTHE2_COMMON_X1Y3
set_property -dict {LOC AL6 } [get_ports {sfp_rx_p[2]}] ;# MGTHRXP1_113 GTHE2_CHANNEL_X1Y14 / GTHE2_COMMON_X1Y3
set_property -dict {LOC AL5 } [get_ports {sfp_rx_n[2]}] ;# MGTHRXN1_113 GTHE2_CHANNEL_X1Y14 / GTHE2_COMMON_X1Y3
set_property -dict {LOC AL2 } [get_ports {sfp_tx_p[3]}] ;# MGTHTXP0_113 GTHE2_CHANNEL_X1Y15 / GTHE2_COMMON_X1Y3
set_property -dict {LOC AL1 } [get_ports {sfp_tx_n[3]}] ;# MGTHTXN0_113 GTHE2_CHANNEL_X1Y15 / GTHE2_COMMON_X1Y3
set_property -dict {LOC AJ6 } [get_ports {sfp_rx_p[3]}] ;# MGTHRXP0_113 GTHE2_CHANNEL_X1Y15 / GTHE2_COMMON_X1Y3
set_property -dict {LOC AJ5 } [get_ports {sfp_rx_n[3]}] ;# MGTHRXN0_113 GTHE2_CHANNEL_X1Y15 / GTHE2_COMMON_X1Y3
set_property -dict {LOC AH8 } [get_ports sfp_mgt_refclk_p] ;# MGTREFCLK0P_113 from U24.28
set_property -dict {LOC AH7 } [get_ports sfp_mgt_refclk_n] ;# MGTREFCLK0N_113 from U24.29
# set_property -dict {LOC AK8 } [get_ports sma_mgt_refclk_p] ;# MGTREFCLK1P_113 from J25
# set_property -dict {LOC AK7 } [get_ports sma_mgt_refclk_n] ;# MGTREFCLK1N_113 from J26
#set_property -dict {LOC AW32 IOSTANDARD LVDS} [get_ports sfp_recclk_p] ;# to IC20.16
#set_property -dict {LOC AW33 IOSTANDARD LVDS} [get_ports sfp_recclk_n] ;# to IC20.17

set_property -dict {LOC AT36 IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 12} [get_ports si5324_rst]
set_property -dict {LOC AU34 IOSTANDARD LVCMOS18 PULLUP true} [get_ports si5324_int]

set_property -dict {LOC AA42 IOSTANDARD LVCMOS18 PULLUP true} [get_ports {sfp_mod_detect[0]}]
set_property -dict {LOC AB42 IOSTANDARD LVCMOS18 PULLUP true} [get_ports {sfp_mod_detect[1]}]
set_property -dict {LOC AC39 IOSTANDARD LVCMOS18 PULLUP true} [get_ports {sfp_mod_detect[2]}]
set_property -dict {LOC AC41 IOSTANDARD LVCMOS18 PULLUP true} [get_ports {sfp_mod_detect[3]}]
set_property -dict {LOC AB38 IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 12} [get_ports {sfp_rs[0][0]}]
set_property -dict {LOC AB39 IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 12} [get_ports {sfp_rs[0][1]}]
set_property -dict {LOC W40  IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 12} [get_ports {sfp_rs[1][0]}]
set_property -dict {LOC Y40  IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 12} [get_ports {sfp_rs[1][1]}]
set_property -dict {LOC AD42 IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 12} [get_ports {sfp_rs[2][0]}]
set_property -dict {LOC AE42 IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 12} [get_ports {sfp_rs[2][1]}]
set_property -dict {LOC AE39 IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 12} [get_ports {sfp_rs[3][0]}]
set_property -dict {LOC AE40 IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 12} [get_ports {sfp_rs[3][1]}]
set_property -dict {LOC AA40 IOSTANDARD LVCMOS18 PULLUP true} [get_ports {sfp_los[0]}]
set_property -dict {LOC Y39  IOSTANDARD LVCMOS18 PULLUP true} [get_ports {sfp_los[1]}]
set_property -dict {LOC AD38 IOSTANDARD LVCMOS18 PULLUP true} [get_ports {sfp_los[2]}]
set_property -dict {LOC AD40 IOSTANDARD LVCMOS18 PULLUP true} [get_ports {sfp_los[3]}]
set_property -dict {LOC Y42  IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 12} [get_ports {sfp_tx_disable[0]}]
set_property -dict {LOC AB41 IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 12} [get_ports {sfp_tx_disable[1]}]
set_property -dict {LOC AC38 IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 12} [get_ports {sfp_tx_disable[2]}]
set_property -dict {LOC AC40 IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 12} [get_ports {sfp_tx_disable[3]}]
set_property -dict {LOC AA39 IOSTANDARD LVCMOS18 PULLUP true} [get_ports {sfp_tx_fault[0]}]
set_property -dict {LOC Y38  IOSTANDARD LVCMOS18 PULLUP true} [get_ports {sfp_tx_fault[1]}]
set_property -dict {LOC AA41 IOSTANDARD LVCMOS18 PULLUP true} [get_ports {sfp_tx_fault[2]}]
set_property -dict {LOC AE38 IOSTANDARD LVCMOS18 PULLUP true} [get_ports {sfp_tx_fault[3]}]

# 156.25 MHz MGT reference clock
create_clock -period 6.4 -name sfp_mgt_refclk [get_ports sfp_mgt_refclk_p]

# 156.25 MHz MGT reference clock
#create_clock -period 6.4 -name sma_mgt_refclk [get_ports sma_mgt_refclk_p]

set_false_path -to [get_ports {si5324_rst}]
set_output_delay 0 [get_ports {si5324_rst}]
set_false_path -from [get_ports {si5324_int}]
set_input_delay 0 [get_ports {si5324_int}]

set_false_path -from [get_ports {sfp_mod_detect[*] sfp_los[*] sfp_tx_fault[*]}]
set_input_delay 0 [get_ports {sfp_mod_detect[*] sfp_los[*] sfp_tx_fault[*]}]
set_false_path -to [get_ports {sfp_rs[*][*] sfp_tx_disable[*]}]
set_output_delay 0 [get_ports {sfp_rs[*][*] sfp_tx_disable[*]}]

# PCIe Interface
#set_property -dict {LOC Y4   } [get_ports {pcie_rx_p[0]}] ;# MGTHTXP3_115 GTHE2_CHANNEL_X1Y23 / GTHE2_COMMON_X1Y5
#set_property -dict {LOC Y3   } [get_ports {pcie_rx_n[0]}] ;# MGTHTXN3_115 GTHE2_CHANNEL_X1Y23 / GTHE2_COMMON_X1Y5
#set_property -dict {LOC W2   } [get_ports {pcie_tx_p[0]}] ;# MGTHTXP3_115 GTHE2_CHANNEL_X1Y23 / GTHE2_COMMON_X1Y5
#set_property -dict {LOC W1   } [get_ports {pcie_tx_n[0]}] ;# MGTHTXN3_115 GTHE2_CHANNEL_X1Y23 / GTHE2_COMMON_X1Y5
#set_property -dict {LOC AA6  } [get_ports {pcie_rx_p[1]}] ;# MGTHTXP2_115 GTHE2_CHANNEL_X1Y22 / GTHE2_COMMON_X1Y5
#set_property -dict {LOC AA5  } [get_ports {pcie_rx_n[1]}] ;# MGTHTXN2_115 GTHE2_CHANNEL_X1Y22 / GTHE2_COMMON_X1Y5
#set_property -dict {LOC AA2  } [get_ports {pcie_tx_p[1]}] ;# MGTHTXP2_115 GTHE2_CHANNEL_X1Y22 / GTHE2_COMMON_X1Y5
#set_property -dict {LOC AA1  } [get_ports {pcie_tx_n[1]}] ;# MGTHTXN2_115 GTHE2_CHANNEL_X1Y22 / GTHE2_COMMON_X1Y5
#set_property -dict {LOC AB4  } [get_ports {pcie_rx_p[2]}] ;# MGTHTXP1_115 GTHE2_CHANNEL_X1Y21 / GTHE2_COMMON_X1Y5
#set_property -dict {LOC AB3  } [get_ports {pcie_rx_n[2]}] ;# MGTHTXN1_115 GTHE2_CHANNEL_X1Y21 / GTHE2_COMMON_X1Y5
#set_property -dict {LOC AC2  } [get_ports {pcie_tx_p[2]}] ;# MGTHTXP1_115 GTHE2_CHANNEL_X1Y21 / GTHE2_COMMON_X1Y5
#set_property -dict {LOC AC1  } [get_ports {pcie_tx_n[2]}] ;# MGTHTXN1_115 GTHE2_CHANNEL_X1Y21 / GTHE2_COMMON_X1Y5
#set_property -dict {LOC AC6  } [get_ports {pcie_rx_p[3]}] ;# MGTHTXP0_115 GTHE2_CHANNEL_X1Y20 / GTHE2_COMMON_X1Y5
#set_property -dict {LOC AC5  } [get_ports {pcie_rx_n[3]}] ;# MGTHTXN0_115 GTHE2_CHANNEL_X1Y20 / GTHE2_COMMON_X1Y5
#set_property -dict {LOC AE2  } [get_ports {pcie_tx_p[3]}] ;# MGTHTXP0_115 GTHE2_CHANNEL_X1Y20 / GTHE2_COMMON_X1Y5
#set_property -dict {LOC AE1  } [get_ports {pcie_tx_n[3]}] ;# MGTHTXN0_115 GTHE2_CHANNEL_X1Y20 / GTHE2_COMMON_X1Y5
#set_property -dict {LOC AD4  } [get_ports {pcie_rx_p[4]}] ;# MGTHTXP3_114 GTHE2_CHANNEL_X1Y19 / GTHE2_COMMON_X1Y4
#set_property -dict {LOC AD3  } [get_ports {pcie_rx_n[4]}] ;# MGTHTXN3_114 GTHE2_CHANNEL_X1Y19 / GTHE2_COMMON_X1Y4
#set_property -dict {LOC AG2  } [get_ports {pcie_tx_p[4]}] ;# MGTHTXP3_114 GTHE2_CHANNEL_X1Y19 / GTHE2_COMMON_X1Y4
#set_property -dict {LOC AG1  } [get_ports {pcie_tx_n[4]}] ;# MGTHTXN3_114 GTHE2_CHANNEL_X1Y19 / GTHE2_COMMON_X1Y4
#set_property -dict {LOC AE6  } [get_ports {pcie_rx_p[5]}] ;# MGTHTXP2_114 GTHE2_CHANNEL_X1Y18 / GTHE2_COMMON_X1Y4
#set_property -dict {LOC AE5  } [get_ports {pcie_rx_n[5]}] ;# MGTHTXN2_114 GTHE2_CHANNEL_X1Y18 / GTHE2_COMMON_X1Y4
#set_property -dict {LOC AH4  } [get_ports {pcie_tx_p[5]}] ;# MGTHTXP2_114 GTHE2_CHANNEL_X1Y18 / GTHE2_COMMON_X1Y4
#set_property -dict {LOC AH3  } [get_ports {pcie_tx_n[5]}] ;# MGTHTXN2_114 GTHE2_CHANNEL_X1Y18 / GTHE2_COMMON_X1Y4
#set_property -dict {LOC AF4  } [get_ports {pcie_rx_p[6]}] ;# MGTHTXP1_114 GTHE2_CHANNEL_X1Y17 / GTHE2_COMMON_X1Y4
#set_property -dict {LOC AF3  } [get_ports {pcie_rx_n[6]}] ;# MGTHTXN1_114 GTHE2_CHANNEL_X1Y17 / GTHE2_COMMON_X1Y4
#set_property -dict {LOC AJ2  } [get_ports {pcie_tx_p[6]}] ;# MGTHTXP1_114 GTHE2_CHANNEL_X1Y17 / GTHE2_COMMON_X1Y4
#set_property -dict {LOC AJ1  } [get_ports {pcie_tx_n[6]}] ;# MGTHTXN1_114 GTHE2_CHANNEL_X1Y17 / GTHE2_COMMON_X1Y4
#set_property -dict {LOC AG6  } [get_ports {pcie_rx_p[7]}] ;# MGTHTXP0_114 GTHE2_CHANNEL_X1Y16 / GTHE2_COMMON_X1Y4
#set_property -dict {LOC AG5  } [get_ports {pcie_rx_n[7]}] ;# MGTHTXN0_114 GTHE2_CHANNEL_X1Y16 / GTHE2_COMMON_X1Y4
#set_property -dict {LOC AK4  } [get_ports {pcie_tx_p[7]}] ;# MGTHTXP0_114 GTHE2_CHANNEL_X1Y16 / GTHE2_COMMON_X1Y4
#set_property -dict {LOC AK3  } [get_ports {pcie_tx_n[7]}] ;# MGTHTXN0_114 GTHE2_CHANNEL_X1Y16 / GTHE2_COMMON_X1Y4
#set_property -dict {LOC AB8  } [get_ports pcie_mgt_refclk_p] ;# MGTREFCLK1P_115
#set_property -dict {LOC AB7  } [get_ports pcie_mgt_refclk_n] ;# MGTREFCLK1N_115
#set_property -dict {LOC AV35 IOSTANDARD LVCMOS18 PULLUP true} [get_ports pcie_reset_n]

# 100 MHz MGT reference clock
#create_clock -period 10 -name pcie_mgt_refclk [get_ports pcie_mgt_refclk_p]

#set_false_path -from [get_ports {pcie_reset_n}]
#set_input_delay 0 [get_ports {pcie_reset_n}]
