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
set_property -dict {LOC AF15 IOSTANDARD LVCMOS18} [get_ports reset] ;# SW20

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

# USB UART (U34 FT4232H CDBUS)
set_property -dict {LOC AU15 IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 8} [get_ports uart_txd] ;# U34.39 CDBUS1 RXD
set_property -dict {LOC AT15 IOSTANDARD LVCMOS18} [get_ports uart_rxd] ;# U34.38 CDBUS0 TXD
set_property -dict {LOC AU14 IOSTANDARD LVCMOS18} [get_ports uart_rts] ;# U34.40 CDBUS2 RTS#
set_property -dict {LOC AT14 IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 8} [get_ports uart_cts] ;# U34.41 CDBUS3 CTS#

set_false_path -to [get_ports {uart_txd uart_cts}]
set_output_delay 0 [get_ports {uart_txd uart_cts}]
set_false_path -from [get_ports {uart_rxd uart_rts}]
set_input_delay 0 [get_ports {uart_rxd uart_rts}]

# I2C interfaces
set_property -dict {LOC AT16 IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 12 PULLUP true} [get_ports i2c0_scl]
set_property -dict {LOC AW16 IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 12 PULLUP true} [get_ports i2c0_sda]
set_property -dict {LOC AV16 IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 12 PULLUP true} [get_ports i2c1_scl]
set_property -dict {LOC AV13 IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 12 PULLUP true} [get_ports i2c1_sda]

set_false_path -to [get_ports {i2c0_sda i2c0_scl}]
set_output_delay 0 [get_ports {i2c0_sda i2c0_scl}]
set_false_path -from [get_ports {i2c0_sda i2c0_scl}]
set_input_delay 0 [get_ports {i2c0_sda i2c0_scl}]

set_false_path -to [get_ports {i2c1_sda i2c1_scl}]
set_output_delay 0 [get_ports {i2c1_sda i2c1_scl}]
set_false_path -from [get_ports {i2c1_sda i2c1_scl}]
set_input_delay 0 [get_ports {i2c1_sda i2c1_scl}]

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

# DDR4 components
#set_property -dict {LOC D18  IOSTANDARD SSTL12_DCI} [get_ports {ddr4_a[0]}]
#set_property -dict {LOC E19  IOSTANDARD SSTL12_DCI} [get_ports {ddr4_a[1]}]
#set_property -dict {LOC E17  IOSTANDARD SSTL12_DCI} [get_ports {ddr4_a[2]}]
#set_property -dict {LOC E18  IOSTANDARD SSTL12_DCI} [get_ports {ddr4_a[3]}]
#set_property -dict {LOC E16  IOSTANDARD SSTL12_DCI} [get_ports {ddr4_a[4]}]
#set_property -dict {LOC F16  IOSTANDARD SSTL12_DCI} [get_ports {ddr4_a[5]}]
#set_property -dict {LOC F19  IOSTANDARD SSTL12_DCI} [get_ports {ddr4_a[6]}]
#set_property -dict {LOC G19  IOSTANDARD SSTL12_DCI} [get_ports {ddr4_a[7]}]
#set_property -dict {LOC F15  IOSTANDARD SSTL12_DCI} [get_ports {ddr4_a[8]}]
#set_property -dict {LOC G15  IOSTANDARD SSTL12_DCI} [get_ports {ddr4_a[9]}]
#set_property -dict {LOC G18  IOSTANDARD SSTL12_DCI} [get_ports {ddr4_a[10]}]
#set_property -dict {LOC H18  IOSTANDARD SSTL12_DCI} [get_ports {ddr4_a[11]}]
#set_property -dict {LOC K17  IOSTANDARD SSTL12_DCI} [get_ports {ddr4_a[12]}]
#set_property -dict {LOC L17  IOSTANDARD SSTL12_DCI} [get_ports {ddr4_a[13]}]
#set_property -dict {LOC B17  IOSTANDARD SSTL12_DCI} [get_ports {ddr4_a[14]}]
#set_property -dict {LOC D15  IOSTANDARD SSTL12_DCI} [get_ports {ddr4_a[15]}]
#set_property -dict {LOC C18  IOSTANDARD SSTL12_DCI} [get_ports {ddr4_a[16]}]

#set_property -dict {LOC A19  IOSTANDARD SSTL12_DCI} [get_ports {ddr4_act_n}]
#set_property -dict {LOC B18  IOSTANDARD SSTL12_DCI} [get_ports {ddr4_alert_n}]

#set_property -dict {LOC K18  IOSTANDARD SSTL12_DCI} [get_ports {ddr4_ba[0]}]
#set_property -dict {LOC K19  IOSTANDARD SSTL12_DCI} [get_ports {ddr4_ba[1]}]
#set_property -dict {LOC C16  IOSTANDARD SSTL12_DCI} [get_ports {ddr4_bg[0]}]

#set_property -dict {LOC A16  IOSTANDARD SSTL12_DCI} [get_ports {ddr4_cke}]
#set_property -dict {LOC G17  IOSTANDARD DIFF_SSTL2_DCI} [get_ports {ddr4_ck_t}]
#set_property -dict {LOC F17  IOSTANDARD DIFF_SSTL2_DCI} [get_ports {ddr4_ck_c}]
#set_property -dict {LOC D16  IOSTANDARD SSTL12_DCI} [get_ports {ddr4_cs_n}]

