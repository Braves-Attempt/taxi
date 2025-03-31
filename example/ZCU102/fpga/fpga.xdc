# SPDX-License-Identifier: MIT
#
# Copyright (c) 2025 FPGA Ninja, LLC
#
# Authors:
# - Alex Forencich
#

# XDC constraints for the Xilinx ZCU102 board
# part: xczu9eg-ffvb1156-2-e

# General configuration
set_property BITSTREAM.GENERAL.COMPRESS true           [current_design]

# System clocks
# 125 MHz
set_property -dict {LOC G21  IOSTANDARD LVDS_25} [get_ports clk_125mhz_p]
set_property -dict {LOC F21  IOSTANDARD LVDS_25} [get_ports clk_125mhz_n]
create_clock -period 8.000 -name clk_125mhz [get_ports clk_125mhz_p]

# LEDs
set_property -dict {LOC AG14 IOSTANDARD LVCMOS33 SLEW SLOW DRIVE 8} [get_ports {led[0]}]
set_property -dict {LOC AF13 IOSTANDARD LVCMOS33 SLEW SLOW DRIVE 8} [get_ports {led[1]}]
set_property -dict {LOC AE13 IOSTANDARD LVCMOS33 SLEW SLOW DRIVE 8} [get_ports {led[2]}]
set_property -dict {LOC AJ14 IOSTANDARD LVCMOS33 SLEW SLOW DRIVE 8} [get_ports {led[3]}]
set_property -dict {LOC AJ15 IOSTANDARD LVCMOS33 SLEW SLOW DRIVE 8} [get_ports {led[4]}]
set_property -dict {LOC AH13 IOSTANDARD LVCMOS33 SLEW SLOW DRIVE 8} [get_ports {led[5]}]
set_property -dict {LOC AH14 IOSTANDARD LVCMOS33 SLEW SLOW DRIVE 8} [get_ports {led[6]}]
set_property -dict {LOC AL12 IOSTANDARD LVCMOS33 SLEW SLOW DRIVE 8} [get_ports {led[7]}]

set_false_path -to [get_ports {led[*]}]
set_output_delay 0 [get_ports {led[*]}]

# Reset button
set_property -dict {LOC AM13 IOSTANDARD LVCMOS33} [get_ports reset]

set_false_path -from [get_ports {reset}]
set_input_delay 0 [get_ports {reset}]

# Push buttons
set_property -dict {LOC AG15 IOSTANDARD LVCMOS33} [get_ports btnu]
set_property -dict {LOC AF15 IOSTANDARD LVCMOS33} [get_ports btnl]
set_property -dict {LOC AE15 IOSTANDARD LVCMOS33} [get_ports btnd]
set_property -dict {LOC AE14 IOSTANDARD LVCMOS33} [get_ports btnr]
set_property -dict {LOC AG13 IOSTANDARD LVCMOS33} [get_ports btnc]

set_false_path -from [get_ports {btnu btnl btnd btnr btnc}]
set_input_delay 0 [get_ports {btnu btnl btnd btnr btnc}]

# DIP switches
set_property -dict {LOC AN14 IOSTANDARD LVCMOS33} [get_ports {sw[0]}]
set_property -dict {LOC AP14 IOSTANDARD LVCMOS33} [get_ports {sw[1]}]
set_property -dict {LOC AM14 IOSTANDARD LVCMOS33} [get_ports {sw[2]}]
set_property -dict {LOC AN13 IOSTANDARD LVCMOS33} [get_ports {sw[3]}]
set_property -dict {LOC AN12 IOSTANDARD LVCMOS33} [get_ports {sw[4]}]
set_property -dict {LOC AP12 IOSTANDARD LVCMOS33} [get_ports {sw[5]}]
set_property -dict {LOC AL13 IOSTANDARD LVCMOS33} [get_ports {sw[6]}]
set_property -dict {LOC AK13 IOSTANDARD LVCMOS33} [get_ports {sw[7]}]

set_false_path -from [get_ports {sw[*]}]
set_input_delay 0 [get_ports {sw[*]}]

# PMOD0
#set_property -dict {LOC A20  IOSTANDARD LVCMOS33 SLEW SLOW DRIVE 8} [get_ports {pmod0[0]}] ;# J55.1
#set_property -dict {LOC B20  IOSTANDARD LVCMOS33 SLEW SLOW DRIVE 8} [get_ports {pmod0[1]}] ;# J55.3
#set_property -dict {LOC A22  IOSTANDARD LVCMOS33 SLEW SLOW DRIVE 8} [get_ports {pmod0[2]}] ;# J55.5
#set_property -dict {LOC A21  IOSTANDARD LVCMOS33 SLEW SLOW DRIVE 8} [get_ports {pmod0[3]}] ;# J55.7
#set_property -dict {LOC B21  IOSTANDARD LVCMOS33 SLEW SLOW DRIVE 8} [get_ports {pmod0[4]}] ;# J55.2
#set_property -dict {LOC C21  IOSTANDARD LVCMOS33 SLEW SLOW DRIVE 8} [get_ports {pmod0[5]}] ;# J55.4
#set_property -dict {LOC C22  IOSTANDARD LVCMOS33 SLEW SLOW DRIVE 8} [get_ports {pmod0[6]}] ;# J55.6
#set_property -dict {LOC D21  IOSTANDARD LVCMOS33 SLEW SLOW DRIVE 8} [get_ports {pmod0[7]}] ;# J55.8

#set_false_path -to [get_ports {pmod0[*]}]
#set_output_delay 0 [get_ports {pmod0[*]}]

# PMOD1
#set_property -dict {LOC D20  IOSTANDARD LVCMOS33 SLEW SLOW DRIVE 8} [get_ports {pmod1[0]}] ;# J87.1
#set_property -dict {LOC E20  IOSTANDARD LVCMOS33 SLEW SLOW DRIVE 8} [get_ports {pmod1[1]}] ;# J87.3
#set_property -dict {LOC D22  IOSTANDARD LVCMOS33 SLEW SLOW DRIVE 8} [get_ports {pmod1[2]}] ;# J87.5
#set_property -dict {LOC E22  IOSTANDARD LVCMOS33 SLEW SLOW DRIVE 8} [get_ports {pmod1[3]}] ;# J87.7
#set_property -dict {LOC F20  IOSTANDARD LVCMOS33 SLEW SLOW DRIVE 8} [get_ports {pmod1[4]}] ;# J87.2
#set_property -dict {LOC G20  IOSTANDARD LVCMOS33 SLEW SLOW DRIVE 8} [get_ports {pmod1[5]}] ;# J87.4
#set_property -dict {LOC J20  IOSTANDARD LVCMOS33 SLEW SLOW DRIVE 8} [get_ports {pmod1[6]}] ;# J87.6
#set_property -dict {LOC J19  IOSTANDARD LVCMOS33 SLEW SLOW DRIVE 8} [get_ports {pmod1[7]}] ;# J87.8

#set_false_path -to [get_ports {pmod1[*]}]
#set_output_delay 0 [get_ports {pmod1[*]}]

# "Prototype header" GPIO
#set_property -dict {LOC H14  IOSTANDARD LVCMOS33 SLEW SLOW DRIVE 8} [get_ports {proto_gpio[0]}] ;# J3.6
#set_property -dict {LOC J14  IOSTANDARD LVCMOS33 SLEW SLOW DRIVE 8} [get_ports {proto_gpio[1]}] ;# J3.8
#set_property -dict {LOC G14  IOSTANDARD LVCMOS33 SLEW SLOW DRIVE 8} [get_ports {proto_gpio[2]}] ;# J3.10
#set_property -dict {LOC G15  IOSTANDARD LVCMOS33 SLEW SLOW DRIVE 8} [get_ports {proto_gpio[3]}] ;# J3.12
#set_property -dict {LOC J15  IOSTANDARD LVCMOS33 SLEW SLOW DRIVE 8} [get_ports {proto_gpio[4]}] ;# J3.14
#set_property -dict {LOC J16  IOSTANDARD LVCMOS33 SLEW SLOW DRIVE 8} [get_ports {proto_gpio[5]}] ;# J3.16
#set_property -dict {LOC G16  IOSTANDARD LVCMOS33 SLEW SLOW DRIVE 8} [get_ports {proto_gpio[6]}] ;# J3.18
#set_property -dict {LOC H16  IOSTANDARD LVCMOS33 SLEW SLOW DRIVE 8} [get_ports {proto_gpio[7]}] ;# J3.20
#set_property -dict {LOC G13  IOSTANDARD LVCMOS33 SLEW SLOW DRIVE 8} [get_ports {proto_gpio[8]}] ;# J3.22
#set_property -dict {LOC H13  IOSTANDARD LVCMOS33 SLEW SLOW DRIVE 8} [get_ports {proto_gpio[9]}] ;# J3.24

#set_false_path -to [get_ports {proto_gpio[*]}]
#set_output_delay 0 [get_ports {proto_gpio[*]}]

