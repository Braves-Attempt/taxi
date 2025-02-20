# SPDX-License-Identifier: MIT
#
# Copyright (c) 2025 FPGA Ninja, LLC
#
# Authors:
# - Alex Forencich
#

# XDC constraints for the HiTech Global HTG-9200 board
# part: xcvu9p-flgb2104-2-e
# part: xcvu13p-fhgb2104-2-e

# General configuration
set_property CFGBVS GND                                [current_design]
set_property CONFIG_VOLTAGE 1.8                        [current_design]
set_property BITSTREAM.GENERAL.COMPRESS true           [current_design]
set_property BITSTREAM.CONFIG.EXTMASTERCCLK_EN {DIV-1} [current_design]
set_property BITSTREAM.CONFIG.SPI_32BIT_ADDR YES       [current_design]
set_property BITSTREAM.CONFIG.SPI_BUSWIDTH 8           [current_design]
set_property BITSTREAM.CONFIG.SPI_FALL_EDGE YES        [current_design]
set_property BITSTREAM.CONFIG.OVERTEMPSHUTDOWN Enable  [current_design]

# System clocks
# DDR4 clocks from U37 (200 MHz)
#set_property -dict {LOC BA34 IOSTANDARD DIFF_SSTL12} [get_ports sys_clk_ddr4_a_p]
#set_property -dict {LOC BB34 IOSTANDARD DIFF_SSTL12} [get_ports sys_clk_ddr4_a_n]
#create_clock -period 5.000 -name sys_clk_ddr4_a [get_ports sys_clk_ddr4_a_p]

# refclk from U39 (156.25 MHz)
set_property -dict {LOC AW28 IOSTANDARD LVDS} [get_ports ref_clk_p]
set_property -dict {LOC AY28 IOSTANDARD LVDS} [get_ports ref_clk_n]
create_clock -period 6.400 -name ref_clk [get_ports ref_clk_p]

# LEDs
set_property -dict {LOC AP28 IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 8} [get_ports {led[0]}]
set_property -dict {LOC AN28 IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 8} [get_ports {led[1]}]
set_property -dict {LOC AP26 IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 8} [get_ports {led[2]}]
set_property -dict {LOC AP25 IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 8} [get_ports {led[3]}]
set_property -dict {LOC AR28 IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 8} [get_ports {led[4]}]
set_property -dict {LOC AR27 IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 8} [get_ports {led[5]}]
set_property -dict {LOC AT28 IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 8} [get_ports {led[6]}]
set_property -dict {LOC AR25 IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 8} [get_ports {led[7]}]

set_false_path -to [get_ports {led[*]}]
set_output_delay 0 [get_ports {led[*]}]

# Push buttons
set_property -dict {LOC AJ34 IOSTANDARD LVCMOS12} [get_ports {btn[0]}]
set_property -dict {LOC AK32 IOSTANDARD LVCMOS12} [get_ports {btn[1]}]

set_false_path -from [get_ports {btn[*]}]
set_input_delay 0 [get_ports {btn[*]}]

# DIP switches
set_property -dict {LOC BF33 IOSTANDARD LVCMOS12} [get_ports {sw[0]}]
set_property -dict {LOC AK27 IOSTANDARD LVCMOS12} [get_ports {sw[1]}]
set_property -dict {LOC AR32 IOSTANDARD LVCMOS12} [get_ports {sw[2]}]
set_property -dict {LOC AR31 IOSTANDARD LVCMOS12} [get_ports {sw[3]}]
set_property -dict {LOC AT32 IOSTANDARD LVCMOS12} [get_ports {sw[4]}]
set_property -dict {LOC AW30 IOSTANDARD LVCMOS12} [get_ports {sw[5]}]
set_property -dict {LOC BC32 IOSTANDARD LVCMOS12} [get_ports {sw[6]}]
set_property -dict {LOC BC33 IOSTANDARD LVCMOS12} [get_ports {sw[7]}]

set_false_path -from [get_ports {sw[*]}]
set_input_delay 0 [get_ports {sw[*]}]

# UART
set_property -dict {LOC R15  IOSTANDARD LVCMOS18} [get_ports uart_txd]
set_property -dict {LOC P15  IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 8} [get_ports uart_rxd]
set_property -dict {LOC L15  IOSTANDARD LVCMOS18} [get_ports uart_rts]
set_property -dict {LOC D14  IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 8} [get_ports uart_cts]
set_property -dict {LOC P16  IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 8} [get_ports uart_rst_n]