#set_property -dict {LOC D14  IOSTANDARD POD12_DCI} [get_ports {ddr4_dq[0]}]
#set_property -dict {LOC E11  IOSTANDARD POD12_DCI} [get_ports {ddr4_dq[1]}]
#set_property -dict {LOC F14  IOSTANDARD POD12_DCI} [get_ports {ddr4_dq[2]}]
#set_property -dict {LOC F12  IOSTANDARD POD12_DCI} [get_ports {ddr4_dq[3]}]
#set_property -dict {LOC E14  IOSTANDARD POD12_DCI} [get_ports {ddr4_dq[4]}]
#set_property -dict {LOC H12  IOSTANDARD POD12_DCI} [get_ports {ddr4_dq[5]}]
#set_property -dict {LOC G14  IOSTANDARD POD12_DCI} [get_ports {ddr4_dq[6]}]
#set_property -dict {LOC H13  IOSTANDARD POD12_DCI} [get_ports {ddr4_dq[7]}]
#set_property -dict {LOC B13  IOSTANDARD POD12_DCI} [get_ports {ddr4_dq[8]}]
#set_property -dict {LOC A15  IOSTANDARD POD12_DCI} [get_ports {ddr4_dq[9]}]
#set_property -dict {LOC A12  IOSTANDARD POD12_DCI} [get_ports {ddr4_dq[10]}]
#set_property -dict {LOC A14  IOSTANDARD POD12_DCI} [get_ports {ddr4_dq[11]}]
#set_property -dict {LOC D13  IOSTANDARD POD12_DCI} [get_ports {ddr4_dq[12]}]
#set_property -dict {LOC B14  IOSTANDARD POD12_DCI} [get_ports {ddr4_dq[13]}]
#set_property -dict {LOC A11  IOSTANDARD POD12_DCI} [get_ports {ddr4_dq[14]}]
#set_property -dict {LOC C13  IOSTANDARD POD12_DCI} [get_ports {ddr4_dq[15]}]
#set_property -dict {LOC K11  IOSTANDARD POD12_DCI} [get_ports {ddr4_dq[16]}]
#set_property -dict {LOC J11  IOSTANDARD POD12_DCI} [get_ports {ddr4_dq[17]}]
#set_property -dict {LOC H10  IOSTANDARD POD12_DCI} [get_ports {ddr4_dq[18]}]
#set_property -dict {LOC F11  IOSTANDARD POD12_DCI} [get_ports {ddr4_dq[19]}]
#set_property -dict {LOC K10  IOSTANDARD POD12_DCI} [get_ports {ddr4_dq[20]}]
#set_property -dict {LOC F10  IOSTANDARD POD12_DCI} [get_ports {ddr4_dq[21]}]
#set_property -dict {LOC J10  IOSTANDARD POD12_DCI} [get_ports {ddr4_dq[22]}]
#set_property -dict {LOC H11  IOSTANDARD POD12_DCI} [get_ports {ddr4_dq[23]}]
#set_property -dict {LOC G9   IOSTANDARD POD12_DCI} [get_ports {ddr4_dq[24]}]
#set_property -dict {LOC G7   IOSTANDARD POD12_DCI} [get_ports {ddr4_dq[25]}]
#set_property -dict {LOC F9   IOSTANDARD POD12_DCI} [get_ports {ddr4_dq[26]}]
#set_property -dict {LOC G6   IOSTANDARD POD12_DCI} [get_ports {ddr4_dq[27]}]
#set_property -dict {LOC H6   IOSTANDARD POD12_DCI} [get_ports {ddr4_dq[28]}]
#set_property -dict {LOC H7   IOSTANDARD POD12_DCI} [get_ports {ddr4_dq[29]}]
#set_property -dict {LOC J9   IOSTANDARD POD12_DCI} [get_ports {ddr4_dq[30]}]
#set_property -dict {LOC K9   IOSTANDARD POD12_DCI} [get_ports {ddr4_dq[31]}]
#set_property -dict {LOC C22  IOSTANDARD POD12_DCI} [get_ports {ddr4_dq[32]}]
#set_property -dict {LOC A20  IOSTANDARD POD12_DCI} [get_ports {ddr4_dq[33]}]
#set_property -dict {LOC A21  IOSTANDARD POD12_DCI} [get_ports {ddr4_dq[34]}]
#set_property -dict {LOC C21  IOSTANDARD POD12_DCI} [get_ports {ddr4_dq[35]}]
#set_property -dict {LOC A24  IOSTANDARD POD12_DCI} [get_ports {ddr4_dq[36]}]
#set_property -dict {LOC B20  IOSTANDARD POD12_DCI} [get_ports {ddr4_dq[37]}]
#set_property -dict {LOC B24  IOSTANDARD POD12_DCI} [get_ports {ddr4_dq[38]}]
#set_property -dict {LOC C20  IOSTANDARD POD12_DCI} [get_ports {ddr4_dq[39]}]
#set_property -dict {LOC E24  IOSTANDARD POD12_DCI} [get_ports {ddr4_dq[40]}]
#set_property -dict {LOC E22  IOSTANDARD POD12_DCI} [get_ports {ddr4_dq[41]}]
#set_property -dict {LOC E23  IOSTANDARD POD12_DCI} [get_ports {ddr4_dq[42]}]
#set_property -dict {LOC G20  IOSTANDARD POD12_DCI} [get_ports {ddr4_dq[43]}]
#set_property -dict {LOC F24  IOSTANDARD POD12_DCI} [get_ports {ddr4_dq[44]}]
#set_property -dict {LOC E21  IOSTANDARD POD12_DCI} [get_ports {ddr4_dq[45]}]
#set_property -dict {LOC F20  IOSTANDARD POD12_DCI} [get_ports {ddr4_dq[46]}]
#set_property -dict {LOC D21  IOSTANDARD POD12_DCI} [get_ports {ddr4_dq[47]}]
#set_property -dict {LOC H23  IOSTANDARD POD12_DCI} [get_ports {ddr4_dq[48]}]
#set_property -dict {LOC G23  IOSTANDARD POD12_DCI} [get_ports {ddr4_dq[49]}]
#set_property -dict {LOC K24  IOSTANDARD POD12_DCI} [get_ports {ddr4_dq[50]}]
#set_property -dict {LOC G22  IOSTANDARD POD12_DCI} [get_ports {ddr4_dq[51]}]
#set_property -dict {LOC J21  IOSTANDARD POD12_DCI} [get_ports {ddr4_dq[52]}]
#set_property -dict {LOC H22  IOSTANDARD POD12_DCI} [get_ports {ddr4_dq[53]}]
#set_property -dict {LOC L24  IOSTANDARD POD12_DCI} [get_ports {ddr4_dq[54]}]
#set_property -dict {LOC H21  IOSTANDARD POD12_DCI} [get_ports {ddr4_dq[55]}]
#set_property -dict {LOC L23  IOSTANDARD POD12_DCI} [get_ports {ddr4_dq[56]}]
#set_property -dict {LOC L20  IOSTANDARD POD12_DCI} [get_ports {ddr4_dq[57]}]
#set_property -dict {LOC L22  IOSTANDARD POD12_DCI} [get_ports {ddr4_dq[58]}]
#set_property -dict {LOC L21  IOSTANDARD POD12_DCI} [get_ports {ddr4_dq[59]}]
#set_property -dict {LOC M20  IOSTANDARD POD12_DCI} [get_ports {ddr4_dq[60]}]
#set_property -dict {LOC L19  IOSTANDARD POD12_DCI} [get_ports {ddr4_dq[61]}]
#set_property -dict {LOC M19  IOSTANDARD POD12_DCI} [get_ports {ddr4_dq[62]}]
#set_property -dict {LOC N19  IOSTANDARD POD12_DCI} [get_ports {ddr4_dq[63]}]

