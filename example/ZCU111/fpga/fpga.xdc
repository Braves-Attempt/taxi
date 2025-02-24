# SPDX-License-Identifier: MIT
#
# Copyright (c) 2025 FPGA Ninja, LLC
#
# Authors:
# - Alex Forencich
#

# XDC constraints for the Xilinx ZCU111 board
# part: xczu28dr-ffvg1517-2-e

# General configuration
set_property BITSTREAM.GENERAL.COMPRESS true           [current_design]

# System clocks
# 125 MHz
set_property -dict {LOC AL17 IOSTANDARD LVDS} [get_ports clk_125mhz_p]
set_property -dict {LOC AM17 IOSTANDARD LVDS} [get_ports clk_125mhz_n]
create_clock -period 8.000 -name clk_125mhz [get_ports clk_125mhz_p]

# 100 MHz
#set_property -dict {LOC AM15 IOSTANDARD LVDS} [get_ports clk_100mhz_p]
#set_property -dict {LOC AN15 IOSTANDARD LVDS} [get_ports clk_100mhz_n]
#create_clock -period 10.000 -name clk_100mhz [get_ports clk_100mhz_p]

# LEDs
set_property -dict {LOC AR13 IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 8} [get_ports {led[0]}] ;# DS11
set_property -dict {LOC AP13 IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 8} [get_ports {led[1]}] ;# DS12
set_property -dict {LOC AR16 IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 8} [get_ports {led[2]}] ;# DS13
set_property -dict {LOC AP16 IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 8} [get_ports {led[3]}] ;# DS14
set_property -dict {LOC AP15 IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 8} [get_ports {led[4]}] ;# DS15
set_property -dict {LOC AN16 IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 8} [get_ports {led[5]}] ;# DS16
set_property -dict {LOC AN17 IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 8} [get_ports {led[6]}] ;# DS17
set_property -dict {LOC AV15 IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 8} [get_ports {led[7]}] ;# DS18

set_false_path -to [get_ports {led[*]}]
set_output_delay 0 [get_ports {led[*]}]

# Reset button
set_property -dict {LOC AF15 IOSTANDARD LVCMOS18} [get_ports reset] ;# SW15

set_false_path -from [get_ports {reset}]
set_input_delay 0 [get_ports {reset}]

# Push buttons
set_property -dict {LOC AW3  IOSTANDARD LVCMOS18} [get_ports btnu] ;# SW9
set_property -dict {LOC AW4  IOSTANDARD LVCMOS18} [get_ports btnl] ;# SW12
set_property -dict {LOC E8   IOSTANDARD LVCMOS18} [get_ports btnd] ;# SW13
set_property -dict {LOC AW6  IOSTANDARD LVCMOS18} [get_ports btnr] ;# SW10
set_property -dict {LOC AW5  IOSTANDARD LVCMOS18} [get_ports btnc] ;# SW11

set_false_path -from [get_ports {btnu btnl btnd btnr btnc}]
set_input_delay 0 [get_ports {btnu btnl btnd btnr btnc}]

# DIP switches
set_property -dict {LOC AF16 IOSTANDARD LVCMOS18} [get_ports {sw[0]}] ;# SW14.8
set_property -dict {LOC AF17 IOSTANDARD LVCMOS18} [get_ports {sw[1]}] ;# SW14.7
set_property -dict {LOC AH15 IOSTANDARD LVCMOS18} [get_ports {sw[2]}] ;# SW14.6
set_property -dict {LOC AH16 IOSTANDARD LVCMOS18} [get_ports {sw[3]}] ;# SW14.5
set_property -dict {LOC AH17 IOSTANDARD LVCMOS18} [get_ports {sw[4]}] ;# SW14.4
set_property -dict {LOC AG17 IOSTANDARD LVCMOS18} [get_ports {sw[5]}] ;# SW14.3
set_property -dict {LOC AJ15 IOSTANDARD LVCMOS18} [get_ports {sw[6]}] ;# SW14.2
set_property -dict {LOC AJ16 IOSTANDARD LVCMOS18} [get_ports {sw[7]}] ;# SW14.1

set_false_path -from [get_ports {sw[*]}]
set_input_delay 0 [get_ports {sw[*]}]