# UART (U40 CP2108 ch 2)
set_property -dict {LOC F13  IOSTANDARD LVCMOS33 SLEW SLOW DRIVE 8} [get_ports uart_txd] ;# U40.15 RX_2
set_property -dict {LOC E13  IOSTANDARD LVCMOS33} [get_ports uart_rxd] ;# U40.16 TX_2
set_property -dict {LOC D12  IOSTANDARD LVCMOS33} [get_ports uart_rts] ;# U40.14 RTS_2
set_property -dict {LOC E12  IOSTANDARD LVCMOS33 SLEW SLOW DRIVE 8} [get_ports uart_cts] ;# U40.13 CTS_2

set_false_path -to [get_ports {uart_txd uart_cts}]
set_output_delay 0 [get_ports {uart_txd uart_cts}]
set_false_path -from [get_ports {uart_rxd uart_rts}]
set_input_delay 0 [get_ports {uart_rxd uart_rts}]

# I2C interfaces
#set_property -dict {LOC J10  IOSTANDARD LVCMOS33 SLEW SLOW DRIVE 8} [get_ports i2c0_scl]
#set_property -dict {LOC J11  IOSTANDARD LVCMOS33 SLEW SLOW DRIVE 8} [get_ports i2c0_sda]
#set_property -dict {LOC K20  IOSTANDARD LVCMOS33 SLEW SLOW DRIVE 8} [get_ports i2c1_scl]
#set_property -dict {LOC L20  IOSTANDARD LVCMOS33 SLEW SLOW DRIVE 8} [get_ports i2c1_sda]

#set_false_path -to [get_ports {i2c1_sda i2c1_scl}]
#set_output_delay 0 [get_ports {i2c1_sda i2c1_scl}]
#set_false_path -from [get_ports {i2c1_sda i2c1_scl}]
#set_input_delay 0 [get_ports {i2c1_sda i2c1_scl}]

# SFP+ Interface
set_property -dict {LOC D2  } [get_ports {sfp_rx_p[0]}] ;# MGTHRXP0_230 GTHE4_CHANNEL_X1Y12 / GTHE4_COMMON_X1Y3
set_property -dict {LOC D1  } [get_ports {sfp_rx_n[0]}] ;# MGTHRXN0_230 GTHE4_CHANNEL_X1Y12 / GTHE4_COMMON_X1Y3
set_property -dict {LOC E4  } [get_ports {sfp_tx_p[0]}] ;# MGTHTXP0_230 GTHE4_CHANNEL_X1Y12 / GTHE4_COMMON_X1Y3
set_property -dict {LOC E3  } [get_ports {sfp_tx_n[0]}] ;# MGTHTXN0_230 GTHE4_CHANNEL_X1Y12 / GTHE4_COMMON_X1Y3
set_property -dict {LOC C4  } [get_ports {sfp_rx_p[1]}] ;# MGTHRXP1_230 GTHE4_CHANNEL_X1Y13 / GTHE4_COMMON_X1Y3
set_property -dict {LOC C3  } [get_ports {sfp_rx_n[1]}] ;# MGTHRXN1_230 GTHE4_CHANNEL_X1Y13 / GTHE4_COMMON_X1Y3
set_property -dict {LOC D6  } [get_ports {sfp_tx_p[1]}] ;# MGTHTXP1_230 GTHE4_CHANNEL_X1Y13 / GTHE4_COMMON_X1Y3
set_property -dict {LOC D5  } [get_ports {sfp_tx_n[1]}] ;# MGTHTXN1_230 GTHE4_CHANNEL_X1Y13 / GTHE4_COMMON_X1Y3
set_property -dict {LOC B2  } [get_ports {sfp_rx_p[2]}] ;# MGTHRXP2_230 GTHE4_CHANNEL_X1Y14 / GTHE4_COMMON_X1Y3
set_property -dict {LOC B1  } [get_ports {sfp_rx_n[2]}] ;# MGTHRXN2_230 GTHE4_CHANNEL_X1Y14 / GTHE4_COMMON_X1Y3
set_property -dict {LOC B6  } [get_ports {sfp_tx_p[2]}] ;# MGTHTXP2_230 GTHE4_CHANNEL_X1Y14 / GTHE4_COMMON_X1Y3
set_property -dict {LOC B5  } [get_ports {sfp_tx_n[2]}] ;# MGTHTXN2_230 GTHE4_CHANNEL_X1Y14 / GTHE4_COMMON_X1Y3
set_property -dict {LOC A4  } [get_ports {sfp_rx_p[3]}] ;# MGTHRXP3_230 GTHE4_CHANNEL_X1Y15 / GTHE4_COMMON_X1Y3
set_property -dict {LOC A3  } [get_ports {sfp_rx_n[3]}] ;# MGTHRXN3_230 GTHE4_CHANNEL_X1Y15 / GTHE4_COMMON_X1Y3
set_property -dict {LOC A8  } [get_ports {sfp_tx_p[3]}] ;# MGTHTXP3_230 GTHE4_CHANNEL_X1Y15 / GTHE4_COMMON_X1Y3
set_property -dict {LOC A7  } [get_ports {sfp_tx_n[3]}] ;# MGTHTXN3_230 GTHE4_CHANNEL_X1Y15 / GTHE4_COMMON_X1Y3
set_property -dict {LOC C8  } [get_ports {sfp_mgt_refclk_0_p}] ;# MGTREFCLK0P_230 from U56 SI570 via U51 SI53340
set_property -dict {LOC C7  } [get_ports {sfp_mgt_refclk_0_n}] ;# MGTREFCLK0N_230 from U56 SI570 via U51 SI53340
#set_property -dict {LOC B10 } [get_ports {sfp_mgt_refclk_1_p}] ;# MGTREFCLK1P_230 from U20 CKOUT2 SI5328
#set_property -dict {LOC B9  } [get_ports {sfp_mgt_refclk_1_n}] ;# MGTREFCLK1N_230 from U20 CKOUT2 SI5328
#set_property -dict {LOC R10  IOSTANDARD LVDS} [get_ports {sfp_recclk_p}] ;# to U20 CKIN1 SI5328
#set_property -dict {LOC R9   IOSTANDARD LVDS} [get_ports {sfp_recclk_n}] ;# to U20 CKIN1 SI5328
set_property -dict {LOC A12  IOSTANDARD LVCMOS33 SLEW SLOW DRIVE 8} [get_ports {sfp_tx_disable_b[0]}]
set_property -dict {LOC A13  IOSTANDARD LVCMOS33 SLEW SLOW DRIVE 8} [get_ports {sfp_tx_disable_b[1]}]
set_property -dict {LOC B13  IOSTANDARD LVCMOS33 SLEW SLOW DRIVE 8} [get_ports {sfp_tx_disable_b[2]}]
set_property -dict {LOC C13  IOSTANDARD LVCMOS33 SLEW SLOW DRIVE 8} [get_ports {sfp_tx_disable_b[3]}]

# 156.25 MHz MGT reference clock
create_clock -period 6.400 -name sfp_mgt_refclk_0 [get_ports {sfp_mgt_refclk_0_p}]

set_false_path -to [get_ports {sfp_tx_disable_b[*]}]
set_output_delay 0 [get_ports {sfp_tx_disable_b[*]}]