#set_property -dict {LOC E13  IOSTANDARD DIFF_POD12} [get_ports {ddr4_dqs_t[0]}]
#set_property -dict {LOC E12  IOSTANDARD DIFF_POD12} [get_ports {ddr4_dqs_c[0]}]
#set_property -dict {LOC C15  IOSTANDARD DIFF_POD12} [get_ports {ddr4_dqs_t[1]}]
#set_property -dict {LOC B15  IOSTANDARD DIFF_POD12} [get_ports {ddr4_dqs_c[1]}]
#set_property -dict {LOC J14  IOSTANDARD DIFF_POD12} [get_ports {ddr4_dqs_t[2]}]
#set_property -dict {LOC J13  IOSTANDARD DIFF_POD12} [get_ports {ddr4_dqs_c[2]}]
#set_property -dict {LOC H8   IOSTANDARD DIFF_POD12} [get_ports {ddr4_dqs_t[3]}]
#set_property -dict {LOC G8   IOSTANDARD DIFF_POD12} [get_ports {ddr4_dqs_c[3]}]
#set_property -dict {LOC B22  IOSTANDARD DIFF_POD12} [get_ports {ddr4_dqs_t[4]}]
#set_property -dict {LOC A22  IOSTANDARD DIFF_POD12} [get_ports {ddr4_dqs_c[4]}]
#set_property -dict {LOC D23  IOSTANDARD DIFF_POD12} [get_ports {ddr4_dqs_t[5]}]
#set_property -dict {LOC D24  IOSTANDARD DIFF_POD12} [get_ports {ddr4_dqs_c[5]}]
#set_property -dict {LOC J20  IOSTANDARD DIFF_POD12} [get_ports {ddr4_dqs_t[6]}]
#set_property -dict {LOC H20  IOSTANDARD DIFF_POD12} [get_ports {ddr4_dqs_c[6]}]
#set_property -dict {LOC K21  IOSTANDARD DIFF_POD12} [get_ports {ddr4_dqs_t[7]}]
#set_property -dict {LOC K22  IOSTANDARD DIFF_POD12} [get_ports {ddr4_dqs_c[7]}]

#set_property -dict {LOC G13  IOSTANDARD POD12_DCI} [get_ports {ddr4_dm_dbi_n[0]}]
#set_property -dict {LOC C12  IOSTANDARD POD12_DCI} [get_ports {ddr4_dm_dbi_n[1]}]
#set_property -dict {LOC K13  IOSTANDARD POD12_DCI} [get_ports {ddr4_dm_dbi_n[2]}]
#set_property -dict {LOC J8   IOSTANDARD POD12_DCI} [get_ports {ddr4_dm_dbi_n[3]}]
#set_property -dict {LOC C23  IOSTANDARD POD12_DCI} [get_ports {ddr4_dm_dbi_n[4]}]
#set_property -dict {LOC F21  IOSTANDARD POD12_DCI} [get_ports {ddr4_dm_dbi_n[5]}]
#set_property -dict {LOC J23  IOSTANDARD POD12_DCI} [get_ports {ddr4_dm_dbi_n[6]}]
#set_property -dict {LOC N20  IOSTANDARD POD12_DCI} [get_ports {ddr4_dm_dbi_n[7]}]

#set_property -dict {LOC B19 IOSTANDARD LVCMOS12} [get_ports {ddr4_odt}]
#set_property -dict {LOC A17 IOSTANDARD LVCMOS12} [get_ports {ddr4_rst_n}]
#set_property -dict {LOC D19 IOSTANDARD LVCMOS12} [get_ports {ddr4_par}]