set_false_path -to [get_ports {uart_rxd uart_cts uart_rst_n}]
set_output_delay 0 [get_ports {uart_rxd uart_cts uart_rst_n}]
set_false_path -from [get_ports {uart_txd uart_rts}]
set_input_delay 0 [get_ports {uart_txd uart_rts}]

# I2C
set_property -dict {LOC AV28 IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 8} [get_ports i2c_main_scl]
set_property -dict {LOC AU27 IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 8} [get_ports i2c_main_sda]
set_property -dict {LOC AV27 IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 8} [get_ports i2c_main_rst_n]

set_false_path -to [get_ports {i2c_main_sda i2c_main_scl i2c_main_rst_n}]
set_output_delay 0 [get_ports {i2c_main_sda i2c_main_scl i2c_main_rst_n}]
set_false_path -from [get_ports {i2c_main_sda i2c_main_scl}]
set_input_delay 0 [get_ports {i2c_main_sda i2c_main_scl}]

# Gigabit Ethernet RGMII PHY
set_property -dict {LOC G20  IOSTANDARD LVCMOS18} [get_ports {phy_rx_clk}] ;# from U2.43 // MAYBE
set_property -dict {LOC A20  IOSTANDARD LVCMOS18} [get_ports {phy_rxd[0]}] ;# from U2.44
set_property -dict {LOC D21  IOSTANDARD LVCMOS18} [get_ports {phy_rxd[1]}] ;# from U2.45
set_property -dict {LOC E21  IOSTANDARD LVCMOS18} [get_ports {phy_rxd[2]}] ;# from U2.46
set_property -dict {LOC C21  IOSTANDARD LVCMOS18} [get_ports {phy_rxd[3]}] ;# from U2.47
set_property -dict {LOC B21  IOSTANDARD LVCMOS18} [get_ports {phy_rx_ctl}] ;# from U2.53
set_property -dict {LOC B20  IOSTANDARD LVCMOS18 SLEW FAST DRIVE 12} [get_ports {phy_tx_clk}] ;# from U2.40
set_property -dict {LOC D20  IOSTANDARD LVCMOS18 SLEW FAST DRIVE 12} [get_ports {phy_txd[0]}] ;# from U2.38
set_property -dict {LOC A19  IOSTANDARD LVCMOS18 SLEW FAST DRIVE 12} [get_ports {phy_txd[1]}] ;# from U2.37
set_property -dict {LOC B19  IOSTANDARD LVCMOS18 SLEW FAST DRIVE 12} [get_ports {phy_txd[2]}] ;# from U2.36
set_property -dict {LOC E20  IOSTANDARD LVCMOS18 SLEW FAST DRIVE 12} [get_ports {phy_txd[3]}] ;# from U2.35
set_property -dict {LOC G21  IOSTANDARD LVCMOS18 SLEW FAST DRIVE 12} [get_ports {phy_tx_ctl}] ;# from U2.52
#set_property -dict {LOC G19  IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 12} [get_ports {phy_mdio}] ;# from U2.21
#set_property -dict {LOC A18  IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 12} [get_ports {phy_mdc}] ;# from U2.20

create_clock -period 8.000 -name {phy_rx_clk} [get_ports {phy_rx_clk}]

#set_false_path -to [get_ports {phy_mdio phy_mdc}]
#set_output_delay 0 [get_ports {phy_mdio phy_mdc}]
#set_false_path -from [get_ports {phy_mdio}]
#set_input_delay 0 [get_ports {phy_mdio}]

# QSPI flash
#set_property -dict {LOC AM26 IOSTANDARD LVCMOS18 DRIVE 8} [get_ports {qspi_1_dq[0]}]
#set_property -dict {LOC AN26 IOSTANDARD LVCMOS18 DRIVE 8} [get_ports {qspi_1_dq[1]}]
#set_property -dict {LOC AL25 IOSTANDARD LVCMOS18 DRIVE 8} [get_ports {qspi_1_dq[2]}]
#set_property -dict {LOC AM25 IOSTANDARD LVCMOS18 DRIVE 8} [get_ports {qspi_1_dq[3]}]
#set_property -dict {LOC BF27 IOSTANDARD LVCMOS18 DRIVE 8} [get_ports {qspi_1_cs_n}]

#set_false_path -to [get_ports {qspi_1_dq[*] qspi_1_cs}]
#set_output_delay 0 [get_ports {qspi_1_dq[*] qspi_1_cs}]
#set_false_path -from [get_ports {qspi_1_dq}]
#set_input_delay 0 [get_ports {qspi_1_dq}]