# FMC interface
# FMC HPC0 J5
#set_property -dict {LOC Y4   IOSTANDARD LVDS DIFF_TERM_ADV TERM_100} [get_ports {fmc_hpc0_la_p[0]}]  ;# J5.G9  LA00_P_CC
#set_property -dict {LOC Y3   IOSTANDARD LVDS DIFF_TERM_ADV TERM_100} [get_ports {fmc_hpc0_la_n[0]}]  ;# J5.G10 LA00_N_CC
#set_property -dict {LOC AB4  IOSTANDARD LVDS DIFF_TERM_ADV TERM_100} [get_ports {fmc_hpc0_la_p[1]}]  ;# J5.D8  LA01_P_CC
#set_property -dict {LOC AC4  IOSTANDARD LVDS DIFF_TERM_ADV TERM_100} [get_ports {fmc_hpc0_la_n[1]}]  ;# J5.D9  LA01_N_CC
#set_property -dict {LOC V2   IOSTANDARD LVDS DIFF_TERM_ADV TERM_100} [get_ports {fmc_hpc0_la_p[2]}]  ;# J5.H7  LA02_P
#set_property -dict {LOC V1   IOSTANDARD LVDS DIFF_TERM_ADV TERM_100} [get_ports {fmc_hpc0_la_n[2]}]  ;# J5.H8  LA02_N
#set_property -dict {LOC Y2   IOSTANDARD LVDS DIFF_TERM_ADV TERM_100} [get_ports {fmc_hpc0_la_p[3]}]  ;# J5.G12 LA03_P
#set_property -dict {LOC Y1   IOSTANDARD LVDS DIFF_TERM_ADV TERM_100} [get_ports {fmc_hpc0_la_n[3]}]  ;# J5.G13 LA03_N
#set_property -dict {LOC AA2  IOSTANDARD LVDS DIFF_TERM_ADV TERM_100} [get_ports {fmc_hpc0_la_p[4]}]  ;# J5.H10 LA04_P
#set_property -dict {LOC AA1  IOSTANDARD LVDS DIFF_TERM_ADV TERM_100} [get_ports {fmc_hpc0_la_n[4]}]  ;# J5.H11 LA04_N
#set_property -dict {LOC AB3  IOSTANDARD LVDS DIFF_TERM_ADV TERM_100} [get_ports {fmc_hpc0_la_p[5]}]  ;# J5.D11 LA05_P
#set_property -dict {LOC AC3  IOSTANDARD LVDS DIFF_TERM_ADV TERM_100} [get_ports {fmc_hpc0_la_n[5]}]  ;# J5.D12 LA05_N
#set_property -dict {LOC AC2  IOSTANDARD LVDS DIFF_TERM_ADV TERM_100} [get_ports {fmc_hpc0_la_p[6]}]  ;# J5.C10 LA06_P
#set_property -dict {LOC AC1  IOSTANDARD LVDS DIFF_TERM_ADV TERM_100} [get_ports {fmc_hpc0_la_n[6]}]  ;# J5.C11 LA06_N
#set_property -dict {LOC U5   IOSTANDARD LVDS DIFF_TERM_ADV TERM_100} [get_ports {fmc_hpc0_la_p[7]}]  ;# J5.H13 LA07_P
#set_property -dict {LOC U4   IOSTANDARD LVDS DIFF_TERM_ADV TERM_100} [get_ports {fmc_hpc0_la_n[7]}]  ;# J5.H14 LA07_N
#set_property -dict {LOC V4   IOSTANDARD LVDS DIFF_TERM_ADV TERM_100} [get_ports {fmc_hpc0_la_p[8]}]  ;# J5.G12 LA08_P
#set_property -dict {LOC V3   IOSTANDARD LVDS DIFF_TERM_ADV TERM_100} [get_ports {fmc_hpc0_la_n[8]}]  ;# J5.G13 LA08_N
#set_property -dict {LOC W2   IOSTANDARD LVDS DIFF_TERM_ADV TERM_100} [get_ports {fmc_hpc0_la_p[9]}]  ;# J5.D14 LA09_P
#set_property -dict {LOC W1   IOSTANDARD LVDS DIFF_TERM_ADV TERM_100} [get_ports {fmc_hpc0_la_n[9]}]  ;# J5.D15 LA09_N
#set_property -dict {LOC W5   IOSTANDARD LVDS DIFF_TERM_ADV TERM_100} [get_ports {fmc_hpc0_la_p[10]}] ;# J5.C14 LA10_P
#set_property -dict {LOC W4   IOSTANDARD LVDS DIFF_TERM_ADV TERM_100} [get_ports {fmc_hpc0_la_n[10]}] ;# J5.C15 LA10_N
#set_property -dict {LOC AB6  IOSTANDARD LVDS DIFF_TERM_ADV TERM_100} [get_ports {fmc_hpc0_la_p[11]}] ;# J5.H16 LA11_P
#set_property -dict {LOC AB5  IOSTANDARD LVDS DIFF_TERM_ADV TERM_100} [get_ports {fmc_hpc0_la_n[11]}] ;# J5.H17 LA11_N
#set_property -dict {LOC W7   IOSTANDARD LVDS DIFF_TERM_ADV TERM_100} [get_ports {fmc_hpc0_la_p[12]}] ;# J5.G15 LA12_P
#set_property -dict {LOC W6   IOSTANDARD LVDS DIFF_TERM_ADV TERM_100} [get_ports {fmc_hpc0_la_n[12]}] ;# J5.G16 LA12_N
#set_property -dict {LOC AB8  IOSTANDARD LVDS DIFF_TERM_ADV TERM_100} [get_ports {fmc_hpc0_la_p[13]}] ;# J5.D17 LA13_P
#set_property -dict {LOC AC8  IOSTANDARD LVDS DIFF_TERM_ADV TERM_100} [get_ports {fmc_hpc0_la_n[13]}] ;# J5.D18 LA13_N
#set_property -dict {LOC AC7  IOSTANDARD LVDS DIFF_TERM_ADV TERM_100} [get_ports {fmc_hpc0_la_p[14]}] ;# J5.C18 LA14_P
#set_property -dict {LOC AC6  IOSTANDARD LVDS DIFF_TERM_ADV TERM_100} [get_ports {fmc_hpc0_la_n[14]}] ;# J5.C19 LA14_N
#set_property -dict {LOC Y10  IOSTANDARD LVDS DIFF_TERM_ADV TERM_100} [get_ports {fmc_hpc0_la_p[15]}] ;# J5.H19 LA15_P
#set_property -dict {LOC Y9   IOSTANDARD LVDS DIFF_TERM_ADV TERM_100} [get_ports {fmc_hpc0_la_n[15]}] ;# J5.H20 LA15_N
#set_property -dict {LOC Y12  IOSTANDARD LVDS DIFF_TERM_ADV TERM_100} [get_ports {fmc_hpc0_la_p[16]}] ;# J5.G18 LA16_P
#set_property -dict {LOC AA12 IOSTANDARD LVDS DIFF_TERM_ADV TERM_100} [get_ports {fmc_hpc0_la_n[16]}] ;# J5.G19 LA16_N
#set_property -dict {LOC P11  IOSTANDARD LVDS DIFF_TERM_ADV TERM_100} [get_ports {fmc_hpc0_la_p[17]}] ;# J5.D20 LA17_P_CC
#set_property -dict {LOC N11  IOSTANDARD LVDS DIFF_TERM_ADV TERM_100} [get_ports {fmc_hpc0_la_n[17]}] ;# J5.D21 LA17_N_CC
#set_property -dict {LOC N9   IOSTANDARD LVDS DIFF_TERM_ADV TERM_100} [get_ports {fmc_hpc0_la_p[18]}] ;# J5.C22 LA18_P_CC
#set_property -dict {LOC N8   IOSTANDARD LVDS DIFF_TERM_ADV TERM_100} [get_ports {fmc_hpc0_la_n[18]}] ;# J5.C23 LA18_N_CC
#set_property -dict {LOC L13  IOSTANDARD LVDS DIFF_TERM_ADV TERM_100} [get_ports {fmc_hpc0_la_p[19]}] ;# J5.H22 LA19_P
#set_property -dict {LOC K13  IOSTANDARD LVDS DIFF_TERM_ADV TERM_100} [get_ports {fmc_hpc0_la_n[19]}] ;# J5.H23 LA19_N
#set_property -dict {LOC N13  IOSTANDARD LVDS DIFF_TERM_ADV TERM_100} [get_ports {fmc_hpc0_la_p[20]}] ;# J5.G21 LA20_P
#set_property -dict {LOC M13  IOSTANDARD LVDS DIFF_TERM_ADV TERM_100} [get_ports {fmc_hpc0_la_n[20]}] ;# J5.G22 LA20_N
#set_property -dict {LOC P12  IOSTANDARD LVDS DIFF_TERM_ADV TERM_100} [get_ports {fmc_hpc0_la_p[21]}] ;# J5.H25 LA21_P
#set_property -dict {LOC N12  IOSTANDARD LVDS DIFF_TERM_ADV TERM_100} [get_ports {fmc_hpc0_la_n[21]}] ;# J5.H26 LA21_N
#set_property -dict {LOC M15  IOSTANDARD LVDS DIFF_TERM_ADV TERM_100} [get_ports {fmc_hpc0_la_p[22]}] ;# J5.G24 LA22_P
#set_property -dict {LOC M14  IOSTANDARD LVDS DIFF_TERM_ADV TERM_100} [get_ports {fmc_hpc0_la_n[22]}] ;# J5.G25 LA22_N
#set_property -dict {LOC L16  IOSTANDARD LVDS DIFF_TERM_ADV TERM_100} [get_ports {fmc_hpc0_la_p[23]}] ;# J5.D23 LA23_P
#set_property -dict {LOC K16  IOSTANDARD LVDS DIFF_TERM_ADV TERM_100} [get_ports {fmc_hpc0_la_n[23]}] ;# J5.D24 LA23_N
#set_property -dict {LOC L12  IOSTANDARD LVDS DIFF_TERM_ADV TERM_100} [get_ports {fmc_hpc0_la_p[24]}] ;# J5.H28 LA24_P
#set_property -dict {LOC K12  IOSTANDARD LVDS DIFF_TERM_ADV TERM_100} [get_ports {fmc_hpc0_la_n[24]}] ;# J5.H29 LA24_N
#set_property -dict {LOC M11  IOSTANDARD LVDS DIFF_TERM_ADV TERM_100} [get_ports {fmc_hpc0_la_p[25]}] ;# J5.G27 LA25_P
#set_property -dict {LOC L11  IOSTANDARD LVDS DIFF_TERM_ADV TERM_100} [get_ports {fmc_hpc0_la_n[25]}] ;# J5.G28 LA25_N
#set_property -dict {LOC L15  IOSTANDARD LVDS DIFF_TERM_ADV TERM_100} [get_ports {fmc_hpc0_la_p[26]}] ;# J5.D26 LA26_P
#set_property -dict {LOC K15  IOSTANDARD LVDS DIFF_TERM_ADV TERM_100} [get_ports {fmc_hpc0_la_n[26]}] ;# J5.D27 LA26_N
#set_property -dict {LOC M10  IOSTANDARD LVDS DIFF_TERM_ADV TERM_100} [get_ports {fmc_hpc0_la_p[27]}] ;# J5.C26 LA27_P
#set_property -dict {LOC L10  IOSTANDARD LVDS DIFF_TERM_ADV TERM_100} [get_ports {fmc_hpc0_la_n[27]}] ;# J5.C27 LA27_N
#set_property -dict {LOC T7   IOSTANDARD LVDS DIFF_TERM_ADV TERM_100} [get_ports {fmc_hpc0_la_p[28]}] ;# J5.H31 LA28_P
#set_property -dict {LOC T6   IOSTANDARD LVDS DIFF_TERM_ADV TERM_100} [get_ports {fmc_hpc0_la_n[28]}] ;# J5.H32 LA28_N
#set_property -dict {LOC U9   IOSTANDARD LVDS DIFF_TERM_ADV TERM_100} [get_ports {fmc_hpc0_la_p[29]}] ;# J5.G30 LA29_P
#set_property -dict {LOC U8   IOSTANDARD LVDS DIFF_TERM_ADV TERM_100} [get_ports {fmc_hpc0_la_n[29]}] ;# J5.G31 LA29_N
#set_property -dict {LOC V6   IOSTANDARD LVDS DIFF_TERM_ADV TERM_100} [get_ports {fmc_hpc0_la_p[30]}] ;# J5.H34 LA30_P
#set_property -dict {LOC U6   IOSTANDARD LVDS DIFF_TERM_ADV TERM_100} [get_ports {fmc_hpc0_la_n[30]}] ;# J5.H35 LA30_N
#set_property -dict {LOC V8   IOSTANDARD LVDS DIFF_TERM_ADV TERM_100} [get_ports {fmc_hpc0_la_p[31]}] ;# J5.G33 LA31_P
#set_property -dict {LOC V7   IOSTANDARD LVDS DIFF_TERM_ADV TERM_100} [get_ports {fmc_hpc0_la_n[31]}] ;# J5.G34 LA31_N
#set_property -dict {LOC U11  IOSTANDARD LVDS DIFF_TERM_ADV TERM_100} [get_ports {fmc_hpc0_la_p[32]}] ;# J5.H37 LA32_P
#set_property -dict {LOC T11  IOSTANDARD LVDS DIFF_TERM_ADV TERM_100} [get_ports {fmc_hpc0_la_n[32]}] ;# J5.H38 LA32_N
#set_property -dict {LOC V12  IOSTANDARD LVDS DIFF_TERM_ADV TERM_100} [get_ports {fmc_hpc0_la_p[33]}] ;# J5.G36 LA33_P
#set_property -dict {LOC V11  IOSTANDARD LVDS DIFF_TERM_ADV TERM_100} [get_ports {fmc_hpc0_la_n[33]}] ;# J5.G37 LA33_N