# FMC+ HSPC J26
#set_property -dict {LOC AP9  IOSTANDARD LVDS DIFF_TERM_ADV TERM_100} [get_ports {fmcp_hspc_la_p[0]}]  ;# J26.G9  LA00_P_CC
#set_property -dict {LOC AR9  IOSTANDARD LVDS DIFF_TERM_ADV TERM_100} [get_ports {fmcp_hspc_la_n[0]}]  ;# J26.G10 LA00_N_CC
#set_property -dict {LOC AP8  IOSTANDARD LVDS DIFF_TERM_ADV TERM_100} [get_ports {fmcp_hspc_la_p[1]}]  ;# J26.D8  LA01_P_CC
#set_property -dict {LOC AR8  IOSTANDARD LVDS DIFF_TERM_ADV TERM_100} [get_ports {fmcp_hspc_la_n[1]}]  ;# J26.D9  LA01_N_CC
#set_property -dict {LOC AH13 IOSTANDARD LVDS DIFF_TERM_ADV TERM_100} [get_ports {fmcp_hspc_la_p[2]}]  ;# J26.H7  LA02_P
#set_property -dict {LOC AJ13 IOSTANDARD LVDS DIFF_TERM_ADV TERM_100} [get_ports {fmcp_hspc_la_n[2]}]  ;# J26.H8  LA02_N
#set_property -dict {LOC AJ12 IOSTANDARD LVDS DIFF_TERM_ADV TERM_100} [get_ports {fmcp_hspc_la_p[3]}]  ;# J26.G12 LA03_P
#set_property -dict {LOC AK12 IOSTANDARD LVDS DIFF_TERM_ADV TERM_100} [get_ports {fmcp_hspc_la_n[3]}]  ;# J26.G13 LA03_N
#set_property -dict {LOC AG12 IOSTANDARD LVDS DIFF_TERM_ADV TERM_100} [get_ports {fmcp_hspc_la_p[4]}]  ;# J26.H10 LA04_P
#set_property -dict {LOC AH12 IOSTANDARD LVDS DIFF_TERM_ADV TERM_100} [get_ports {fmcp_hspc_la_n[4]}]  ;# J26.H11 LA04_N
#set_property -dict {LOC AM8  IOSTANDARD LVDS DIFF_TERM_ADV TERM_100} [get_ports {fmcp_hspc_la_p[5]}]  ;# J26.D11 LA05_P
#set_property -dict {LOC AM7  IOSTANDARD LVDS DIFF_TERM_ADV TERM_100} [get_ports {fmcp_hspc_la_n[5]}]  ;# J26.D12 LA05_N
#set_property -dict {LOC AL8  IOSTANDARD LVDS DIFF_TERM_ADV TERM_100} [get_ports {fmcp_hspc_la_p[6]}]  ;# J26.C10 LA06_P
#set_property -dict {LOC AL7  IOSTANDARD LVDS DIFF_TERM_ADV TERM_100} [get_ports {fmcp_hspc_la_n[6]}]  ;# J26.C11 LA06_N
#set_property -dict {LOC AK13 IOSTANDARD LVDS DIFF_TERM_ADV TERM_100} [get_ports {fmcp_hspc_la_p[7]}]  ;# J26.H13 LA07_P
#set_property -dict {LOC AL12 IOSTANDARD LVDS DIFF_TERM_ADV TERM_100} [get_ports {fmcp_hspc_la_n[7]}]  ;# J26.H14 LA07_N
#set_property -dict {LOC AL9  IOSTANDARD LVDS DIFF_TERM_ADV TERM_100} [get_ports {fmcp_hspc_la_p[8]}]  ;# J26.G12 LA08_P
#set_property -dict {LOC AM9  IOSTANDARD LVDS DIFF_TERM_ADV TERM_100} [get_ports {fmcp_hspc_la_n[8]}]  ;# J26.G13 LA08_N
#set_property -dict {LOC AN8  IOSTANDARD LVDS DIFF_TERM_ADV TERM_100} [get_ports {fmcp_hspc_la_p[9]}]  ;# J26.D14 LA09_P
#set_property -dict {LOC AN7  IOSTANDARD LVDS DIFF_TERM_ADV TERM_100} [get_ports {fmcp_hspc_la_n[9]}]  ;# J26.D15 LA09_N
#set_property -dict {LOC AM12 IOSTANDARD LVDS DIFF_TERM_ADV TERM_100} [get_ports {fmcp_hspc_la_p[10]}] ;# J26.C14 LA10_P
#set_property -dict {LOC AN12 IOSTANDARD LVDS DIFF_TERM_ADV TERM_100} [get_ports {fmcp_hspc_la_n[10]}] ;# J26.C15 LA10_N
#set_property -dict {LOC AT10 IOSTANDARD LVDS DIFF_TERM_ADV TERM_100} [get_ports {fmcp_hspc_la_p[11]}] ;# J26.H16 LA11_P
#set_property -dict {LOC AU10 IOSTANDARD LVDS DIFF_TERM_ADV TERM_100} [get_ports {fmcp_hspc_la_n[11]}] ;# J26.H17 LA11_N
#set_property -dict {LOC AL10 IOSTANDARD LVDS DIFF_TERM_ADV TERM_100} [get_ports {fmcp_hspc_la_p[12]}] ;# J26.G15 LA12_P
#set_property -dict {LOC AM10 IOSTANDARD LVDS DIFF_TERM_ADV TERM_100} [get_ports {fmcp_hspc_la_n[12]}] ;# J26.G16 LA12_N
#set_property -dict {LOC AM13 IOSTANDARD LVDS DIFF_TERM_ADV TERM_100} [get_ports {fmcp_hspc_la_p[13]}] ;# J26.D17 LA13_P
#set_property -dict {LOC AN13 IOSTANDARD LVDS DIFF_TERM_ADV TERM_100} [get_ports {fmcp_hspc_la_n[13]}] ;# J26.D18 LA13_N
#set_property -dict {LOC AL14 IOSTANDARD LVDS DIFF_TERM_ADV TERM_100} [get_ports {fmcp_hspc_la_p[14]}] ;# J26.C18 LA14_P
#set_property -dict {LOC AM14 IOSTANDARD LVDS DIFF_TERM_ADV TERM_100} [get_ports {fmcp_hspc_la_n[14]}] ;# J26.C19 LA14_N
#set_property -dict {LOC AJ14 IOSTANDARD LVDS DIFF_TERM_ADV TERM_100} [get_ports {fmcp_hspc_la_p[15]}] ;# J26.H19 LA15_P
#set_property -dict {LOC AK14 IOSTANDARD LVDS DIFF_TERM_ADV TERM_100} [get_ports {fmcp_hspc_la_n[15]}] ;# J26.H20 LA15_N
#set_property -dict {LOC AR12 IOSTANDARD LVDS DIFF_TERM_ADV TERM_100} [get_ports {fmcp_hspc_la_p[16]}] ;# J26.G18 LA16_P
#set_property -dict {LOC AR11 IOSTANDARD LVDS DIFF_TERM_ADV TERM_100} [get_ports {fmcp_hspc_la_n[16]}] ;# J26.G19 LA16_N
#set_property -dict {LOC AN21 IOSTANDARD LVDS DIFF_TERM_ADV TERM_100} [get_ports {fmcp_hspc_la_p[17]}] ;# J26.D20 LA17_P_CC
#set_property -dict {LOC AP21 IOSTANDARD LVDS DIFF_TERM_ADV TERM_100} [get_ports {fmcp_hspc_la_n[17]}] ;# J26.D21 LA17_N_CC
#set_property -dict {LOC AM20 IOSTANDARD LVDS DIFF_TERM_ADV TERM_100} [get_ports {fmcp_hspc_la_p[18]}] ;# J26.C22 LA18_P_CC
#set_property -dict {LOC AN20 IOSTANDARD LVDS DIFF_TERM_ADV TERM_100} [get_ports {fmcp_hspc_la_n[18]}] ;# J26.C23 LA18_N_CC
#set_property -dict {LOC AU20 IOSTANDARD LVDS DIFF_TERM_ADV TERM_100} [get_ports {fmcp_hspc_la_p[19]}] ;# J26.H22 LA19_P
#set_property -dict {LOC AU19 IOSTANDARD LVDS DIFF_TERM_ADV TERM_100} [get_ports {fmcp_hspc_la_n[19]}] ;# J26.H23 LA19_N
#set_property -dict {LOC AR17 IOSTANDARD LVDS DIFF_TERM_ADV TERM_100} [get_ports {fmcp_hspc_la_p[20]}] ;# J26.G21 LA20_P
#set_property -dict {LOC AT17 IOSTANDARD LVDS DIFF_TERM_ADV TERM_100} [get_ports {fmcp_hspc_la_n[20]}] ;# J26.G22 LA20_N
#set_property -dict {LOC AL19 IOSTANDARD LVDS DIFF_TERM_ADV TERM_100} [get_ports {fmcp_hspc_la_p[21]}] ;# J26.H25 LA21_P
#set_property -dict {LOC AM19 IOSTANDARD LVDS DIFF_TERM_ADV TERM_100} [get_ports {fmcp_hspc_la_n[21]}] ;# J26.H26 LA21_N
#set_property -dict {LOC AR19 IOSTANDARD LVDS DIFF_TERM_ADV TERM_100} [get_ports {fmcp_hspc_la_p[22]}] ;# J26.G24 LA22_P
#set_property -dict {LOC AT19 IOSTANDARD LVDS DIFF_TERM_ADV TERM_100} [get_ports {fmcp_hspc_la_n[22]}] ;# J26.G25 LA22_N
#set_property -dict {LOC AM18 IOSTANDARD LVDS DIFF_TERM_ADV TERM_100} [get_ports {fmcp_hspc_la_p[23]}] ;# J26.D23 LA23_P
#set_property -dict {LOC AN18 IOSTANDARD LVDS DIFF_TERM_ADV TERM_100} [get_ports {fmcp_hspc_la_n[23]}] ;# J26.D24 LA23_N
#set_property -dict {LOC AL22 IOSTANDARD LVDS DIFF_TERM_ADV TERM_100} [get_ports {fmcp_hspc_la_p[24]}] ;# J26.H28 LA24_P
#set_property -dict {LOC AM22 IOSTANDARD LVDS DIFF_TERM_ADV TERM_100} [get_ports {fmcp_hspc_la_n[24]}] ;# J26.H29 LA24_N
#set_property -dict {LOC AL21 IOSTANDARD LVDS DIFF_TERM_ADV TERM_100} [get_ports {fmcp_hspc_la_p[25]}] ;# J26.G27 LA25_P
#set_property -dict {LOC AL20 IOSTANDARD LVDS DIFF_TERM_ADV TERM_100} [get_ports {fmcp_hspc_la_n[25]}] ;# J26.G28 LA25_N
#set_property -dict {LOC AR22 IOSTANDARD LVDS DIFF_TERM_ADV TERM_100} [get_ports {fmcp_hspc_la_p[26]}] ;# J26.D26 LA26_P
#set_property -dict {LOC AT22 IOSTANDARD LVDS DIFF_TERM_ADV TERM_100} [get_ports {fmcp_hspc_la_n[26]}] ;# J26.D27 LA26_N
#set_property -dict {LOC AR21 IOSTANDARD LVDS DIFF_TERM_ADV TERM_100} [get_ports {fmcp_hspc_la_p[27]}] ;# J26.C26 LA27_P
#set_property -dict {LOC AT21 IOSTANDARD LVDS DIFF_TERM_ADV TERM_100} [get_ports {fmcp_hspc_la_n[27]}] ;# J26.C27 LA27_N
#set_property -dict {LOC AJ18 IOSTANDARD LVDS DIFF_TERM_ADV TERM_100} [get_ports {fmcp_hspc_la_p[28]}] ;# J26.H31 LA28_P
#set_property -dict {LOC AK18 IOSTANDARD LVDS DIFF_TERM_ADV TERM_100} [get_ports {fmcp_hspc_la_n[28]}] ;# J26.H32 LA28_N
#set_property -dict {LOC AK22 IOSTANDARD LVDS DIFF_TERM_ADV TERM_100} [get_ports {fmcp_hspc_la_p[29]}] ;# J26.G30 LA29_P
#set_property -dict {LOC AK21 IOSTANDARD LVDS DIFF_TERM_ADV TERM_100} [get_ports {fmcp_hspc_la_n[29]}] ;# J26.G31 LA29_N
#set_property -dict {LOC AG20 IOSTANDARD LVDS DIFF_TERM_ADV TERM_100} [get_ports {fmcp_hspc_la_p[30]}] ;# J26.H34 LA30_P
#set_property -dict {LOC AH20 IOSTANDARD LVDS DIFF_TERM_ADV TERM_100} [get_ports {fmcp_hspc_la_n[30]}] ;# J26.H35 LA30_N
#set_property -dict {LOC AJ20 IOSTANDARD LVDS DIFF_TERM_ADV TERM_100} [get_ports {fmcp_hspc_la_p[31]}] ;# J26.G33 LA31_P
#set_property -dict {LOC AJ19 IOSTANDARD LVDS DIFF_TERM_ADV TERM_100} [get_ports {fmcp_hspc_la_n[31]}] ;# J26.G34 LA31_N
#set_property -dict {LOC AF20 IOSTANDARD LVDS DIFF_TERM_ADV TERM_100} [get_ports {fmcp_hspc_la_p[32]}] ;# J26.H37 LA32_P
#set_property -dict {LOC AF19 IOSTANDARD LVDS DIFF_TERM_ADV TERM_100} [get_ports {fmcp_hspc_la_n[32]}] ;# J26.H38 LA32_N
#set_property -dict {LOC AG18 IOSTANDARD LVDS DIFF_TERM_ADV TERM_100} [get_ports {fmcp_hspc_la_p[33]}] ;# J26.G36 LA33_P
#set_property -dict {LOC AH18 IOSTANDARD LVDS DIFF_TERM_ADV TERM_100} [get_ports {fmcp_hspc_la_n[33]}] ;# J26.G37 LA33_N