# PMOD0
#set_property -dict {LOC C17  IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 8} [get_ports {pmod0[0]}] ;# J48.1
#set_property -dict {LOC M18  IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 8} [get_ports {pmod0[1]}] ;# J48.3
#set_property -dict {LOC H16  IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 8} [get_ports {pmod0[2]}] ;# J48.5
#set_property -dict {LOC H17  IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 8} [get_ports {pmod0[3]}] ;# J48.7
#set_property -dict {LOC J16  IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 8} [get_ports {pmod0[4]}] ;# J48.2
#set_property -dict {LOC K16  IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 8} [get_ports {pmod0[5]}] ;# J48.4
#set_property -dict {LOC H15  IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 8} [get_ports {pmod0[6]}] ;# J48.6
#set_property -dict {LOC J15  IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 8} [get_ports {pmod0[7]}] ;# J48.8

#set_false_path -to [get_ports {pmod0[*]}]
#set_output_delay 0 [get_ports {pmod0[*]}]

# PMOD1
#set_property -dict {LOC L14  IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 8} [get_ports {pmod1[0]}] ;# J49.1
#set_property -dict {LOC L15  IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 8} [get_ports {pmod1[1]}] ;# J49.3
#set_property -dict {LOC M13  IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 8} [get_ports {pmod1[2]}] ;# J49.5
#set_property -dict {LOC N13  IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 8} [get_ports {pmod1[3]}] ;# J49.7
#set_property -dict {LOC M15  IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 8} [get_ports {pmod1[4]}] ;# J49.2
#set_property -dict {LOC N15  IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 8} [get_ports {pmod1[5]}] ;# J49.4
#set_property -dict {LOC M14  IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 8} [get_ports {pmod1[6]}] ;# J49.6
#set_property -dict {LOC N14  IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 8} [get_ports {pmod1[7]}] ;# J49.8

#set_false_path -to [get_ports {pmod1[*]}]
#set_output_delay 0 [get_ports {pmod1[*]}]

# UART
set_property -dict {LOC AU15 IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 8} [get_ports uart_txd]
set_property -dict {LOC AT15 IOSTANDARD LVCMOS18} [get_ports uart_rxd]
set_property -dict {LOC AU14 IOSTANDARD LVCMOS18} [get_ports uart_rts]
set_property -dict {LOC AT14 IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 8} [get_ports uart_cts]

set_false_path -to [get_ports {uart_txd uart_cts}]
set_output_delay 0 [get_ports {uart_txd uart_cts}]
set_false_path -from [get_ports {uart_rxd uart_rts}]
set_input_delay 0 [get_ports {uart_rxd uart_rts}]


# I2C interfaces
#set_property -dict {LOC AT16 IOSTANDARD LVCMOS33 SLEW SLOW DRIVE 8} [get_ports i2c0_scl]
#set_property -dict {LOC AW16 IOSTANDARD LVCMOS33 SLEW SLOW DRIVE 8} [get_ports i2c0_sda]
#set_property -dict {LOC AH19 IOSTANDARD LVCMOS33 SLEW SLOW DRIVE 8} [get_ports i2c1_scl]
#set_property -dict {LOC AL21 IOSTANDARD LVCMOS33 SLEW SLOW DRIVE 8} [get_ports i2c1_sda]

#set_false_path -to [get_ports {i2c1_sda i2c1_scl}]
#set_output_delay 0 [get_ports {i2c1_sda i2c1_scl}]
#set_false_path -from [get_ports {i2c1_sda i2c1_scl}]
#set_input_delay 0 [get_ports {i2c1_sda i2c1_scl}]