#set_property -dict {LOC AA7  IOSTANDARD LVDS DIFF_TERM_ADV TERM_100} [get_ports {fmc_hpc0_clk0_m2c_p}] ;# J5.H4 CLK0_M2C_P
#set_property -dict {LOC AA6  IOSTANDARD LVDS DIFF_TERM_ADV TERM_100} [get_ports {fmc_hpc0_clk0_m2c_n}] ;# J5.H5 CLK0_M2C_N
#set_property -dict {LOC T8   IOSTANDARD LVDS DIFF_TERM_ADV TERM_100} [get_ports {fmc_hpc0_clk1_m2c_p}] ;# J5.G2 CLK1_M2C_P
#set_property -dict {LOC R8   IOSTANDARD LVDS DIFF_TERM_ADV TERM_100} [get_ports {fmc_hpc0_clk1_m2c_n}] ;# J5.G3 CLK1_M2C_N

#set_property -dict {LOC G4  } [get_ports {fmc_hpc0_dp_c2m_p[0]}] ;# MGTHTXP2_229 GTHE4_CHANNEL_X1Y10 / GTHE4_COMMON_X1Y2 from J5.C2  DP0_C2M_P
#set_property -dict {LOC G3  } [get_ports {fmc_hpc0_dp_c2m_n[0]}] ;# MGTHTXN2_229 GTHE4_CHANNEL_X1Y10 / GTHE4_COMMON_X1Y2 from J5.C3  DP0_C2M_N
#set_property -dict {LOC H2  } [get_ports {fmc_hpc0_dp_m2c_p[0]}] ;# MGTHRXP2_229 GTHE4_CHANNEL_X1Y10 / GTHE4_COMMON_X1Y2 from J5.C6  DP0_M2C_P
#set_property -dict {LOC H1  } [get_ports {fmc_hpc0_dp_m2c_n[0]}] ;# MGTHRXN2_229 GTHE4_CHANNEL_X1Y10 / GTHE4_COMMON_X1Y2 from J5.C7  DP0_M2C_N
#set_property -dict {LOC H6  } [get_ports {fmc_hpc0_dp_c2m_p[1]}] ;# MGTHTXP1_229 GTHE4_CHANNEL_X1Y9  / GTHE4_COMMON_X1Y2 from J5.A22 DP1_C2M_P
#set_property -dict {LOC H5  } [get_ports {fmc_hpc0_dp_c2m_n[1]}] ;# MGTHTXN1_229 GTHE4_CHANNEL_X1Y9  / GTHE4_COMMON_X1Y2 from J5.A23 DP1_C2M_N
#set_property -dict {LOC J4  } [get_ports {fmc_hpc0_dp_m2c_p[1]}] ;# MGTHRXP1_229 GTHE4_CHANNEL_X1Y9  / GTHE4_COMMON_X1Y2 from J5.A2  DP1_M2C_P
#set_property -dict {LOC J3  } [get_ports {fmc_hpc0_dp_m2c_n[1]}] ;# MGTHRXN1_229 GTHE4_CHANNEL_X1Y9  / GTHE4_COMMON_X1Y2 from J5.A3  DP1_M2C_N
#set_property -dict {LOC F6  } [get_ports {fmc_hpc0_dp_c2m_p[2]}] ;# MGTHTXP3_229 GTHE4_CHANNEL_X1Y11 / GTHE4_COMMON_X1Y2 from J5.A26 DP2_C2M_P
#set_property -dict {LOC F5  } [get_ports {fmc_hpc0_dp_c2m_n[2]}] ;# MGTHTXN3_229 GTHE4_CHANNEL_X1Y11 / GTHE4_COMMON_X1Y2 from J5.A27 DP2_C2M_N
#set_property -dict {LOC F2  } [get_ports {fmc_hpc0_dp_m2c_p[2]}] ;# MGTHRXP3_229 GTHE4_CHANNEL_X1Y11 / GTHE4_COMMON_X1Y2 from J5.A6  DP2_M2C_P
#set_property -dict {LOC F1  } [get_ports {fmc_hpc0_dp_m2c_n[2]}] ;# MGTHRXN3_229 GTHE4_CHANNEL_X1Y11 / GTHE4_COMMON_X1Y2 from J5.A7  DP2_M2C_N
#set_property -dict {LOC K6  } [get_ports {fmc_hpc0_dp_c2m_p[3]}] ;# MGTHTXP0_229 GTHE4_CHANNEL_X1Y8  / GTHE4_COMMON_X1Y2 from J5.A30 DP3_C2M_P
#set_property -dict {LOC K5  } [get_ports {fmc_hpc0_dp_c2m_n[3]}] ;# MGTHTXN0_229 GTHE4_CHANNEL_X1Y8  / GTHE4_COMMON_X1Y2 from J5.A31 DP3_C2M_N
#set_property -dict {LOC K2  } [get_ports {fmc_hpc0_dp_m2c_p[3]}] ;# MGTHRXP0_229 GTHE4_CHANNEL_X1Y8  / GTHE4_COMMON_X1Y2 from J5.A10 DP3_M2C_P
#set_property -dict {LOC K1  } [get_ports {fmc_hpc0_dp_m2c_n[3]}] ;# MGTHRXN0_229 GTHE4_CHANNEL_X1Y8  / GTHE4_COMMON_X1Y2 from J5.A11 DP3_M2C_N