#set_property -dict {LOC AN10 IOSTANDARD LVDS DIFF_TERM_ADV TERM_100} [get_ports {fmcp_hspc_clk0_m2c_p}] ;# J26.H4 CLK0_M2C_P
#set_property -dict {LOC AP10 IOSTANDARD LVDS DIFF_TERM_ADV TERM_100} [get_ports {fmcp_hspc_clk0_m2c_n}] ;# J26.H5 CLK0_M2C_N
#set_property -dict {LOC AP20 IOSTANDARD LVDS DIFF_TERM_ADV TERM_100} [get_ports {fmcp_hspc_clk1_m2c_p}] ;# J26.G2 CLK1_M2C_P
#set_property -dict {LOC AP19 IOSTANDARD LVDS DIFF_TERM_ADV TERM_100} [get_ports {fmcp_hspc_clk1_m2c_n}] ;# J26.G3 CLK1_M2C_N

#set_property -dict {LOC AV11 IOSTANDARD LVDS                       } [get_ports {fmcp_hspc_refclk_c2m_p}] ;# J26.L20 REFCLK_C2M_P
#set_property -dict {LOC AW11 IOSTANDARD LVDS                       } [get_ports {fmcp_hspc_refclk_c2m_n}] ;# J26.L21 REFCLK_C2M_N
#set_property -dict {LOC AN11 IOSTANDARD LVDS DIFF_TERM_ADV TERM_100} [get_ports {fmcp_hspc_refclk_m2c_p}] ;# J26.L24 REFCLK_M2C_P
#set_property -dict {LOC AP11 IOSTANDARD LVDS DIFF_TERM_ADV TERM_100} [get_ports {fmcp_hspc_refclk_m2c_n}] ;# J26.L25 REFCLK_M2C_N
#set_property -dict {LOC AT11 IOSTANDARD LVDS                       } [get_ports {fmcp_hspc_sync_c2m_p}]   ;# J26.L16 SYNC_C2M_P
#set_property -dict {LOC AT12 IOSTANDARD LVDS                       } [get_ports {fmcp_hspc_sync_c2m_n}]   ;# J26.L17 SYNC_C2M_N
#set_property -dict {LOC AV12 IOSTANDARD LVDS DIFF_TERM_ADV TERM_100} [get_ports {fmcp_hspc_sync_m2c_p}]   ;# J26.L28 SYNC_M2C_P
#set_property -dict {LOC AU12 IOSTANDARD LVDS DIFF_TERM_ADV TERM_100} [get_ports {fmcp_hspc_sync_m2c_n}]   ;# J26.L29 SYNC_M2C_N