# SFP28 Interface
set_property -dict {LOC AA38} [get_ports {sfp_rx_p[0]}] ;# MGTYRXP0_128 GTYE4_CHANNEL_X1Y12 / GTYE4_COMMON_X1Y3
set_property -dict {LOC AA39} [get_ports {sfp_rx_n[0]}] ;# MGTYRXN0_128 GTYE4_CHANNEL_X1Y12 / GTYE4_COMMON_X1Y3
set_property -dict {LOC Y35 } [get_ports {sfp_tx_p[0]}] ;# MGTYTXP0_128 GTYE4_CHANNEL_X1Y12 / GTYE4_COMMON_X1Y3
set_property -dict {LOC Y36 } [get_ports {sfp_tx_n[0]}] ;# MGTYTXN0_128 GTYE4_CHANNEL_X1Y12 / GTYE4_COMMON_X1Y3
set_property -dict {LOC W38 } [get_ports {sfp_rx_p[1]}] ;# MGTYRXP1_128 GTYE4_CHANNEL_X1Y13 / GTYE4_COMMON_X1Y3
set_property -dict {LOC W39 } [get_ports {sfp_rx_n[1]}] ;# MGTYRXN1_128 GTYE4_CHANNEL_X1Y13 / GTYE4_COMMON_X1Y3
set_property -dict {LOC V35 } [get_ports {sfp_tx_p[1]}] ;# MGTYTXP1_128 GTYE4_CHANNEL_X1Y13 / GTYE4_COMMON_X1Y3
set_property -dict {LOC V36 } [get_ports {sfp_tx_n[1]}] ;# MGTYTXN1_128 GTYE4_CHANNEL_X1Y13 / GTYE4_COMMON_X1Y3
set_property -dict {LOC U38 } [get_ports {sfp_rx_p[2]}] ;# MGTYRXP2_128 GTYE4_CHANNEL_X1Y14 / GTYE4_COMMON_X1Y3
set_property -dict {LOC U39 } [get_ports {sfp_rx_n[2]}] ;# MGTYRXN2_128 GTYE4_CHANNEL_X1Y14 / GTYE4_COMMON_X1Y3
set_property -dict {LOC T35 } [get_ports {sfp_tx_p[2]}] ;# MGTYTXP2_128 GTYE4_CHANNEL_X1Y14 / GTYE4_COMMON_X1Y3
set_property -dict {LOC T36 } [get_ports {sfp_tx_n[2]}] ;# MGTYTXN2_128 GTYE4_CHANNEL_X1Y14 / GTYE4_COMMON_X1Y3
set_property -dict {LOC R38 } [get_ports {sfp_rx_p[3]}] ;# MGTYRXP3_128 GTYE4_CHANNEL_X1Y15 / GTYE4_COMMON_X1Y3
set_property -dict {LOC R39 } [get_ports {sfp_rx_n[3]}] ;# MGTYRXN3_128 GTYE4_CHANNEL_X1Y15 / GTYE4_COMMON_X1Y3
set_property -dict {LOC R33 } [get_ports {sfp_tx_p[3]}] ;# MGTYTXP3_128 GTYE4_CHANNEL_X1Y15 / GTYE4_COMMON_X1Y3
set_property -dict {LOC R34 } [get_ports {sfp_tx_n[3]}] ;# MGTYTXN3_128 GTYE4_CHANNEL_X1Y15 / GTYE4_COMMON_X1Y3
set_property -dict {LOC V31 } [get_ports {sfp_mgt_refclk_0_p}] ;# MGTREFCLK1P_129 from U49 SI570
set_property -dict {LOC V32 } [get_ports {sfp_mgt_refclk_0_n}] ;# MGTREFCLK1N_129 from U49 SI570
#set_property -dict {LOC Y31 } [get_ports {sfp_mgt_refclk_1_p}] ;# MGTREFCLK1P_128 from U48 OUT0 SI5382A
#set_property -dict {LOC Y32 } [get_ports {sfp_mgt_refclk_1_n}] ;# MGTREFCLK1N_128 from U48 OUT0 SI5382A
#set_property -dict {LOC AW14 IOSTANDARD LVDS} [get_ports {sfp_recclk_p}] ;# to U48 CKIN1 SI5382
#set_property -dict {LOC AW13 IOSTANDARD LVDS} [get_ports {sfp_recclk_n}] ;# to U48 CKIN1 SI5382
set_property -dict {LOC G12  IOSTANDARD LVCMOS12 SLEW SLOW DRIVE 8} [get_ports {sfp_tx_disable_b[0]}]
set_property -dict {LOC G10  IOSTANDARD LVCMOS12 SLEW SLOW DRIVE 8} [get_ports {sfp_tx_disable_b[1]}]
set_property -dict {LOC K12  IOSTANDARD LVCMOS12 SLEW SLOW DRIVE 8} [get_ports {sfp_tx_disable_b[2]}]
set_property -dict {LOC J7   IOSTANDARD LVCMOS12 SLEW SLOW DRIVE 8} [get_ports {sfp_tx_disable_b[3]}]

# 156.25 MHz MGT reference clock
create_clock -period 6.400 -name sfp_mgt_refclk_0 [get_ports {sfp_mgt_refclk_0_p}]

set_false_path -to [get_ports {sfp_tx_disable_b[*]}]
set_output_delay 0 [get_ports {sfp_tx_disable_b[*]}]