#set_property -dict {LOC M6  } [get_ports {fmc_hpc0_dp_c2m_p[4]}] ;# MGTHTXP3_228 GTHE4_CHANNEL_X1Y7 / GTHE4_COMMON_X1Y1 from J5.A34 DP4_C2M_P
#set_property -dict {LOC M5  } [get_ports {fmc_hpc0_dp_c2m_n[4]}] ;# MGTHTXN3_228 GTHE4_CHANNEL_X1Y7 / GTHE4_COMMON_X1Y1 from J5.A35 DP4_C2M_N
#set_property -dict {LOC L4  } [get_ports {fmc_hpc0_dp_m2c_p[4]}] ;# MGTHRXP3_228 GTHE4_CHANNEL_X1Y7 / GTHE4_COMMON_X1Y1 from J5.A14 DP4_M2C_P
#set_property -dict {LOC L3  } [get_ports {fmc_hpc0_dp_m2c_n[4]}] ;# MGTHRXN3_228 GTHE4_CHANNEL_X1Y7 / GTHE4_COMMON_X1Y1 from J5.A15 DP4_M2C_N
#set_property -dict {LOC P6  } [get_ports {fmc_hpc0_dp_c2m_p[5]}] ;# MGTHTXP1_228 GTHE4_CHANNEL_X1Y5 / GTHE4_COMMON_X1Y1 from J5.A38 DP5_C2M_P
#set_property -dict {LOC P5  } [get_ports {fmc_hpc0_dp_c2m_n[5]}] ;# MGTHTXN1_228 GTHE4_CHANNEL_X1Y5 / GTHE4_COMMON_X1Y1 from J5.A39 DP5_C2M_N
#set_property -dict {LOC P2  } [get_ports {fmc_hpc0_dp_m2c_p[5]}] ;# MGTHRXP1_228 GTHE4_CHANNEL_X1Y5 / GTHE4_COMMON_X1Y1 from J5.A18 DP5_M2C_P
#set_property -dict {LOC P1  } [get_ports {fmc_hpc0_dp_m2c_n[5]}] ;# MGTHRXN1_228 GTHE4_CHANNEL_X1Y5 / GTHE4_COMMON_X1Y1 from J5.A19 DP5_M2C_N
#set_property -dict {LOC R4  } [get_ports {fmc_hpc0_dp_c2m_p[6]}] ;# MGTHTXP0_228 GTHE4_CHANNEL_X1Y5 / GTHE4_COMMON_X1Y1 from J5.B36 DP6_C2M_P
#set_property -dict {LOC R3  } [get_ports {fmc_hpc0_dp_c2m_n[6]}] ;# MGTHTXN0_228 GTHE4_CHANNEL_X1Y5 / GTHE4_COMMON_X1Y1 from J5.B37 DP6_C2M_N
#set_property -dict {LOC T2  } [get_ports {fmc_hpc0_dp_m2c_p[6]}] ;# MGTHRXP0_228 GTHE4_CHANNEL_X1Y5 / GTHE4_COMMON_X1Y1 from J5.B16 DP6_M2C_P
#set_property -dict {LOC T1  } [get_ports {fmc_hpc0_dp_m2c_n[6]}] ;# MGTHRXN0_228 GTHE4_CHANNEL_X1Y5 / GTHE4_COMMON_X1Y1 from J5.B17 DP6_M2C_N
#set_property -dict {LOC N4  } [get_ports {fmc_hpc0_dp_c2m_p[7]}] ;# MGTHTXP2_228 GTHE4_CHANNEL_X1Y6 / GTHE4_COMMON_X1Y1 from J5.B32 DP7_C2M_P
#set_property -dict {LOC N3  } [get_ports {fmc_hpc0_dp_c2m_n[7]}] ;# MGTHTXN2_228 GTHE4_CHANNEL_X1Y6 / GTHE4_COMMON_X1Y1 from J5.B33 DP7_C2M_N
#set_property -dict {LOC M2  } [get_ports {fmc_hpc0_dp_m2c_p[7]}] ;# MGTHRXP2_228 GTHE4_CHANNEL_X1Y6 / GTHE4_COMMON_X1Y1 from J5.B12 DP7_M2C_P
#set_property -dict {LOC M1  } [get_ports {fmc_hpc0_dp_m2c_n[7]}] ;# MGTHRXN2_228 GTHE4_CHANNEL_X1Y6 / GTHE4_COMMON_X1Y1 from J5.B13 DP7_M2C_N
#set_property -dict {LOC G8  } [get_ports {fmc_hpc0_mgt_refclk_0_p}] ;# MGTREFCLK0P_229 from J5.D4 GBTCLK0_M2C_P
#set_property -dict {LOC G7  } [get_ports {fmc_hpc0_mgt_refclk_0_n}] ;# MGTREFCLK0N_229 from J5.D5 GBTCLK0_M2C_N
#set_property -dict {LOC L8  } [get_ports {fmc_hpc0_mgt_refclk_1_p}] ;# MGTREFCLK0P_228 from J5.B20 GBTCLK1_M2C_P
#set_property -dict {LOC L7  } [get_ports {fmc_hpc0_mgt_refclk_1_n}] ;# MGTREFCLK0N_228 from J5.B21 GBTCLK1_M2C_N

# reference clock
#create_clock -period 6.400 -name fmc_hpc0_mgt_refclk_0 [get_ports {fmc_hpc0_mgt_refclk_0_p}]
#create_clock -period 6.400 -name fmc_hpc0_mgt_refclk_1 [get_ports {fmc_hpc0_mgt_refclk_1_p}]