#set_property -dict {LOC P35 } [get_ports {fmcp_hspc_dp_c2m_p[0]}]  ;# MGTYTXP0_129 GTYE4_CHANNEL_X0Y8 / GTYE4_COMMON_X0Y2 from J26.C2  DP0_C2M_P
#set_property -dict {LOC P36 } [get_ports {fmcp_hspc_dp_c2m_n[0]}]  ;# MGTYTXN0_129 GTYE4_CHANNEL_X0Y8 / GTYE4_COMMON_X0Y2 from J26.C3  DP0_C2M_N
#set_property -dict {LOC N38 } [get_ports {fmcp_hspc_dp_m2c_p[0]}]  ;# MGTYRXP0_129 GTYE4_CHANNEL_X0Y8 / GTYE4_COMMON_X0Y2 from J26.C6  DP0_M2C_P
#set_property -dict {LOC N39 } [get_ports {fmcp_hspc_dp_m2c_n[0]}]  ;# MGTYRXN0_129 GTYE4_CHANNEL_X0Y8 / GTYE4_COMMON_X0Y2 from J26.C7  DP0_M2C_N
#set_property -dict {LOC N33 } [get_ports {fmcp_hspc_dp_c2m_p[1]}]  ;# MGTYTXP1_129 GTYE4_CHANNEL_X0Y9 / GTYE4_COMMON_X0Y2 from J26.A22 DP1_C2M_P
#set_property -dict {LOC N34 } [get_ports {fmcp_hspc_dp_c2m_n[1]}]  ;# MGTYTXN1_129 GTYE4_CHANNEL_X0Y9 / GTYE4_COMMON_X0Y2 from J26.A23 DP1_C2M_N
#set_property -dict {LOC M36 } [get_ports {fmcp_hspc_dp_m2c_p[1]}]  ;# MGTYRXP1_129 GTYE4_CHANNEL_X0Y9 / GTYE4_COMMON_X0Y2 from J26.A2  DP1_M2C_P
#set_property -dict {LOC M37 } [get_ports {fmcp_hspc_dp_m2c_n[1]}]  ;# MGTYRXN1_129 GTYE4_CHANNEL_X0Y9 / GTYE4_COMMON_X0Y2 from J26.A3  DP1_M2C_N
#set_property -dict {LOC L33 } [get_ports {fmcp_hspc_dp_c2m_p[2]}]  ;# MGTYTXP2_129 GTYE4_CHANNEL_X0Y10 / GTYE4_COMMON_X0Y2 from J26.A26 DP2_C2M_P
#set_property -dict {LOC L34 } [get_ports {fmcp_hspc_dp_c2m_n[2]}]  ;# MGTYTXN2_129 GTYE4_CHANNEL_X0Y10 / GTYE4_COMMON_X0Y2 from J26.A27 DP2_C2M_N
#set_property -dict {LOC L38 } [get_ports {fmcp_hspc_dp_m2c_p[2]}]  ;# MGTYRXP2_129 GTYE4_CHANNEL_X0Y10 / GTYE4_COMMON_X0Y2 from J26.A6  DP2_M2C_P
#set_property -dict {LOC L39 } [get_ports {fmcp_hspc_dp_m2c_n[2]}]  ;# MGTYRXN2_129 GTYE4_CHANNEL_X0Y10 / GTYE4_COMMON_X0Y2 from J26.A7  DP2_M2C_N
#set_property -dict {LOC J33 } [get_ports {fmcp_hspc_dp_c2m_p[3]}]  ;# MGTYTXP3_129 GTYE4_CHANNEL_X0Y11 / GTYE4_COMMON_X0Y2 from J26.A30 DP3_C2M_P
#set_property -dict {LOC J34 } [get_ports {fmcp_hspc_dp_c2m_n[3]}]  ;# MGTYTXN3_129 GTYE4_CHANNEL_X0Y11 / GTYE4_COMMON_X0Y2 from J26.A31 DP3_C2M_N
#set_property -dict {LOC K36 } [get_ports {fmcp_hspc_dp_m2c_p[3]}]  ;# MGTYRXP3_129 GTYE4_CHANNEL_X0Y11 / GTYE4_COMMON_X0Y2 from J26.A10 DP3_M2C_P
#set_property -dict {LOC K37 } [get_ports {fmcp_hspc_dp_m2c_n[3]}]  ;# MGTYRXN3_129 GTYE4_CHANNEL_X0Y11 / GTYE4_COMMON_X0Y2 from J26.A11 DP3_M2C_N
#set_property -dict {LOC W33 } [get_ports {fmcp_hspc_mgt_refclk_0_0_p}] ;# MGTREFCLK0P_129 from J26.D4 GBTCLK0_M2C_P
#set_property -dict {LOC W34 } [get_ports {fmcp_hspc_mgt_refclk_0_0_n}] ;# MGTREFCLK0N_129 from J26.D5 GBTCLK0_M2C_N
#set_property -dict {LOC V31 } [get_ports {fmcp_hspc_mgt_refclk_0_1_p}] ;# MGTREFCLK1P_129 from U49 SI570
#set_property -dict {LOC V32 } [get_ports {fmcp_hspc_mgt_refclk_0_1_n}] ;# MGTREFCLK1N_129 from U49 SI570

# reference clock
#create_clock -period 6.400 -name fmcp_hspc_mgt_refclk_0_0 [get_ports {fmcp_hspc_mgt_refclk_0_0_p}]
#create_clock -period 6.400 -name fmcp_hspc_mgt_refclk_0_1 [get_ports {fmcp_hspc_mgt_refclk_0_1_p}]

#set_property -dict {LOC H31 } [get_ports {fmcp_hspc_dp_c2m_p[4]}]  ;# MGTYTXP0_130 GTYE4_CHANNEL_X0Y28 / GTYE4_COMMON_X0Y7 from J26.A34 DP4_C2M_P
#set_property -dict {LOC H32 } [get_ports {fmcp_hspc_dp_c2m_n[4]}]  ;# MGTYTXN0_130 GTYE4_CHANNEL_X0Y28 / GTYE4_COMMON_X0Y7 from J26.A35 DP4_C2M_N
#set_property -dict {LOC J38 } [get_ports {fmcp_hspc_dp_m2c_p[4]}]  ;# MGTYRXP0_130 GTYE4_CHANNEL_X0Y28 / GTYE4_COMMON_X0Y7 from J26.A14 DP4_M2C_P
#set_property -dict {LOC J39 } [get_ports {fmcp_hspc_dp_m2c_n[4]}]  ;# MGTYRXN0_130 GTYE4_CHANNEL_X0Y28 / GTYE4_COMMON_X0Y7 from J26.A15 DP4_M2C_N
#set_property -dict {LOC G33 } [get_ports {fmcp_hspc_dp_c2m_p[5]}]  ;# MGTYTXP1_130 GTYE4_CHANNEL_X0Y29 / GTYE4_COMMON_X0Y7 from J26.A38 DP5_C2M_P
#set_property -dict {LOC G34 } [get_ports {fmcp_hspc_dp_c2m_n[5]}]  ;# MGTYTXN1_130 GTYE4_CHANNEL_X0Y29 / GTYE4_COMMON_X0Y7 from J26.A39 DP5_C2M_N
#set_property -dict {LOC H36 } [get_ports {fmcp_hspc_dp_m2c_p[5]}]  ;# MGTYRXP1_130 GTYE4_CHANNEL_X0Y29 / GTYE4_COMMON_X0Y7 from J26.A18 DP5_M2C_P
#set_property -dict {LOC H37 } [get_ports {fmcp_hspc_dp_m2c_n[5]}]  ;# MGTYRXN1_130 GTYE4_CHANNEL_X0Y29 / GTYE4_COMMON_X0Y7 from J26.A19 DP5_M2C_N
#set_property -dict {LOC F31 } [get_ports {fmcp_hspc_dp_c2m_p[6]}]  ;# MGTYTXP2_130 GTYE4_CHANNEL_X0Y30 / GTYE4_COMMON_X0Y7 from J26.B36 DP6_C2M_P
#set_property -dict {LOC F32 } [get_ports {fmcp_hspc_dp_c2m_n[6]}]  ;# MGTYTXN2_130 GTYE4_CHANNEL_X0Y30 / GTYE4_COMMON_X0Y7 from J26.B37 DP6_C2M_N
#set_property -dict {LOC G38 } [get_ports {fmcp_hspc_dp_m2c_p[6]}]  ;# MGTYRXP2_130 GTYE4_CHANNEL_X0Y30 / GTYE4_COMMON_X0Y7 from J26.B16 DP6_M2C_P
#set_property -dict {LOC G39 } [get_ports {fmcp_hspc_dp_m2c_n[6]}]  ;# MGTYRXN2_130 GTYE4_CHANNEL_X0Y30 / GTYE4_COMMON_X0Y7 from J26.B17 DP6_M2C_N
#set_property -dict {LOC E33 } [get_ports {fmcp_hspc_dp_c2m_p[7]}]  ;# MGTYTXP3_130 GTYE4_CHANNEL_X0Y31 / GTYE4_COMMON_X0Y7 from J26.B32 DP7_C2M_P
#set_property -dict {LOC E34 } [get_ports {fmcp_hspc_dp_c2m_n[7]}]  ;# MGTYTXN3_130 GTYE4_CHANNEL_X0Y31 / GTYE4_COMMON_X0Y7 from J26.B33 DP7_C2M_N
#set_property -dict {LOC F36 } [get_ports {fmcp_hspc_dp_m2c_p[7]}]  ;# MGTYRXP3_130 GTYE4_CHANNEL_X0Y31 / GTYE4_COMMON_X0Y7 from J26.B12 DP7_M2C_P
#set_property -dict {LOC F37 } [get_ports {fmcp_hspc_dp_m2c_n[7]}]  ;# MGTYRXN3_130 GTYE4_CHANNEL_X0Y31 / GTYE4_COMMON_X0Y7 from J26.B13 DP7_M2C_N
#set_property -dict {LOC U33 } [get_ports {fmcp_hspc_mgt_refclk_1_0_p}] ;# MGTREFCLK0P_130 from J26.B20 GBTCLK1_M2C_P
#set_property -dict {LOC U34 } [get_ports {fmcp_hspc_mgt_refclk_1_0_n}] ;# MGTREFCLK0N_130 from J26.B21 GBTCLK1_M2C_N
#set_property -dict {LOC T31 } [get_ports {fmcp_hspc_mgt_refclk_1_1_p}] ;# MGTREFCLK1P_130 from J14
#set_property -dict {LOC T32 } [get_ports {fmcp_hspc_mgt_refclk_1_1_n}] ;# MGTREFCLK1N_130 from J15