# FMC HPC1 J4
#set_property -dict {LOC AE5  IOSTANDARD LVDS DIFF_TERM_ADV TERM_100} [get_ports {fmc_hpc1_la_p[0]}]  ;# J4.G9  LA00_P_CC
#set_property -dict {LOC AF5  IOSTANDARD LVDS DIFF_TERM_ADV TERM_100} [get_ports {fmc_hpc1_la_n[0]}]  ;# J4.G10 LA00_N_CC
#set_property -dict {LOC AJ6  IOSTANDARD LVDS DIFF_TERM_ADV TERM_100} [get_ports {fmc_hpc1_la_p[1]}]  ;# J4.D8  LA01_P_CC
#set_property -dict {LOC AJ5  IOSTANDARD LVDS DIFF_TERM_ADV TERM_100} [get_ports {fmc_hpc1_la_n[1]}]  ;# J4.D9  LA01_N_CC
#set_property -dict {LOC AD2  IOSTANDARD LVDS DIFF_TERM_ADV TERM_100} [get_ports {fmc_hpc1_la_p[2]}]  ;# J4.H7  LA02_P
#set_property -dict {LOC AD1  IOSTANDARD LVDS DIFF_TERM_ADV TERM_100} [get_ports {fmc_hpc1_la_n[2]}]  ;# J4.H8  LA02_N
#set_property -dict {LOC AH1  IOSTANDARD LVDS DIFF_TERM_ADV TERM_100} [get_ports {fmc_hpc1_la_p[3]}]  ;# J4.G12 LA03_P
#set_property -dict {LOC AJ1  IOSTANDARD LVDS DIFF_TERM_ADV TERM_100} [get_ports {fmc_hpc1_la_n[3]}]  ;# J4.G13 LA03_N
#set_property -dict {LOC AF2  IOSTANDARD LVDS DIFF_TERM_ADV TERM_100} [get_ports {fmc_hpc1_la_p[4]}]  ;# J4.H10 LA04_P
#set_property -dict {LOC AF1  IOSTANDARD LVDS DIFF_TERM_ADV TERM_100} [get_ports {fmc_hpc1_la_n[4]}]  ;# J4.H11 LA04_N
#set_property -dict {LOC AG3  IOSTANDARD LVDS DIFF_TERM_ADV TERM_100} [get_ports {fmc_hpc1_la_p[5]}]  ;# J4.D11 LA05_P
#set_property -dict {LOC AH3  IOSTANDARD LVDS DIFF_TERM_ADV TERM_100} [get_ports {fmc_hpc1_la_n[5]}]  ;# J4.D12 LA05_N
#set_property -dict {LOC AH2  IOSTANDARD LVDS DIFF_TERM_ADV TERM_100} [get_ports {fmc_hpc1_la_p[6]}]  ;# J4.C10 LA06_P
#set_property -dict {LOC AJ2  IOSTANDARD LVDS DIFF_TERM_ADV TERM_100} [get_ports {fmc_hpc1_la_n[6]}]  ;# J4.C11 LA06_N
#set_property -dict {LOC AD4  IOSTANDARD LVDS DIFF_TERM_ADV TERM_100} [get_ports {fmc_hpc1_la_p[7]}]  ;# J4.H13 LA07_P
#set_property -dict {LOC AE4  IOSTANDARD LVDS DIFF_TERM_ADV TERM_100} [get_ports {fmc_hpc1_la_n[7]}]  ;# J4.H14 LA07_N
#set_property -dict {LOC AE3  IOSTANDARD LVDS DIFF_TERM_ADV TERM_100} [get_ports {fmc_hpc1_la_p[8]}]  ;# J4.G12 LA08_P
#set_property -dict {LOC AF3  IOSTANDARD LVDS DIFF_TERM_ADV TERM_100} [get_ports {fmc_hpc1_la_n[8]}]  ;# J4.G13 LA08_N
#set_property -dict {LOC AE2  IOSTANDARD LVDS DIFF_TERM_ADV TERM_100} [get_ports {fmc_hpc1_la_p[9]}]  ;# J4.D14 LA09_P
#set_property -dict {LOC AE1  IOSTANDARD LVDS DIFF_TERM_ADV TERM_100} [get_ports {fmc_hpc1_la_n[9]}]  ;# J4.D15 LA09_N
#set_property -dict {LOC AH4  IOSTANDARD LVDS DIFF_TERM_ADV TERM_100} [get_ports {fmc_hpc1_la_p[10]}] ;# J4.C14 LA10_P
#set_property -dict {LOC AJ4  IOSTANDARD LVDS DIFF_TERM_ADV TERM_100} [get_ports {fmc_hpc1_la_n[10]}] ;# J4.C15 LA10_N
#set_property -dict {LOC AE8  IOSTANDARD LVDS DIFF_TERM_ADV TERM_100} [get_ports {fmc_hpc1_la_p[11]}] ;# J4.H16 LA11_P
#set_property -dict {LOC AF8  IOSTANDARD LVDS DIFF_TERM_ADV TERM_100} [get_ports {fmc_hpc1_la_n[11]}] ;# J4.H17 LA11_N
#set_property -dict {LOC AD7  IOSTANDARD LVDS DIFF_TERM_ADV TERM_100} [get_ports {fmc_hpc1_la_p[12]}] ;# J4.G15 LA12_P
#set_property -dict {LOC AD6  IOSTANDARD LVDS DIFF_TERM_ADV TERM_100} [get_ports {fmc_hpc1_la_n[12]}] ;# J4.G16 LA12_N
#set_property -dict {LOC AG8  IOSTANDARD LVDS DIFF_TERM_ADV TERM_100} [get_ports {fmc_hpc1_la_p[13]}] ;# J4.D17 LA13_P
#set_property -dict {LOC AH8  IOSTANDARD LVDS DIFF_TERM_ADV TERM_100} [get_ports {fmc_hpc1_la_n[13]}] ;# J4.D18 LA13_N
#set_property -dict {LOC AH7  IOSTANDARD LVDS DIFF_TERM_ADV TERM_100} [get_ports {fmc_hpc1_la_p[14]}] ;# J4.C18 LA14_P
#set_property -dict {LOC AH6  IOSTANDARD LVDS DIFF_TERM_ADV TERM_100} [get_ports {fmc_hpc1_la_n[14]}] ;# J4.C19 LA14_N
#set_property -dict {LOC AD10 IOSTANDARD LVDS DIFF_TERM_ADV TERM_100} [get_ports {fmc_hpc1_la_p[15]}] ;# J4.H19 LA15_P
#set_property -dict {LOC AE9  IOSTANDARD LVDS DIFF_TERM_ADV TERM_100} [get_ports {fmc_hpc1_la_n[15]}] ;# J4.H20 LA15_N
#set_property -dict {LOC AG10 IOSTANDARD LVDS DIFF_TERM_ADV TERM_100} [get_ports {fmc_hpc1_la_p[16]}] ;# J4.G18 LA16_P
#set_property -dict {LOC AG9  IOSTANDARD LVDS DIFF_TERM_ADV TERM_100} [get_ports {fmc_hpc1_la_n[16]}] ;# J4.G19 LA16_N
#set_property -dict {LOC Y5   IOSTANDARD LVDS DIFF_TERM_ADV TERM_100} [get_ports {fmc_hpc1_la_p[17]}] ;# J4.D20 LA17_P_CC
#set_property -dict {LOC AA5  IOSTANDARD LVDS DIFF_TERM_ADV TERM_100} [get_ports {fmc_hpc1_la_n[17]}] ;# J4.D21 LA17_N_CC
#set_property -dict {LOC Y8   IOSTANDARD LVDS DIFF_TERM_ADV TERM_100} [get_ports {fmc_hpc1_la_p[18]}] ;# J4.C22 LA18_P_CC
#set_property -dict {LOC Y7   IOSTANDARD LVDS DIFF_TERM_ADV TERM_100} [get_ports {fmc_hpc1_la_n[18]}] ;# J4.C23 LA18_N_CC
#set_property -dict {LOC AA11 IOSTANDARD LVDS DIFF_TERM_ADV TERM_100} [get_ports {fmc_hpc1_la_p[19]}] ;# J4.H22 LA19_P
#set_property -dict {LOC AA10 IOSTANDARD LVDS DIFF_TERM_ADV TERM_100} [get_ports {fmc_hpc1_la_n[19]}] ;# J4.H23 LA19_N
#set_property -dict {LOC AB11 IOSTANDARD LVDS DIFF_TERM_ADV TERM_100} [get_ports {fmc_hpc1_la_p[20]}] ;# J4.G21 LA20_P
#set_property -dict {LOC AB10 IOSTANDARD LVDS DIFF_TERM_ADV TERM_100} [get_ports {fmc_hpc1_la_n[20]}] ;# J4.G22 LA20_N
#set_property -dict {LOC AC12 IOSTANDARD LVDS DIFF_TERM_ADV TERM_100} [get_ports {fmc_hpc1_la_p[21]}] ;# J4.H25 LA21_P
#set_property -dict {LOC AC11 IOSTANDARD LVDS DIFF_TERM_ADV TERM_100} [get_ports {fmc_hpc1_la_n[21]}] ;# J4.H26 LA21_N
#set_property -dict {LOC AF11 IOSTANDARD LVDS DIFF_TERM_ADV TERM_100} [get_ports {fmc_hpc1_la_p[22]}] ;# J4.G24 LA22_P
#set_property -dict {LOC AG11 IOSTANDARD LVDS DIFF_TERM_ADV TERM_100} [get_ports {fmc_hpc1_la_n[22]}] ;# J4.G25 LA22_N
#set_property -dict {LOC AE12 IOSTANDARD LVDS DIFF_TERM_ADV TERM_100} [get_ports {fmc_hpc1_la_p[23]}] ;# J4.D23 LA23_P
#set_property -dict {LOC AF12 IOSTANDARD LVDS DIFF_TERM_ADV TERM_100} [get_ports {fmc_hpc1_la_n[23]}] ;# J4.D24 LA23_N
#set_property -dict {LOC AH12 IOSTANDARD LVDS DIFF_TERM_ADV TERM_100} [get_ports {fmc_hpc1_la_p[24]}] ;# J4.H28 LA24_P
#set_property -dict {LOC AH11 IOSTANDARD LVDS DIFF_TERM_ADV TERM_100} [get_ports {fmc_hpc1_la_n[24]}] ;# J4.H29 LA24_N
#set_property -dict {LOC AE10 IOSTANDARD LVDS DIFF_TERM_ADV TERM_100} [get_ports {fmc_hpc1_la_p[25]}] ;# J4.G27 LA25_P
#set_property -dict {LOC AF10 IOSTANDARD LVDS DIFF_TERM_ADV TERM_100} [get_ports {fmc_hpc1_la_n[25]}] ;# J4.G28 LA25_N
#set_property -dict {LOC T12  IOSTANDARD LVDS DIFF_TERM_ADV TERM_100} [get_ports {fmc_hpc1_la_p[26]}] ;# J4.D26 LA26_P
#set_property -dict {LOC R12  IOSTANDARD LVDS DIFF_TERM_ADV TERM_100} [get_ports {fmc_hpc1_la_n[26]}] ;# J4.D27 LA26_N
#set_property -dict {LOC U10  IOSTANDARD LVDS DIFF_TERM_ADV TERM_100} [get_ports {fmc_hpc1_la_p[27]}] ;# J4.C26 LA27_P
#set_property -dict {LOC T10  IOSTANDARD LVDS DIFF_TERM_ADV TERM_100} [get_ports {fmc_hpc1_la_n[27]}] ;# J4.C27 LA27_N
#set_property -dict {LOC T13  IOSTANDARD LVDS DIFF_TERM_ADV TERM_100} [get_ports {fmc_hpc1_la_p[28]}] ;# J4.H31 LA28_P
#set_property -dict {LOC R13  IOSTANDARD LVDS DIFF_TERM_ADV TERM_100} [get_ports {fmc_hpc1_la_n[28]}] ;# J4.H32 LA28_N
#set_property -dict {LOC W12  IOSTANDARD LVDS DIFF_TERM_ADV TERM_100} [get_ports {fmc_hpc1_la_p[29]}] ;# J4.G30 LA29_P
#set_property -dict {LOC W11  IOSTANDARD LVDS DIFF_TERM_ADV TERM_100} [get_ports {fmc_hpc1_la_n[29]}] ;# J4.G31 LA29_N

#set_property -dict {LOC AE7  IOSTANDARD LVDS DIFF_TERM_ADV TERM_100} [get_ports {fmc_hpc1_clk0_m2c_p}] ;# J4.H4 CLK0_M2C_P
#set_property -dict {LOC AF7  IOSTANDARD LVDS DIFF_TERM_ADV TERM_100} [get_ports {fmc_hpc1_clk0_m2c_n}] ;# J4.H5 CLK0_M2C_N
#set_property -dict {LOC P10  IOSTANDARD LVDS DIFF_TERM_ADV TERM_100} [get_ports {fmc_hpc1_clk1_m2c_p}] ;# J4.G2 CLK1_M2C_P
#set_property -dict {LOC P9   IOSTANDARD LVDS DIFF_TERM_ADV TERM_100} [get_ports {fmc_hpc1_clk1_m2c_n}] ;# J4.G3 CLK1_M2C_N