# reference clock
#create_clock -period 6.400 -name fmcp_hspc_mgt_refclk_1_0 [get_ports {fmcp_hspc_mgt_refclk_1_0_p}]
#create_clock -period 6.400 -name fmcp_hspc_mgt_refclk_1_1 [get_ports {fmcp_hspc_mgt_refclk_1_1_p}]

#set_property -dict {LOC D31 } [get_ports {fmcp_hspc_dp_c2m_p[8]}]  ;# MGTYTXP0_131 GTYE4_CHANNEL_X0Y12 / GTYE4_COMMON_X0Y3 from J26.B28 DP8_C2M_P
#set_property -dict {LOC D32 } [get_ports {fmcp_hspc_dp_c2m_n[8]}]  ;# MGTYTXN0_131 GTYE4_CHANNEL_X0Y12 / GTYE4_COMMON_X0Y3 from J26.B29 DP8_C2M_N
#set_property -dict {LOC E38 } [get_ports {fmcp_hspc_dp_m2c_p[8]}]  ;# MGTYRXP0_131 GTYE4_CHANNEL_X0Y12 / GTYE4_COMMON_X0Y3 from J26.B8  DP8_M2C_P
#set_property -dict {LOC E39 } [get_ports {fmcp_hspc_dp_m2c_n[8]}]  ;# MGTYRXN0_131 GTYE4_CHANNEL_X0Y12 / GTYE4_COMMON_X0Y3 from J26.B9  DP8_M2C_N
#set_property -dict {LOC C33 } [get_ports {fmcp_hspc_dp_c2m_p[9]}]  ;# MGTYTXP1_131 GTYE4_CHANNEL_X0Y13 / GTYE4_COMMON_X0Y3 from J26.B24 DP9_C2M_P
#set_property -dict {LOC C34 } [get_ports {fmcp_hspc_dp_c2m_n[9]}]  ;# MGTYTXN1_131 GTYE4_CHANNEL_X0Y13 / GTYE4_COMMON_X0Y3 from J26.B25 DP9_C2M_N
#set_property -dict {LOC D36 } [get_ports {fmcp_hspc_dp_m2c_p[9]}]  ;# MGTYRXP1_131 GTYE4_CHANNEL_X0Y13 / GTYE4_COMMON_X0Y3 from J26.B4  DP9_M2C_P
#set_property -dict {LOC D37 } [get_ports {fmcp_hspc_dp_m2c_n[9]}]  ;# MGTYRXN1_131 GTYE4_CHANNEL_X0Y13 / GTYE4_COMMON_X0Y3 from J26.B5  DP9_M2C_N
#set_property -dict {LOC B31 } [get_ports {fmcp_hspc_dp_c2m_p[10]}] ;# MGTYTXP2_131 GTYE4_CHANNEL_X0Y14 / GTYE4_COMMON_X0Y3 from J26.Z24 DP10_C2M_P
#set_property -dict {LOC B32 } [get_ports {fmcp_hspc_dp_c2m_n[10]}] ;# MGTYTXN2_131 GTYE4_CHANNEL_X0Y14 / GTYE4_COMMON_X0Y3 from J26.Z25 DP10_C2M_N
#set_property -dict {LOC C38 } [get_ports {fmcp_hspc_dp_m2c_p[10]}] ;# MGTYRXP2_131 GTYE4_CHANNEL_X0Y14 / GTYE4_COMMON_X0Y3 from J26.Y10 DP10_M2C_P
#set_property -dict {LOC C39 } [get_ports {fmcp_hspc_dp_m2c_n[10]}] ;# MGTYRXN2_131 GTYE4_CHANNEL_X0Y14 / GTYE4_COMMON_X0Y3 from J26.Y11 DP10_M2C_N
#set_property -dict {LOC A33 } [get_ports {fmcp_hspc_dp_c2m_p[11]}] ;# MGTYTXP3_131 GTYE4_CHANNEL_X0Y15 / GTYE4_COMMON_X0Y3 from J26.Y26 DP11_C2M_P
#set_property -dict {LOC A34 } [get_ports {fmcp_hspc_dp_c2m_n[11]}] ;# MGTYTXN3_131 GTYE4_CHANNEL_X0Y15 / GTYE4_COMMON_X0Y3 from J26.Y27 DP11_C2M_N
#set_property -dict {LOC B36 } [get_ports {fmcp_hspc_dp_m2c_p[11]}] ;# MGTYRXP3_131 GTYE4_CHANNEL_X0Y15 / GTYE4_COMMON_X0Y3 from J26.Z12 DP11_M2C_P
#set_property -dict {LOC B37 } [get_ports {fmcp_hspc_dp_m2c_n[11]}] ;# MGTYRXN3_131 GTYE4_CHANNEL_X0Y15 / GTYE4_COMMON_X0Y3 from J26.Z13 DP11_M2C_N
#set_property -dict {LOC P31 } [get_ports {fmcp_hspc_mgt_refclk_2_p}] ;# MGTREFCLK0P_131 from J26.L12 GBTCLK2_M2C_P
#set_property -dict {LOC P32 } [get_ports {fmcp_hspc_mgt_refclk_2_n}] ;# MGTREFCLK0N_131 from J26.L13 GBTCLK2_M2C_N