#set_property -dict {LOC F29 } [get_ports {fmc_hpc1_dp_c2m_p[0]}] ;# MGTHTXP0_130 GTHE4_CHANNEL_X0Y14 / GTHE4_COMMON_X0Y3 from J4.C2  DP0_C2M_P
#set_property -dict {LOC F30 } [get_ports {fmc_hpc1_dp_c2m_n[0]}] ;# MGTHTXN0_130 GTHE4_CHANNEL_X0Y14 / GTHE4_COMMON_X0Y3 from J4.C3  DP0_C2M_N
#set_property -dict {LOC E31 } [get_ports {fmc_hpc1_dp_m2c_p[0]}] ;# MGTHRXP0_130 GTHE4_CHANNEL_X0Y14 / GTHE4_COMMON_X0Y3 from J4.C6  DP0_M2C_P
#set_property -dict {LOC E32 } [get_ports {fmc_hpc1_dp_m2c_n[0]}] ;# MGTHRXN0_130 GTHE4_CHANNEL_X0Y14 / GTHE4_COMMON_X0Y3 from J4.C7  DP0_M2C_N
#set_property -dict {LOC D29 } [get_ports {fmc_hpc1_dp_c2m_p[1]}] ;# MGTHTXP1_130 GTHE4_CHANNEL_X0Y13 / GTHE4_COMMON_X0Y3 from J4.A22 DP1_C2M_P
#set_property -dict {LOC D30 } [get_ports {fmc_hpc1_dp_c2m_n[1]}] ;# MGTHTXN1_130 GTHE4_CHANNEL_X0Y13 / GTHE4_COMMON_X0Y3 from J4.A23 DP1_C2M_N
#set_property -dict {LOC D33 } [get_ports {fmc_hpc1_dp_m2c_p[1]}] ;# MGTHRXP1_130 GTHE4_CHANNEL_X0Y13 / GTHE4_COMMON_X0Y3 from J4.A2  DP1_M2C_P
#set_property -dict {LOC D34 } [get_ports {fmc_hpc1_dp_m2c_n[1]}] ;# MGTHRXN1_130 GTHE4_CHANNEL_X0Y13 / GTHE4_COMMON_X0Y3 from J4.A3  DP1_M2C_N
#set_property -dict {LOC B29 } [get_ports {fmc_hpc1_dp_c2m_p[2]}] ;# MGTHTXP2_130 GTHE4_CHANNEL_X0Y15 / GTHE4_COMMON_X0Y3 from J4.A26 DP2_C2M_P
#set_property -dict {LOC B30 } [get_ports {fmc_hpc1_dp_c2m_n[2]}] ;# MGTHTXN2_130 GTHE4_CHANNEL_X0Y15 / GTHE4_COMMON_X0Y3 from J4.A27 DP2_C2M_N
#set_property -dict {LOC C31 } [get_ports {fmc_hpc1_dp_m2c_p[2]}] ;# MGTHRXP2_130 GTHE4_CHANNEL_X0Y15 / GTHE4_COMMON_X0Y3 from J4.A6  DP2_M2C_P
#set_property -dict {LOC C32 } [get_ports {fmc_hpc1_dp_m2c_n[2]}] ;# MGTHRXN2_130 GTHE4_CHANNEL_X0Y15 / GTHE4_COMMON_X0Y3 from J4.A7  DP2_M2C_N
#set_property -dict {LOC A31 } [get_ports {fmc_hpc1_dp_c2m_p[3]}] ;# MGTHTXP3_130 GTHE4_CHANNEL_X0Y12 / GTHE4_COMMON_X0Y3 from J4.A30 DP3_C2M_P
#set_property -dict {LOC A32 } [get_ports {fmc_hpc1_dp_c2m_n[3]}] ;# MGTHTXN3_130 GTHE4_CHANNEL_X0Y12 / GTHE4_COMMON_X0Y3 from J4.A31 DP3_C2M_N
#set_property -dict {LOC B33 } [get_ports {fmc_hpc1_dp_m2c_p[3]}] ;# MGTHRXP3_130 GTHE4_CHANNEL_X0Y12 / GTHE4_COMMON_X0Y3 from J4.A10 DP3_M2C_P
#set_property -dict {LOC B34 } [get_ports {fmc_hpc1_dp_m2c_n[3]}] ;# MGTHRXN3_130 GTHE4_CHANNEL_X0Y12 / GTHE4_COMMON_X0Y3 from J4.A11 DP3_M2C_N

#set_property -dict {LOC K29 } [get_ports {fmc_hpc1_dp_c2m_p[4]}] ;# MGTHTXP0_129 GTHE4_CHANNEL_X0Y8  / GTHE4_COMMON_X0Y2 from J4.A34 DP4_C2M_P
#set_property -dict {LOC K30 } [get_ports {fmc_hpc1_dp_c2m_n[4]}] ;# MGTHTXN0_129 GTHE4_CHANNEL_X0Y8  / GTHE4_COMMON_X0Y2 from J4.A35 DP4_C2M_N
#set_property -dict {LOC L31 } [get_ports {fmc_hpc1_dp_m2c_p[4]}] ;# MGTHRXP0_129 GTHE4_CHANNEL_X0Y8  / GTHE4_COMMON_X0Y2 from J4.A14 DP4_M2C_P
#set_property -dict {LOC L32 } [get_ports {fmc_hpc1_dp_m2c_n[4]}] ;# MGTHRXN0_129 GTHE4_CHANNEL_X0Y8  / GTHE4_COMMON_X0Y2 from J4.A15 DP4_M2C_N
#set_property -dict {LOC J31 } [get_ports {fmc_hpc1_dp_c2m_p[5]}] ;# MGTHTXP1_129 GTHE4_CHANNEL_X0Y9  / GTHE4_COMMON_X0Y2 from J4.A38 DP5_C2M_P
#set_property -dict {LOC J32 } [get_ports {fmc_hpc1_dp_c2m_n[5]}] ;# MGTHTXN1_129 GTHE4_CHANNEL_X0Y9  / GTHE4_COMMON_X0Y2 from J4.A39 DP5_C2M_N
#set_property -dict {LOC K33 } [get_ports {fmc_hpc1_dp_m2c_p[5]}] ;# MGTHRXP1_129 GTHE4_CHANNEL_X0Y9  / GTHE4_COMMON_X0Y2 from J4.A18 DP5_M2C_P
#set_property -dict {LOC K34 } [get_ports {fmc_hpc1_dp_m2c_n[5]}] ;# MGTHRXN1_129 GTHE4_CHANNEL_X0Y9  / GTHE4_COMMON_X0Y2 from J4.A19 DP5_M2C_N
#set_property -dict {LOC H29 } [get_ports {fmc_hpc1_dp_c2m_p[6]}] ;# MGTHTXP2_129 GTHE4_CHANNEL_X0Y10 / GTHE4_COMMON_X0Y2 from J4.B36 DP6_C2M_P
#set_property -dict {LOC H30 } [get_ports {fmc_hpc1_dp_c2m_n[6]}] ;# MGTHTXN2_129 GTHE4_CHANNEL_X0Y10 / GTHE4_COMMON_X0Y2 from J4.B37 DP6_C2M_N
#set_property -dict {LOC H33 } [get_ports {fmc_hpc1_dp_m2c_p[6]}] ;# MGTHRXP2_129 GTHE4_CHANNEL_X0Y10 / GTHE4_COMMON_X0Y2 from J4.B16 DP6_M2C_P
#set_property -dict {LOC H34 } [get_ports {fmc_hpc1_dp_m2c_n[6]}] ;# MGTHRXN2_129 GTHE4_CHANNEL_X0Y10 / GTHE4_COMMON_X0Y2 from J4.B17 DP6_M2C_N
#set_property -dict {LOC G31 } [get_ports {fmc_hpc1_dp_c2m_p[7]}] ;# MGTHTXP3_129 GTHE4_CHANNEL_X0Y11 / GTHE4_COMMON_X0Y2 from J4.B32 DP7_C2M_P
#set_property -dict {LOC G32 } [get_ports {fmc_hpc1_dp_c2m_n[7]}] ;# MGTHTXN3_129 GTHE4_CHANNEL_X0Y11 / GTHE4_COMMON_X0Y2 from J4.B33 DP7_C2M_N
#set_property -dict {LOC F33 } [get_ports {fmc_hpc1_dp_m2c_p[7]}] ;# MGTHRXP3_129 GTHE4_CHANNEL_X0Y11 / GTHE4_COMMON_X0Y2 from J4.B12 DP7_M2C_P
#set_property -dict {LOC F34 } [get_ports {fmc_hpc1_dp_m2c_n[7]}] ;# MGTHRXN3_129 GTHE4_CHANNEL_X0Y11 / GTHE4_COMMON_X0Y2 from J4.B13 DP7_M2C_N
#set_property -dict {LOC G27 } [get_ports {fmc_hpc1_mgt_refclk_0_p}] ;# MGTREFCLK0P_130 from J4.D4 GBTCLK0_M2C_P
#set_property -dict {LOC G28 } [get_ports {fmc_hpc1_mgt_refclk_0_n}] ;# MGTREFCLK0N_130 from J4.D5 GBTCLK0_M2C_N
#set_property -dict {LOC E27 } [get_ports {fmc_hpc1_mgt_refclk_1_p}] ;# MGTREFCLK1P_130 from J4.B20 GBTCLK1_M2C_P
#set_property -dict {LOC E28 } [get_ports {fmc_hpc1_mgt_refclk_1_n}] ;# MGTREFCLK1N_130 from J4.B21 GBTCLK1_M2C_N
#set_property -dict {LOC L27 } [get_ports {fmc_hpc1_mgt_refclk_2_p}] ;# MGTREFCLK0P_129 from U56 SI570 via U51 SI53340
#set_property -dict {LOC L28 } [get_ports {fmc_hpc1_mgt_refclk_2_n}] ;# MGTREFCLK0N_129 from U56 SI570 via U51 SI53340
#set_property -dict {LOC J27 } [get_ports {fmc_hpc1_mgt_refclk_3_p}] ;# MGTREFCLK1P_129 from J79
#set_property -dict {LOC J28 } [get_ports {fmc_hpc1_mgt_refclk_3_n}] ;# MGTREFCLK1N_129 from J80

# reference clock
#create_clock -period 6.400 -name fmc_hpc1_mgt_refclk_0 [get_ports {fmc_hpc1_mgt_refclk_0_p}]
#create_clock -period 6.400 -name fmc_hpc1_mgt_refclk_1 [get_ports {fmc_hpc1_mgt_refclk_1_p}]

# DDR4
# 1x MT40A256M16GE-075E
#set_property -dict {LOC AM8  IOSTANDARD SSTL12_DCI     } [get_ports {ddr4_adr[0]}]
#set_property -dict {LOC AM9  IOSTANDARD SSTL12_DCI     } [get_ports {ddr4_adr[1]}]
#set_property -dict {LOC AP8  IOSTANDARD SSTL12_DCI     } [get_ports {ddr4_adr[2]}]
#set_property -dict {LOC AN8  IOSTANDARD SSTL12_DCI     } [get_ports {ddr4_adr[3]}]
#set_property -dict {LOC AK10 IOSTANDARD SSTL12_DCI     } [get_ports {ddr4_adr[4]}]
#set_property -dict {LOC AJ10 IOSTANDARD SSTL12_DCI     } [get_ports {ddr4_adr[5]}]
#set_property -dict {LOC AP9  IOSTANDARD SSTL12_DCI     } [get_ports {ddr4_adr[6]}]
#set_property -dict {LOC AN9  IOSTANDARD SSTL12_DCI     } [get_ports {ddr4_adr[7]}]
#set_property -dict {LOC AP10 IOSTANDARD SSTL12_DCI     } [get_ports {ddr4_adr[8]}]
#set_property -dict {LOC AP11 IOSTANDARD SSTL12_DCI     } [get_ports {ddr4_adr[9]}]
#set_property -dict {LOC AM10 IOSTANDARD SSTL12_DCI     } [get_ports {ddr4_adr[10]}]
#set_property -dict {LOC AL10 IOSTANDARD SSTL12_DCI     } [get_ports {ddr4_adr[11]}]
#set_property -dict {LOC AM11 IOSTANDARD SSTL12_DCI     } [get_ports {ddr4_adr[12]}]
#set_property -dict {LOC AL11 IOSTANDARD SSTL12_DCI     } [get_ports {ddr4_adr[13]}]
#set_property -dict {LOC AJ7  IOSTANDARD SSTL12_DCI     } [get_ports {ddr4_adr[14]}]
#set_property -dict {LOC AL5  IOSTANDARD SSTL12_DCI     } [get_ports {ddr4_adr[15]}]
#set_property -dict {LOC AJ9  IOSTANDARD SSTL12_DCI     } [get_ports {ddr4_adr[16]}]
#set_property -dict {LOC AK12 IOSTANDARD SSTL12_DCI     } [get_ports {ddr4_ba[0]}]
#set_property -dict {LOC AJ12 IOSTANDARD SSTL12_DCI     } [get_ports {ddr4_ba[1]}]
#set_property -dict {LOC AK7  IOSTANDARD SSTL12_DCI     } [get_ports {ddr4_bg[0]}]
#set_property -dict {LOC AN7  IOSTANDARD DIFF_SSTL12_DCI} [get_ports {ddr4_ck_t}]
#set_property -dict {LOC AP7  IOSTANDARD DIFF_SSTL12_DCI} [get_ports {ddr4_ck_c}]
#set_property -dict {LOC AM3  IOSTANDARD SSTL12_DCI     } [get_ports {ddr4_cke}]
#set_property -dict {LOC AP2  IOSTANDARD SSTL12_DCI     } [get_ports {ddr4_cs_n}]
#set_property -dict {LOC AK8  IOSTANDARD SSTL12_DCI     } [get_ports {ddr4_act_n}]
#set_property -dict {LOC AK9  IOSTANDARD SSTL12_DCI     } [get_ports {ddr4_odt}]
#set_property -dict {LOC AP1  IOSTANDARD SSTL12_DCI     } [get_ports {ddr4_par}]
#set_property -dict {LOC AH9  IOSTANDARD LVCMOS12       } [get_ports {ddr4_reset_n}]

#set_property -dict {LOC AK4  IOSTANDARD POD12_DCI      } [get_ports {ddr4_dq[0]}]       ;# U2.G2 DQL0
#set_property -dict {LOC AK5  IOSTANDARD POD12_DCI      } [get_ports {ddr4_dq[1]}]       ;# U2.F7 DQL1
#set_property -dict {LOC AN4  IOSTANDARD POD12_DCI      } [get_ports {ddr4_dq[2]}]       ;# U2.H3 DQL2
#set_property -dict {LOC AM4  IOSTANDARD POD12_DCI      } [get_ports {ddr4_dq[3]}]       ;# U2.H7 DQL3
#set_property -dict {LOC AP4  IOSTANDARD POD12_DCI      } [get_ports {ddr4_dq[4]}]       ;# U2.H2 DQL4
#set_property -dict {LOC AP5  IOSTANDARD POD12_DCI      } [get_ports {ddr4_dq[5]}]       ;# U2.H8 DQL5
#set_property -dict {LOC AM5  IOSTANDARD POD12_DCI      } [get_ports {ddr4_dq[6]}]       ;# U2.J3 DQL6
#set_property -dict {LOC AM6  IOSTANDARD POD12_DCI      } [get_ports {ddr4_dq[7]}]       ;# U2.J7 DQL7
#set_property -dict {LOC AK2  IOSTANDARD POD12_DCI      } [get_ports {ddr4_dq[8]}]       ;# U2.A3 DQU0
#set_property -dict {LOC AK3  IOSTANDARD POD12_DCI      } [get_ports {ddr4_dq[9]}]       ;# U2.B8 DQU1
#set_property -dict {LOC AL1  IOSTANDARD POD12_DCI      } [get_ports {ddr4_dq[10]}]      ;# U2.C3 DQU2
#set_property -dict {LOC AK1  IOSTANDARD POD12_DCI      } [get_ports {ddr4_dq[11]}]      ;# U2.C7 DQU3
#set_property -dict {LOC AN1  IOSTANDARD POD12_DCI      } [get_ports {ddr4_dq[12]}]      ;# U2.C2 DQU4
#set_property -dict {LOC AM1  IOSTANDARD POD12_DCI      } [get_ports {ddr4_dq[13]}]      ;# U2.C8 DQU5
#set_property -dict {LOC AP3  IOSTANDARD POD12_DCI      } [get_ports {ddr4_dq[14]}]      ;# U2.D3 DQU6
#set_property -dict {LOC AN3  IOSTANDARD POD12_DCI      } [get_ports {ddr4_dq[15]}]      ;# U2.D7 DQU7
#set_property -dict {LOC AN6  IOSTANDARD DIFF_POD12_DCI } [get_ports {ddr4_dqs_t[0]}]    ;# U2.G3 DQSL_T
#set_property -dict {LOC AP6  IOSTANDARD DIFF_POD12_DCI } [get_ports {ddr4_dqs_c[0]}]    ;# U2.F3 DQSL_C
#set_property -dict {LOC AL3  IOSTANDARD DIFF_POD12_DCI } [get_ports {ddr4_dqs_t[1]}]    ;# U2.B7 DQSU_T
#set_property -dict {LOC AL2  IOSTANDARD DIFF_POD12_DCI } [get_ports {ddr4_dqs_c[1]}]    ;# U2.A7 DQSU_C
#set_property -dict {LOC AL6  IOSTANDARD POD12_DCI      } [get_ports {ddr4_dm_dbi_n[0]}] ;# U2.E7 DML_B/DBIL_B
#set_property -dict {LOC AN2  IOSTANDARD POD12_DCI      } [get_ports {ddr4_dm_dbi_n[1]}] ;# U2.E2 DMU_B/DBIU_B