# reference clock
#create_clock -period 6.400 -name fmcp_hspc_mgt_refclk_2 [get_ports {fmcp_hspc_mgt_refclk_2_p}]

# RFDC
set_property -dict {LOC AP2 } [get_ports {adc_vin_p[0]}]  ;# ADC_VIN_I01_224_P from J47.G9
set_property -dict {LOC AP1 } [get_ports {adc_vin_n[0]}]  ;# ADC_VIN_I01_224_N from J47.F9
set_property -dict {LOC AM2 } [get_ports {adc_vin_p[1]}]  ;# ADC_VIN_I23_224_P from J47.C10
set_property -dict {LOC AM1 } [get_ports {adc_vin_n[1]}]  ;# ADC_VIN_I23_224_N from J47.B10
set_property -dict {LOC AK2 } [get_ports {adc_vin_p[2]}]  ;# ADC_VIN_I01_225_P from J47.G12
set_property -dict {LOC AK1 } [get_ports {adc_vin_n[2]}]  ;# ADC_VIN_I01_225_N from J47.F12
set_property -dict {LOC AH2 } [get_ports {adc_vin_p[3]}]  ;# ADC_VIN_I23_225_P from J47.C13
set_property -dict {LOC AH1 } [get_ports {adc_vin_n[3]}]  ;# ADC_VIN_I23_225_N from J47.B13
set_property -dict {LOC AF2 } [get_ports {adc_vin_p[4]}]  ;# ADC_VIN_I01_226_P from J47.G15
set_property -dict {LOC AF1 } [get_ports {adc_vin_n[4]}]  ;# ADC_VIN_I01_226_N from J47.F15
set_property -dict {LOC AD2 } [get_ports {adc_vin_p[5]}]  ;# ADC_VIN_I23_226_P from J47.C16
set_property -dict {LOC AD1 } [get_ports {adc_vin_n[5]}]  ;# ADC_VIN_I23_226_N from J47.B16
set_property -dict {LOC AB2 } [get_ports {adc_vin_p[6]}]  ;# ADC_VIN_I01_227_P from J47.G18
set_property -dict {LOC AB1 } [get_ports {adc_vin_n[6]}]  ;# ADC_VIN_I01_227_N from J47.F18
set_property -dict {LOC Y2  } [get_ports {adc_vin_p[7]}]  ;# ADC_VIN_I23_227_P from J47.C19
set_property -dict {LOC Y1  } [get_ports {adc_vin_n[7]}]  ;# ADC_VIN_I23_227_N from J47.B19

set_property -dict {LOC AF5 } [get_ports {adc_refclk_0_p}]  ;# ADC_224_REFCLK_P from U102.23 RFoutAP
set_property -dict {LOC AF4 } [get_ports {adc_refclk_0_n}]  ;# ADC_224_REFCLK_N from U102.22 RFoutAN
set_property -dict {LOC AD5 } [get_ports {adc_refclk_1_p}]  ;# ADC_225_REFCLK_P from U102.19 RFoutBP
set_property -dict {LOC AD4 } [get_ports {adc_refclk_1_n}]  ;# ADC_225_REFCLK_N from U102.18 RFoutBN
set_property -dict {LOC AB5 } [get_ports {adc_refclk_2_p}]  ;# ADC_226_REFCLK_P from U103.23 RFoutAP
set_property -dict {LOC AB4 } [get_ports {adc_refclk_2_n}]  ;# ADC_226_REFCLK_N from U103.22 RFoutAN
set_property -dict {LOC Y5  } [get_ports {adc_refclk_3_p}]  ;# ADC_227_REFCLK_P from U103.19 RFoutBP
set_property -dict {LOC Y4  } [get_ports {adc_refclk_3_n}]  ;# ADC_227_REFCLK_N from U103.18 RFoutBN

set_property -dict {LOC U2  } [get_ports {dac_vout_p[0]}]  ;# DAC_VOUT0_228_P from J94.G9
set_property -dict {LOC U1  } [get_ports {dac_vout_n[0]}]  ;# DAC_VOUT0_228_N from J94.F9
set_property -dict {LOC R2  } [get_ports {dac_vout_p[1]}]  ;# DAC_VOUT1_228_P from J94.C10
set_property -dict {LOC R1  } [get_ports {dac_vout_n[1]}]  ;# DAC_VOUT1_228_N from J94.B10
set_property -dict {LOC N2  } [get_ports {dac_vout_p[2]}]  ;# DAC_VOUT2_228_P from J94.G12
set_property -dict {LOC N1  } [get_ports {dac_vout_n[2]}]  ;# DAC_VOUT2_228_N from J94.F12
set_property -dict {LOC L2  } [get_ports {dac_vout_p[3]}]  ;# DAC_VOUT3_228_P from J94.C13
set_property -dict {LOC L1  } [get_ports {dac_vout_n[3]}]  ;# DAC_VOUT3_228_N from J94.B13
set_property -dict {LOC J2  } [get_ports {dac_vout_p[4]}]  ;# DAC_VOUT0_229_P from J94.G15
set_property -dict {LOC J1  } [get_ports {dac_vout_n[4]}]  ;# DAC_VOUT0_229_N from J94.F15
set_property -dict {LOC G2  } [get_ports {dac_vout_p[5]}]  ;# DAC_VOUT1_229_P from J94.C16
set_property -dict {LOC G1  } [get_ports {dac_vout_n[5]}]  ;# DAC_VOUT1_229_N from J94.B16
set_property -dict {LOC E2  } [get_ports {dac_vout_p[6]}]  ;# DAC_VOUT2_229_P from J94.G18
set_property -dict {LOC E1  } [get_ports {dac_vout_n[6]}]  ;# DAC_VOUT2_229_N from J94.F18
set_property -dict {LOC C2  } [get_ports {dac_vout_p[7]}]  ;# DAC_VOUT3_229_P from J94.C19
set_property -dict {LOC C1  } [get_ports {dac_vout_n[7]}]  ;# DAC_VOUT3_229_N from J94.B19

set_property -dict {LOC R5  } [get_ports {dac_refclk_0_p}]  ;# DAC_228_REFCLK_P from U104.23 RFoutAP
set_property -dict {LOC R4  } [get_ports {dac_refclk_0_n}]  ;# DAC_228_REFCLK_N from U104.22 RFoutAN
set_property -dict {LOC N5  } [get_ports {dac_refclk_1_p}]  ;# DAC_229_REFCLK_P from U104.19 RFoutBP
set_property -dict {LOC N4  } [get_ports {dac_refclk_1_n}]  ;# DAC_229_REFCLK_N from U104.18 RFoutBN

set_property -dict {LOC U5  } [get_ports {rfdc_sysref_p}]  ;# SYSREF_P_228 from U90.13 CLKout1_P
set_property -dict {LOC U4  } [get_ports {rfdc_sysref_n}]  ;# SYSREF_N_228 from U90.14 CLKout1_N
