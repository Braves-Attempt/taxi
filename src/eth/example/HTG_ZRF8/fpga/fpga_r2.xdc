# SPDX-License-Identifier: MIT
#
# Copyright (c) 2025 FPGA Ninja, LLC
#
# Authors:
# - Alex Forencich
#

# XDC constraints for the HiTech Global HTG-ZRF8-R2 board
# part: xczu28dr-ffvg1517-2-e
# part: xczu48dr-ffvg1517-2-e

# General configuration
set_property BITSTREAM.GENERAL.COMPRESS true           [current_design]

# System clocks
# DDR4 clocks from U48 (300 MHz)
#set_property -dict {LOC G13  IOSTANDARD DIFF_SSTL12} [get_ports sys_clk_ddr4_p] ;# U48.28 OUT1_P
#set_property -dict {LOC G12  IOSTANDARD DIFF_SSTL12} [get_ports sys_clk_ddr4_n] ;# U48.27 OUT1_N
#create_clock -period 3.333 -name sys_clk_ddr4 [get_ports sys_clk_ddr4_p]

# User clock 1 from U48 (200 MHz)
set_property -dict {LOC C8   IOSTANDARD LVDS_25} [get_ports clk_pl_user1_p] ;# U48.24 OUT0_P
set_property -dict {LOC C7   IOSTANDARD LVDS_25} [get_ports clk_pl_user1_n] ;# U48.23 OUT0_N
create_clock -period 5.000 -name clk_pl_user1 [get_ports clk_pl_user1_p]

# Source pin is in an HDIO bank, so it must be routed to an MMCM via a BUFG
set_property CLOCK_DEDICATED_ROUTE ANY_CMT_COLUMN [get_nets clk_pl_user1_bufg]

# User clock 2 from U48 (200 MHz)
#set_property -dict {LOC AM15 IOSTANDARD LVDS} [get_ports clk_pl_user2_p] ;# U48.42 OUT5_P
#set_property -dict {LOC AN15 IOSTANDARD LVDS} [get_ports clk_pl_user2_n] ;# U48.41 OUT5_N
#create_clock -period 5.000 -name clk_pl_user2 [get_ports clk_pl_user2_p]

# PLL refclk from U78 (250 MHz)
set_property -dict {LOC AV6  IOSTANDARD LVDS_25} [get_ports fpga_refclk_p] ;# U78.51 CLKout8_P
set_property -dict {LOC AV5  IOSTANDARD LVDS_25} [get_ports fpga_refclk_n] ;# U78.52 CLKout8_N
create_clock -period 4.000 -name fpga_refclk [get_ports fpga_refclk_p]

# Source pin is in an HDIO bank, so it must be routed to an MMCM via a BUFG
set_property CLOCK_DEDICATED_ROUTE ANY_CMT_COLUMN [get_nets fpga_refclk_int fpga_refclk_bufg_inst_n_0]

# PLL sysref from U78
set_property -dict {LOC AP20 IOSTANDARD LVDS} [get_ports fpga_sysref_p] ;# U78.22 CLKout5_P
set_property -dict {LOC AP19 IOSTANDARD LVDS} [get_ports fpga_sysref_n] ;# U78.23 CLKout5_N
create_clock -period 100.000 -name fpga_sysref [get_ports fpga_sysref_p]

# PLL control
set_property -dict {LOC AU4  IOSTANDARD LVCMOS33 SLEW SLOW DRIVE 8} [get_ports {clk_fdec}]
set_property -dict {LOC AV2  IOSTANDARD LVCMOS33 SLEW SLOW DRIVE 8} [get_ports {clk_finc}]
set_property -dict {LOC AU1  IOSTANDARD LVCMOS33} [get_ports {clk_intr_n}]
set_property -dict {LOC AV3  IOSTANDARD LVCMOS33} [get_ports {clk_lol_n}]
set_property -dict {LOC AU3  IOSTANDARD LVCMOS33 SLEW SLOW DRIVE 8} [get_ports {clk_sync_n}]
set_property -dict {LOC AU2  IOSTANDARD LVCMOS33 SLEW SLOW DRIVE 8} [get_ports {clk_rst_n}]

set_property -dict {LOC AW6  IOSTANDARD LVCMOS33 SLEW SLOW DRIVE 8} [get_ports {lmk_rst}]
set_property -dict {LOC AW4  IOSTANDARD LVCMOS33 SLEW SLOW DRIVE 8} [get_ports {lmk_clkin_s[0]}]
set_property -dict {LOC AW3  IOSTANDARD LVCMOS33 SLEW SLOW DRIVE 8} [get_ports {lmk_clkin_s[1]}]

set_false_path -to [get_ports {clk_fdec clk_finc clk_sync_n clk_rst_n}]
set_output_delay 0 [get_ports {clk_fdec clk_finc clk_sync_n clk_rst_n}]
set_false_path -from [get_ports {clk_intr_n clk_lol_n}]
set_input_delay 0 [get_ports {clk_intr_n clk_lol_n}]

set_false_path -to [get_ports {lmk_rst}]
set_output_delay 0 [get_ports {lmk_rst}]

# LEDs
set_property -dict {LOC A6   IOSTANDARD LVCMOS33 SLEW SLOW DRIVE 8} [get_ports {led[0]}] ;# D10
set_property -dict {LOC C6   IOSTANDARD LVCMOS33 SLEW SLOW DRIVE 8} [get_ports {led[1]}] ;# D9
set_property -dict {LOC D6   IOSTANDARD LVCMOS33 SLEW SLOW DRIVE 8} [get_ports {led[2]}] ;# D8
set_property -dict {LOC E6   IOSTANDARD LVCMOS33 SLEW SLOW DRIVE 8} [get_ports {led[3]}] ;# D7

set_false_path -to [get_ports {led[*]}]
set_output_delay 0 [get_ports {led[*]}]

# Push buttons
set_property -dict {LOC AT5  IOSTANDARD LVCMOS33} [get_ports {btn}] ;# PB3

set_false_path -from [get_ports {btn}]
set_input_delay 0 [get_ports {btn}]

# DIP switches
set_property -dict {LOC D20  IOSTANDARD LVCMOS12} [get_ports {sw[0]}] ;# S1.1
set_property -dict {LOC A25  IOSTANDARD LVCMOS12} [get_ports {sw[1]}] ;# S1.2
set_property -dict {LOC B23  IOSTANDARD LVCMOS12} [get_ports {sw[2]}] ;# S1.3
set_property -dict {LOC D19  IOSTANDARD LVCMOS12} [get_ports {sw[3]}] ;# S1.4

set_false_path -from [get_ports {sw[*]}]
set_input_delay 0 [get_ports {sw[*]}]

# Trace
#set_property -dict {LOC AR16 IOSTANDARD LVCMOS18 SLEW FAST DRIVE 8} [get_ports {trace_data[0]}]  ;# J22.38
#set_property -dict {LOC AN17 IOSTANDARD LVCMOS18 SLEW FAST DRIVE 8} [get_ports {trace_data[1]}]  ;# J22.28
#set_property -dict {LOC AM17 IOSTANDARD LVCMOS18 SLEW FAST DRIVE 8} [get_ports {trace_data[2]}]  ;# J22.26
#set_property -dict {LOC AF16 IOSTANDARD LVCMOS18 SLEW FAST DRIVE 8} [get_ports {trace_data[3]}]  ;# J22.24
#set_property -dict {LOC AP14 IOSTANDARD LVCMOS18 SLEW FAST DRIVE 8} [get_ports {trace_data[4]}]  ;# J22.22
#set_property -dict {LOC AR14 IOSTANDARD LVCMOS18 SLEW FAST DRIVE 8} [get_ports {trace_data[5]}]  ;# J22.20
#set_property -dict {LOC AT13 IOSTANDARD LVCMOS18 SLEW FAST DRIVE 8} [get_ports {trace_data[6]}]  ;# J22.18
#set_property -dict {LOC AT15 IOSTANDARD LVCMOS18 SLEW FAST DRIVE 8} [get_ports {trace_data[7]}]  ;# J22.16
#set_property -dict {LOC AN16 IOSTANDARD LVCMOS18 SLEW FAST DRIVE 8} [get_ports {trace_data[8]}]  ;# J22.37
#set_property -dict {LOC AK17 IOSTANDARD LVCMOS18 SLEW FAST DRIVE 8} [get_ports {trace_data[9]}]  ;# J22.35
#set_property -dict {LOC AR13 IOSTANDARD LVCMOS18 SLEW FAST DRIVE 8} [get_ports {trace_data[10]}] ;# J22.33
#set_property -dict {LOC AU13 IOSTANDARD LVCMOS18 SLEW FAST DRIVE 8} [get_ports {trace_data[11]}] ;# J22.31
#set_property -dict {LOC AK16 IOSTANDARD LVCMOS18 SLEW FAST DRIVE 8} [get_ports {trace_data[12]}] ;# J22.29
#set_property -dict {LOC AL15 IOSTANDARD LVCMOS18 SLEW FAST DRIVE 8} [get_ports {trace_data[13]}] ;# J22.27
#set_property -dict {LOC AH14 IOSTANDARD LVCMOS18 SLEW FAST DRIVE 8} [get_ports {trace_data[14]}] ;# J22.25
#set_property -dict {LOC AJ16 IOSTANDARD LVCMOS18 SLEW FAST DRIVE 8} [get_ports {trace_data[15]}] ;# J22.23
#set_property -dict {LOC AL16 IOSTANDARD LVCMOS18 SLEW FAST DRIVE 8} [get_ports {trace_clk}]      ;# J22.6
#set_property -dict {LOC AT16 IOSTANDARD LVCMOS18 SLEW FAST DRIVE 8} [get_ports {trace_tdi}]      ;# J22.19
#set_property -dict {LOC AH16 IOSTANDARD LVCMOS18 SLEW FAST DRIVE 8} [get_ports {trace_tdo}]      ;# J22.11
#set_property -dict {LOC AF17 IOSTANDARD LVCMOS18 SLEW FAST DRIVE 8} [get_ports {trace_tms}]      ;# J22.17
#set_property -dict {LOC AG17 IOSTANDARD LVCMOS18 SLEW FAST DRIVE 8} [get_ports {trace_tck}]      ;# J22.15
#set_property -dict {LOC AL17 IOSTANDARD LVCMOS18 SLEW FAST DRIVE 8} [get_ports {trace_rtck}]     ;# J22.13
#set_property -dict {LOC AJ15 IOSTANDARD LVCMOS18 SLEW FAST DRIVE 8} [get_ports {trace_dbgrq}]    ;# J22.7
#set_property -dict {LOC AU14 IOSTANDARD LVCMOS18 SLEW FAST DRIVE 8} [get_ports {trace_dbgack}]   ;# J22.8
#set_property -dict {LOC AP15 IOSTANDARD LVCMOS18 SLEW FAST DRIVE 8} [get_ports {trace_trst_b}]   ;# J22.21
#set_property -dict {LOC AH15 IOSTANDARD LVCMOS18 SLEW FAST DRIVE 8} [get_ports {trace_srst_b}]   ;# J22.9
#set_property -dict {LOC AP16 IOSTANDARD LVCMOS18 SLEW FAST DRIVE 8} [get_ports {trace_ctl}]      ;# J22.36
#set_property -dict {LOC AU15 IOSTANDARD LVCMOS18 SLEW FAST DRIVE 8} [get_ports {trace_exttrig}]  ;# J22.10

#set_false_path -to [get_ports {trace_data trace_clk trace_tdi trace_tdo trace_tms trace_tck trace_rtck trace_dbgrq trace_dbgack trace_rst_b trace_ctl trace_exttrig[*]}]
#set_output_delay 0 [get_ports {trace_data trace_clk trace_tdi trace_tdo trace_tms trace_tck trace_rtck trace_dbgrq trace_dbgack trace_rst_b trace_ctl trace_exttrig[*]}]

# UART
set_property -dict {LOC AU8  IOSTANDARD LVCMOS33 SLEW SLOW DRIVE 8} [get_ports uart_rxd]
set_property -dict {LOC AV8  IOSTANDARD LVCMOS33} [get_ports uart_txd]
set_property -dict {LOC AV7  IOSTANDARD LVCMOS33} [get_ports uart_rts]
set_property -dict {LOC AU7  IOSTANDARD LVCMOS33 SLEW SLOW DRIVE 8} [get_ports uart_cts]
set_property -dict {LOC AT7  IOSTANDARD LVCMOS33 SLEW SLOW DRIVE 8} [get_ports uart_rst_n]
set_property -dict {LOC AR7  IOSTANDARD LVCMOS33} [get_ports uart_suspend_n]

set_false_path -to [get_ports {uart_rxd uart_cts uart_rst_n}]
set_output_delay 0 [get_ports {uart_rxd uart_cts uart_rst_n}]
set_false_path -from [get_ports {uart_txd uart_rts uart_suspend_n}]
set_input_delay 0 [get_ports {uart_txd uart_rts uart_suspend_n}]

# I2C
set_property -dict {LOC E9   IOSTANDARD LVCMOS33 SLEW SLOW DRIVE 8} [get_ports i2c_scl]
set_property -dict {LOC E8   IOSTANDARD LVCMOS33 SLEW SLOW DRIVE 8} [get_ports i2c_sda]
set_property -dict {LOC D10  IOSTANDARD LVCMOS33 SLEW SLOW DRIVE 8} [get_ports i2c_rst_n]

set_false_path -to [get_ports {i2c_sda i2c_scl i2c_rst_n}]
set_output_delay 0 [get_ports {i2c_sda i2c_scl i2c_rst_n}]
set_false_path -from [get_ports {i2c_sda i2c_scl}]
set_input_delay 0 [get_ports {i2c_sda i2c_scl}]

# DDR4 SODIMM
#set_property -dict {LOC F11  IOSTANDARD SSTL12_DCI} [get_ports {ddr4_a[0]}]
#set_property -dict {LOC C13  IOSTANDARD SSTL12_DCI} [get_ports {ddr4_a[1]}]
#set_property -dict {LOC F14  IOSTANDARD SSTL12_DCI} [get_ports {ddr4_a[2]}]
#set_property -dict {LOC F10  IOSTANDARD SSTL12_DCI} [get_ports {ddr4_a[3]}]
#set_property -dict {LOC E11  IOSTANDARD SSTL12_DCI} [get_ports {ddr4_a[4]}]
#set_property -dict {LOC E13  IOSTANDARD SSTL12_DCI} [get_ports {ddr4_a[5]}]
#set_property -dict {LOC B13  IOSTANDARD SSTL12_DCI} [get_ports {ddr4_a[6]}]
#set_property -dict {LOC E12  IOSTANDARD SSTL12_DCI} [get_ports {ddr4_a[7]}]
#set_property -dict {LOC A11  IOSTANDARD SSTL12_DCI} [get_ports {ddr4_a[8]}]
#set_property -dict {LOC C12  IOSTANDARD SSTL12_DCI} [get_ports {ddr4_a[9]}]
#set_property -dict {LOC K13  IOSTANDARD SSTL12_DCI} [get_ports {ddr4_a[10]}]
#set_property -dict {LOC C15  IOSTANDARD SSTL12_DCI} [get_ports {ddr4_a[11]}]
#set_property -dict {LOC C11  IOSTANDARD SSTL12_DCI} [get_ports {ddr4_a[12]}]
#set_property -dict {LOC K10  IOSTANDARD SSTL12_DCI} [get_ports {ddr4_a[13]}]
#set_property -dict {LOC B14  IOSTANDARD SSTL12_DCI} [get_ports {ddr4_a[14]}]
#set_property -dict {LOC H12  IOSTANDARD SSTL12_DCI} [get_ports {ddr4_a[15]}]
#set_property -dict {LOC K12  IOSTANDARD SSTL12_DCI} [get_ports {ddr4_a[16]}]

#set_property -dict {LOC B15  IOSTANDARD SSTL12_DCI} [get_ports {ddr4_act_n}]
#set_property -dict {LOC D14  IOSTANDARD SSTL12_DCI} [get_ports {ddr4_alert_n}]

#set_property -dict {LOC H13  IOSTANDARD SSTL12_DCI} [get_ports {ddr4_ba[0]}]
#set_property -dict {LOC A14  IOSTANDARD SSTL12_DCI} [get_ports {ddr4_ba[1]}]
#set_property -dict {LOC B12  IOSTANDARD SSTL12_DCI} [get_ports {ddr4_bg[0]}]
#set_property -dict {LOC D11  IOSTANDARD SSTL12_DCI} [get_ports {ddr4_bg[1]}]

#set_property -dict {LOC A12  IOSTANDARD SSTL12_DCI} [get_ports {ddr4_cke[0]}]
#set_property -dict {LOC A15  IOSTANDARD SSTL12_DCI} [get_ports {ddr4_cke[1]}]
#set_property -dict {LOC J11  IOSTANDARD DIFF_SSTL2_DCI} [get_ports {ddr4_ck_t[0]}]
#set_property -dict {LOC J10  IOSTANDARD DIFF_SSTL2_DCI} [get_ports {ddr4_ck_c[0]}]
#set_property -dict {LOC J14  IOSTANDARD DIFF_SSTL2_DCI} [get_ports {ddr4_ck_t[1]}]
#set_property -dict {LOC J13  IOSTANDARD DIFF_SSTL2_DCI} [get_ports {ddr4_ck_c[1]}]
#set_property -dict {LOC H10  IOSTANDARD SSTL12_DCI} [get_ports {ddr4_cs_n[0]}]
#set_property -dict {LOC E14  IOSTANDARD SSTL12_DCI} [get_ports {ddr4_cs_n[1]}]
#set_property -dict {LOC K11  IOSTANDARD SSTL12_DCI} [get_ports {ddr4_cs_n[2]}]
#set_property -dict {LOC F12  IOSTANDARD SSTL12_DCI} [get_ports {ddr4_cs_n[3]}]

#set_property -dict {LOC M12  IOSTANDARD POD12_DCI} [get_ports {ddr4_dq[0]}]
#set_property -dict {LOC M13  IOSTANDARD POD12_DCI} [get_ports {ddr4_dq[1]}]
#set_property -dict {LOC N15  IOSTANDARD POD12_DCI} [get_ports {ddr4_dq[2]}]
#set_property -dict {LOC M17  IOSTANDARD POD12_DCI} [get_ports {ddr4_dq[3]}]
#set_property -dict {LOC L12  IOSTANDARD POD12_DCI} [get_ports {ddr4_dq[4]}]
#set_property -dict {LOC N13  IOSTANDARD POD12_DCI} [get_ports {ddr4_dq[5]}]
#set_property -dict {LOC M15  IOSTANDARD POD12_DCI} [get_ports {ddr4_dq[6]}]
#set_property -dict {LOC N17  IOSTANDARD POD12_DCI} [get_ports {ddr4_dq[7]}]
#set_property -dict {LOC K17  IOSTANDARD POD12_DCI} [get_ports {ddr4_dq[8]}]
#set_property -dict {LOC L17  IOSTANDARD POD12_DCI} [get_ports {ddr4_dq[9]}]
#set_property -dict {LOC J19  IOSTANDARD POD12_DCI} [get_ports {ddr4_dq[10]}]
#set_property -dict {LOC H16  IOSTANDARD POD12_DCI} [get_ports {ddr4_dq[11]}]
#set_property -dict {LOC J16  IOSTANDARD POD12_DCI} [get_ports {ddr4_dq[12]}]
#set_property -dict {LOC K16  IOSTANDARD POD12_DCI} [get_ports {ddr4_dq[13]}]
#set_property -dict {LOC H17  IOSTANDARD POD12_DCI} [get_ports {ddr4_dq[14]}]
#set_property -dict {LOC J18  IOSTANDARD POD12_DCI} [get_ports {ddr4_dq[15]}]
#set_property -dict {LOC E16  IOSTANDARD POD12_DCI} [get_ports {ddr4_dq[16]}]
#set_property -dict {LOC F15  IOSTANDARD POD12_DCI} [get_ports {ddr4_dq[17]}]
#set_property -dict {LOC E17  IOSTANDARD POD12_DCI} [get_ports {ddr4_dq[18]}]
#set_property -dict {LOC H18  IOSTANDARD POD12_DCI} [get_ports {ddr4_dq[19]}]
#set_property -dict {LOC F16  IOSTANDARD POD12_DCI} [get_ports {ddr4_dq[20]}]
#set_property -dict {LOC G15  IOSTANDARD POD12_DCI} [get_ports {ddr4_dq[21]}]
#set_property -dict {LOC E18  IOSTANDARD POD12_DCI} [get_ports {ddr4_dq[22]}]
#set_property -dict {LOC G18  IOSTANDARD POD12_DCI} [get_ports {ddr4_dq[23]}]
#set_property -dict {LOC C16  IOSTANDARD POD12_DCI} [get_ports {ddr4_dq[24]}]
#set_property -dict {LOC D15  IOSTANDARD POD12_DCI} [get_ports {ddr4_dq[25]}]
#set_property -dict {LOC C17  IOSTANDARD POD12_DCI} [get_ports {ddr4_dq[26]}]
#set_property -dict {LOC A19  IOSTANDARD POD12_DCI} [get_ports {ddr4_dq[27]}]
#set_property -dict {LOC A16  IOSTANDARD POD12_DCI} [get_ports {ddr4_dq[28]}]
#set_property -dict {LOC D16  IOSTANDARD POD12_DCI} [get_ports {ddr4_dq[29]}]
#set_property -dict {LOC A17  IOSTANDARD POD12_DCI} [get_ports {ddr4_dq[30]}]
#set_property -dict {LOC B19  IOSTANDARD POD12_DCI} [get_ports {ddr4_dq[31]}]
#set_property -dict {LOC H23  IOSTANDARD POD12_DCI} [get_ports {ddr4_dq[32]}]
#set_property -dict {LOC J21  IOSTANDARD POD12_DCI} [get_ports {ddr4_dq[33]}]
#set_property -dict {LOC H22  IOSTANDARD POD12_DCI} [get_ports {ddr4_dq[34]}]
#set_property -dict {LOC K24  IOSTANDARD POD12_DCI} [get_ports {ddr4_dq[35]}]
#set_property -dict {LOC G23  IOSTANDARD POD12_DCI} [get_ports {ddr4_dq[36]}]
#set_property -dict {LOC H21  IOSTANDARD POD12_DCI} [get_ports {ddr4_dq[37]}]
#set_property -dict {LOC G22  IOSTANDARD POD12_DCI} [get_ports {ddr4_dq[38]}]
#set_property -dict {LOC L24  IOSTANDARD POD12_DCI} [get_ports {ddr4_dq[39]}]
#set_property -dict {LOC E21  IOSTANDARD POD12_DCI} [get_ports {ddr4_dq[40]}]
#set_property -dict {LOC F20  IOSTANDARD POD12_DCI} [get_ports {ddr4_dq[41]}]
#set_property -dict {LOC E23  IOSTANDARD POD12_DCI} [get_ports {ddr4_dq[42]}]
#set_property -dict {LOC F24  IOSTANDARD POD12_DCI} [get_ports {ddr4_dq[43]}]
#set_property -dict {LOC D21  IOSTANDARD POD12_DCI} [get_ports {ddr4_dq[44]}]
#set_property -dict {LOC E22  IOSTANDARD POD12_DCI} [get_ports {ddr4_dq[45]}]
#set_property -dict {LOC E24  IOSTANDARD POD12_DCI} [get_ports {ddr4_dq[46]}]
#set_property -dict {LOC G20  IOSTANDARD POD12_DCI} [get_ports {ddr4_dq[47]}]
#set_property -dict {LOC C20  IOSTANDARD POD12_DCI} [get_ports {ddr4_dq[48]}]
#set_property -dict {LOC A20  IOSTANDARD POD12_DCI} [get_ports {ddr4_dq[49]}]
#set_property -dict {LOC B24  IOSTANDARD POD12_DCI} [get_ports {ddr4_dq[50]}]
#set_property -dict {LOC C21  IOSTANDARD POD12_DCI} [get_ports {ddr4_dq[51]}]
#set_property -dict {LOC B20  IOSTANDARD POD12_DCI} [get_ports {ddr4_dq[52]}]
#set_property -dict {LOC A21  IOSTANDARD POD12_DCI} [get_ports {ddr4_dq[53]}]
#set_property -dict {LOC C22  IOSTANDARD POD12_DCI} [get_ports {ddr4_dq[54]}]
#set_property -dict {LOC A24  IOSTANDARD POD12_DCI} [get_ports {ddr4_dq[55]}]
#set_property -dict {LOC L19  IOSTANDARD POD12_DCI} [get_ports {ddr4_dq[56]}]
#set_property -dict {LOC L21  IOSTANDARD POD12_DCI} [get_ports {ddr4_dq[57]}]
#set_property -dict {LOC L23  IOSTANDARD POD12_DCI} [get_ports {ddr4_dq[58]}]
#set_property -dict {LOC N19  IOSTANDARD POD12_DCI} [get_ports {ddr4_dq[59]}]
#set_property -dict {LOC L20  IOSTANDARD POD12_DCI} [get_ports {ddr4_dq[60]}]
#set_property -dict {LOC M19  IOSTANDARD POD12_DCI} [get_ports {ddr4_dq[61]}]
#set_property -dict {LOC L22  IOSTANDARD POD12_DCI} [get_ports {ddr4_dq[62]}]
#set_property -dict {LOC M20  IOSTANDARD POD12_DCI} [get_ports {ddr4_dq[63]}]
#set_property -dict {LOC F9   IOSTANDARD POD12_DCI} [get_ports {ddr4_dq[64]}]
#set_property -dict {LOC G7   IOSTANDARD POD12_DCI} [get_ports {ddr4_dq[65]}]
#set_property -dict {LOC H6   IOSTANDARD POD12_DCI} [get_ports {ddr4_dq[66]}]
#set_property -dict {LOC G6   IOSTANDARD POD12_DCI} [get_ports {ddr4_dq[67]}]
#set_property -dict {LOC G9   IOSTANDARD POD12_DCI} [get_ports {ddr4_dq[68]}]
#set_property -dict {LOC H7   IOSTANDARD POD12_DCI} [get_ports {ddr4_dq[69]}]
#set_property -dict {LOC K9   IOSTANDARD POD12_DCI} [get_ports {ddr4_dq[70]}]
#set_property -dict {LOC J9   IOSTANDARD POD12_DCI} [get_ports {ddr4_dq[71]}]

#set_property -dict {LOC L15  IOSTANDARD DIFF_POD12} [get_ports {ddr4_dqs_t[0]}]
#set_property -dict {LOC L14  IOSTANDARD DIFF_POD12} [get_ports {ddr4_dqs_c[0]}]
#set_property -dict {LOC K19  IOSTANDARD DIFF_POD12} [get_ports {ddr4_dqs_t[1]}]
#set_property -dict {LOC K18  IOSTANDARD DIFF_POD12} [get_ports {ddr4_dqs_c[1]}]
#set_property -dict {LOC G19  IOSTANDARD DIFF_POD12} [get_ports {ddr4_dqs_t[2]}]
#set_property -dict {LOC F19  IOSTANDARD DIFF_POD12} [get_ports {ddr4_dqs_c[2]}]
#set_property -dict {LOC B18  IOSTANDARD DIFF_POD12} [get_ports {ddr4_dqs_t[3]}]
#set_property -dict {LOC B17  IOSTANDARD DIFF_POD12} [get_ports {ddr4_dqs_c[3]}]
#set_property -dict {LOC J20  IOSTANDARD DIFF_POD12} [get_ports {ddr4_dqs_t[4]}]
#set_property -dict {LOC H20  IOSTANDARD DIFF_POD12} [get_ports {ddr4_dqs_c[4]}]
#set_property -dict {LOC D23  IOSTANDARD DIFF_POD12} [get_ports {ddr4_dqs_t[5]}]
#set_property -dict {LOC D24  IOSTANDARD DIFF_POD12} [get_ports {ddr4_dqs_c[5]}]
#set_property -dict {LOC B22  IOSTANDARD DIFF_POD12} [get_ports {ddr4_dqs_t[6]}]
#set_property -dict {LOC A22  IOSTANDARD DIFF_POD12} [get_ports {ddr4_dqs_c[6]}]
#set_property -dict {LOC K21  IOSTANDARD DIFF_POD12} [get_ports {ddr4_dqs_t[7]}]
#set_property -dict {LOC K22  IOSTANDARD DIFF_POD12} [get_ports {ddr4_dqs_c[7]}]
#set_property -dict {LOC H8   IOSTANDARD DIFF_POD12} [get_ports {ddr4_dqs_t[8]}]
#set_property -dict {LOC G8   IOSTANDARD DIFF_POD12} [get_ports {ddr4_dqs_c[8]}]

#set_property -dict {LOC N14  IOSTANDARD POD12_DCI} [get_ports {ddr4_dm_dbi_n[0]}]
#set_property -dict {LOC J15  IOSTANDARD POD12_DCI} [get_ports {ddr4_dm_dbi_n[1]}]
#set_property -dict {LOC G17  IOSTANDARD POD12_DCI} [get_ports {ddr4_dm_dbi_n[2]}]
#set_property -dict {LOC D18  IOSTANDARD POD12_DCI} [get_ports {ddr4_dm_dbi_n[3]}]
#set_property -dict {LOC J23  IOSTANDARD POD12_DCI} [get_ports {ddr4_dm_dbi_n[4]}]
#set_property -dict {LOC F21  IOSTANDARD POD12_DCI} [get_ports {ddr4_dm_dbi_n[5]}]
#set_property -dict {LOC C23  IOSTANDARD POD12_DCI} [get_ports {ddr4_dm_dbi_n[6]}]
#set_property -dict {LOC N20  IOSTANDARD POD12_DCI} [get_ports {ddr4_dm_dbi_n[7]}]
#set_property -dict {LOC J8   IOSTANDARD POD12_DCI} [get_ports {ddr4_dm_dbi_n[8]}]

#set_property -dict {LOC J7   IOSTANDARD LVCMOS12} [get_ports {ddr4_odt[0]}]
#set_property -dict {LOC H11  IOSTANDARD LVCMOS12} [get_ports {ddr4_odt[1]}]
#set_property -dict {LOC D13  IOSTANDARD LVCMOS12} [get_ports {ddr4_rst_n}]
#set_property -dict {LOC G10  IOSTANDARD LVCMOS12} [get_ports {ddr4_par}]
#set_property -dict {LOC G14  IOSTANDARD LVCMOS12} [get_ports {ddr4_event_n}]

# PCIe Interface
#set_property -dict {LOC J33 } [get_ports {pcie_tx_p[0]}] ;# MGTYTXP3_129 GTYE4_CHANNEL_X0Y7 / GTYE4_COMMON_X0Y1
#set_property -dict {LOC J34 } [get_ports {pcie_tx_n[0]}] ;# MGTYTXN3_129 GTYE4_CHANNEL_X0Y7 / GTYE4_COMMON_X0Y1
#set_property -dict {LOC K36 } [get_ports {pcie_rx_p[0]}] ;# MGTYRXP3_129 GTYE4_CHANNEL_X0Y7 / GTYE4_COMMON_X0Y1
#set_property -dict {LOC K37 } [get_ports {pcie_rx_n[0]}] ;# MGTYRXN3_129 GTYE4_CHANNEL_X0Y7 / GTYE4_COMMON_X0Y1
#set_property -dict {LOC L33 } [get_ports {pcie_tx_p[1]}] ;# MGTYTXP2_129 GTYE4_CHANNEL_X0Y6 / GTYE4_COMMON_X0Y1
#set_property -dict {LOC L34 } [get_ports {pcie_tx_n[1]}] ;# MGTYTXN2_129 GTYE4_CHANNEL_X0Y6 / GTYE4_COMMON_X0Y1
#set_property -dict {LOC L38 } [get_ports {pcie_rx_p[1]}] ;# MGTYRXP2_129 GTYE4_CHANNEL_X0Y6 / GTYE4_COMMON_X0Y1
#set_property -dict {LOC L39 } [get_ports {pcie_rx_n[1]}] ;# MGTYRXN2_129 GTYE4_CHANNEL_X0Y6 / GTYE4_COMMON_X0Y1
#set_property -dict {LOC N33 } [get_ports {pcie_tx_p[2]}] ;# MGTYTXP1_129 GTYE4_CHANNEL_X0Y5 / GTYE4_COMMON_X0Y1
#set_property -dict {LOC N34 } [get_ports {pcie_tx_n[2]}] ;# MGTYTXN1_129 GTYE4_CHANNEL_X0Y5 / GTYE4_COMMON_X0Y1
#set_property -dict {LOC M36 } [get_ports {pcie_rx_p[2]}] ;# MGTYRXP1_129 GTYE4_CHANNEL_X0Y5 / GTYE4_COMMON_X0Y1
#set_property -dict {LOC M37 } [get_ports {pcie_rx_n[2]}] ;# MGTYRXN1_129 GTYE4_CHANNEL_X0Y5 / GTYE4_COMMON_X0Y1
#set_property -dict {LOC P35 } [get_ports {pcie_tx_p[3]}] ;# MGTYTXP0_129 GTYE4_CHANNEL_X0Y4 / GTYE4_COMMON_X0Y1
#set_property -dict {LOC P36 } [get_ports {pcie_tx_n[3]}] ;# MGTYTXN0_129 GTYE4_CHANNEL_X0Y4 / GTYE4_COMMON_X0Y1
#set_property -dict {LOC N38 } [get_ports {pcie_rx_p[3]}] ;# MGTYRXP0_129 GTYE4_CHANNEL_X0Y4 / GTYE4_COMMON_X0Y1
#set_property -dict {LOC N39 } [get_ports {pcie_rx_n[3]}] ;# MGTYRXN0_129 GTYE4_CHANNEL_X0Y4 / GTYE4_COMMON_X0Y1
#set_property -dict {LOC R33 } [get_ports {pcie_tx_p[4]}] ;# MGTYTXP3_128 GTYE4_CHANNEL_X0Y3 / GTYE4_COMMON_X0Y0
#set_property -dict {LOC R34 } [get_ports {pcie_tx_n[4]}] ;# MGTYTXN3_128 GTYE4_CHANNEL_X0Y3 / GTYE4_COMMON_X0Y0
#set_property -dict {LOC R38 } [get_ports {pcie_rx_p[4]}] ;# MGTYRXP3_128 GTYE4_CHANNEL_X0Y3 / GTYE4_COMMON_X0Y0
#set_property -dict {LOC R39 } [get_ports {pcie_rx_n[4]}] ;# MGTYRXN3_128 GTYE4_CHANNEL_X0Y3 / GTYE4_COMMON_X0Y0
#set_property -dict {LOC T35 } [get_ports {pcie_tx_p[5]}] ;# MGTYTXP2_128 GTYE4_CHANNEL_X0Y2 / GTYE4_COMMON_X0Y0
#set_property -dict {LOC T36 } [get_ports {pcie_tx_n[5]}] ;# MGTYTXN2_128 GTYE4_CHANNEL_X0Y2 / GTYE4_COMMON_X0Y0
#set_property -dict {LOC U38 } [get_ports {pcie_rx_p[5]}] ;# MGTYRXP2_128 GTYE4_CHANNEL_X0Y2 / GTYE4_COMMON_X0Y0
#set_property -dict {LOC U39 } [get_ports {pcie_rx_n[5]}] ;# MGTYRXN2_128 GTYE4_CHANNEL_X0Y2 / GTYE4_COMMON_X0Y0
#set_property -dict {LOC V35 } [get_ports {pcie_tx_p[6]}] ;# MGTYTXP1_128 GTYE4_CHANNEL_X0Y1 / GTYE4_COMMON_X0Y0
#set_property -dict {LOC V36 } [get_ports {pcie_tx_n[6]}] ;# MGTYTXN1_128 GTYE4_CHANNEL_X0Y1 / GTYE4_COMMON_X0Y0
#set_property -dict {LOC W38 } [get_ports {pcie_rx_p[6]}] ;# MGTYRXP1_128 GTYE4_CHANNEL_X0Y1 / GTYE4_COMMON_X0Y0
#set_property -dict {LOC W39 } [get_ports {pcie_rx_n[6]}] ;# MGTYRXN1_128 GTYE4_CHANNEL_X0Y1 / GTYE4_COMMON_X0Y0
#set_property -dict {LOC Y35 } [get_ports {pcie_tx_p[7]}] ;# MGTYTXP0_128 GTYE4_CHANNEL_X0Y0 / GTYE4_COMMON_X0Y0
#set_property -dict {LOC Y36 } [get_ports {pcie_tx_n[7]}] ;# MGTYTXN0_128 GTYE4_CHANNEL_X0Y0 / GTYE4_COMMON_X0Y0
#set_property -dict {LOC AA38} [get_ports {pcie_rx_p[7]}] ;# MGTYRXP0_128 GTYE4_CHANNEL_X0Y0 / GTYE4_COMMON_X0Y0
#set_property -dict {LOC AA39} [get_ports {pcie_rx_n[7]}] ;# MGTYRXN0_128 GTYE4_CHANNEL_X0Y0 / GTYE4_COMMON_X0Y0
#set_property -dict {LOC AA33} [get_ports pcie_refclk_p] ;# MGTREFCLK0P_128
#set_property -dict {LOC AA34} [get_ports pcie_refclk_n] ;# MGTREFCLK0N_128
#set_property -dict {LOC AJ13 IOSTANDARD LVCMOS18 PULLUP true} [get_ports pcie_reset_n]

#set_false_path -from [get_ports {pcie_reset_n}]
#set_input_delay 0 [get_ports {pcie_reset_n}]

# 100 MHz MGT reference clock
#create_clock -period 10 -name pcie_mgt_refclk [get_ports pcie_refclk_p]

# FMC+ J25

# for HTG-FMC-QSFP28-DEG90
set_property -dict {LOC AJ12 IOSTANDARD LVCMOS18} [get_ports {fmc_qsfp_resetl}] ;# J25.G33 LA31_P
set_property -dict {LOC AK12 IOSTANDARD LVCMOS18} [get_ports {fmc_qsfp_modsell}] ;# J25.G34 LA31_N
set_property -dict {LOC AL7  IOSTANDARD LVCMOS18} [get_ports {fmc_qsfp_lpmode}] ;# J25.H38 LA32_N

#set_property -dict {LOC AP18 IOSTANDARD LVDS DIFF_TERM_ADV TERM_100} [get_ports {fmc_la_p[0]}]  ;# J25.G9  LA00_P_CC
#set_property -dict {LOC AR18 IOSTANDARD LVDS DIFF_TERM_ADV TERM_100} [get_ports {fmc_la_n[0]}]  ;# J25.G10 LA00_N_CC
#set_property -dict {LOC AM20 IOSTANDARD LVDS DIFF_TERM_ADV TERM_100} [get_ports {fmc_la_p[1]}]  ;# J25.D8  LA01_P_CC
#set_property -dict {LOC AN20 IOSTANDARD LVDS DIFF_TERM_ADV TERM_100} [get_ports {fmc_la_n[1]}]  ;# J25.D9  LA01_N_CC
#set_property -dict {LOC AR22 IOSTANDARD LVDS DIFF_TERM_ADV TERM_100} [get_ports {fmc_la_p[2]}]  ;# J25.H7  LA02_P
#set_property -dict {LOC AT22 IOSTANDARD LVDS DIFF_TERM_ADV TERM_100} [get_ports {fmc_la_n[2]}]  ;# J25.H8  LA02_N
#set_property -dict {LOC AR21 IOSTANDARD LVDS DIFF_TERM_ADV TERM_100} [get_ports {fmc_la_p[3]}]  ;# J25.G12 LA03_P
#set_property -dict {LOC AT21 IOSTANDARD LVDS DIFF_TERM_ADV TERM_100} [get_ports {fmc_la_n[3]}]  ;# J25.G13 LA03_N
#set_property -dict {LOC AV21 IOSTANDARD LVDS DIFF_TERM_ADV TERM_100} [get_ports {fmc_la_p[4]}]  ;# J25.H10 LA04_P
#set_property -dict {LOC AW21 IOSTANDARD LVDS DIFF_TERM_ADV TERM_100} [get_ports {fmc_la_n[4]}]  ;# J25.H11 LA04_N
#set_property -dict {LOC AK22 IOSTANDARD LVDS DIFF_TERM_ADV TERM_100} [get_ports {fmc_la_p[5]}]  ;# J25.D11 LA05_P
#set_property -dict {LOC AK21 IOSTANDARD LVDS DIFF_TERM_ADV TERM_100} [get_ports {fmc_la_n[5]}]  ;# J25.D12 LA05_N
#set_property -dict {LOC AU18 IOSTANDARD LVDS DIFF_TERM_ADV TERM_100} [get_ports {fmc_la_p[6]}]  ;# J25.C10 LA06_P
#set_property -dict {LOC AV18 IOSTANDARD LVDS DIFF_TERM_ADV TERM_100} [get_ports {fmc_la_n[6]}]  ;# J25.C11 LA06_N
#set_property -dict {LOC AL21 IOSTANDARD LVDS DIFF_TERM_ADV TERM_100} [get_ports {fmc_la_p[7]}]  ;# J25.H13 LA07_P
#set_property -dict {LOC AL20 IOSTANDARD LVDS DIFF_TERM_ADV TERM_100} [get_ports {fmc_la_n[7]}]  ;# J25.H14 LA07_N
#set_property -dict {LOC AL22 IOSTANDARD LVDS DIFF_TERM_ADV TERM_100} [get_ports {fmc_la_p[8]}]  ;# J25.G12 LA08_P
#set_property -dict {LOC AM22 IOSTANDARD LVDS DIFF_TERM_ADV TERM_100} [get_ports {fmc_la_n[8]}]  ;# J25.G13 LA08_N
#set_property -dict {LOC AR19 IOSTANDARD LVDS DIFF_TERM_ADV TERM_100} [get_ports {fmc_la_p[9]}]  ;# J25.D14 LA09_P
#set_property -dict {LOC AT19 IOSTANDARD LVDS DIFF_TERM_ADV TERM_100} [get_ports {fmc_la_n[9]}]  ;# J25.D15 LA09_N
#set_property -dict {LOC AU17 IOSTANDARD LVDS DIFF_TERM_ADV TERM_100} [get_ports {fmc_la_p[10]}] ;# J25.C14 LA10_P
#set_property -dict {LOC AV17 IOSTANDARD LVDS DIFF_TERM_ADV TERM_100} [get_ports {fmc_la_n[10]}] ;# J25.C15 LA10_N
#set_property -dict {LOC AL19 IOSTANDARD LVDS DIFF_TERM_ADV TERM_100} [get_ports {fmc_la_p[11]}] ;# J25.H16 LA11_P
#set_property -dict {LOC AM19 IOSTANDARD LVDS DIFF_TERM_ADV TERM_100} [get_ports {fmc_la_n[11]}] ;# J25.H17 LA11_N
#set_property -dict {LOC AG20 IOSTANDARD LVDS DIFF_TERM_ADV TERM_100} [get_ports {fmc_la_p[12]}] ;# J25.G15 LA12_P
#set_property -dict {LOC AH20 IOSTANDARD LVDS DIFF_TERM_ADV TERM_100} [get_ports {fmc_la_n[12]}] ;# J25.G16 LA12_N
#set_property -dict {LOC AJ20 IOSTANDARD LVDS DIFF_TERM_ADV TERM_100} [get_ports {fmc_la_p[13]}] ;# J25.D17 LA13_P
#set_property -dict {LOC AJ19 IOSTANDARD LVDS DIFF_TERM_ADV TERM_100} [get_ports {fmc_la_n[13]}] ;# J25.D18 LA13_N
#set_property -dict {LOC AJ18 IOSTANDARD LVDS DIFF_TERM_ADV TERM_100} [get_ports {fmc_la_p[14]}] ;# J25.C18 LA14_P
#set_property -dict {LOC AK18 IOSTANDARD LVDS DIFF_TERM_ADV TERM_100} [get_ports {fmc_la_n[14]}] ;# J25.C19 LA14_N
#set_property -dict {LOC AR17 IOSTANDARD LVDS DIFF_TERM_ADV TERM_100} [get_ports {fmc_la_p[15]}] ;# J25.H19 LA15_P
#set_property -dict {LOC AT17 IOSTANDARD LVDS DIFF_TERM_ADV TERM_100} [get_ports {fmc_la_n[15]}] ;# J25.H20 LA15_N
#set_property -dict {LOC AG18 IOSTANDARD LVDS DIFF_TERM_ADV TERM_100} [get_ports {fmc_la_p[16]}] ;# J25.G18 LA16_P
#set_property -dict {LOC AH18 IOSTANDARD LVDS DIFF_TERM_ADV TERM_100} [get_ports {fmc_la_n[16]}] ;# J25.G19 LA16_N
#set_property -dict {LOC AP8  IOSTANDARD LVDS DIFF_TERM_ADV TERM_100} [get_ports {fmc_la_p[17]}] ;# J25.D20 LA17_P_CC
#set_property -dict {LOC AR8  IOSTANDARD LVDS DIFF_TERM_ADV TERM_100} [get_ports {fmc_la_n[17]}] ;# J25.D21 LA17_N_CC
#set_property -dict {LOC AP9  IOSTANDARD LVDS DIFF_TERM_ADV TERM_100} [get_ports {fmc_la_p[18]}] ;# J25.C22 LA18_P_CC
#set_property -dict {LOC AR9  IOSTANDARD LVDS DIFF_TERM_ADV TERM_100} [get_ports {fmc_la_n[18]}] ;# J25.C23 LA18_N_CC
#set_property -dict {LOC AU12 IOSTANDARD LVDS DIFF_TERM_ADV TERM_100} [get_ports {fmc_la_p[19]}] ;# J25.H22 LA19_P
#set_property -dict {LOC AV12 IOSTANDARD LVDS DIFF_TERM_ADV TERM_100} [get_ports {fmc_la_n[19]}] ;# J25.H23 LA19_N
#set_property -dict {LOC AW9  IOSTANDARD LVDS DIFF_TERM_ADV TERM_100} [get_ports {fmc_la_p[20]}] ;# J25.G21 LA20_P
#set_property -dict {LOC AW8  IOSTANDARD LVDS DIFF_TERM_ADV TERM_100} [get_ports {fmc_la_n[20]}] ;# J25.G22 LA20_N
#set_property -dict {LOC AM13 IOSTANDARD LVDS DIFF_TERM_ADV TERM_100} [get_ports {fmc_la_p[21]}] ;# J25.H25 LA21_P
#set_property -dict {LOC AN13 IOSTANDARD LVDS DIFF_TERM_ADV TERM_100} [get_ports {fmc_la_n[21]}] ;# J25.H26 LA21_N
#set_property -dict {LOC AT10 IOSTANDARD LVDS DIFF_TERM_ADV TERM_100} [get_ports {fmc_la_p[22]}] ;# J25.G24 LA22_P
#set_property -dict {LOC AU10 IOSTANDARD LVDS DIFF_TERM_ADV TERM_100} [get_ports {fmc_la_n[22]}] ;# J25.G25 LA22_N
#set_property -dict {LOC AV11 IOSTANDARD LVDS DIFF_TERM_ADV TERM_100} [get_ports {fmc_la_p[23]}] ;# J25.D23 LA23_P
#set_property -dict {LOC AW11 IOSTANDARD LVDS DIFF_TERM_ADV TERM_100} [get_ports {fmc_la_n[23]}] ;# J25.D24 LA23_N
#set_property -dict {LOC AN8  IOSTANDARD LVDS DIFF_TERM_ADV TERM_100} [get_ports {fmc_la_p[24]}] ;# J25.H28 LA24_P
#set_property -dict {LOC AN7  IOSTANDARD LVDS DIFF_TERM_ADV TERM_100} [get_ports {fmc_la_n[24]}] ;# J25.H29 LA24_N
#set_property -dict {LOC AL14 IOSTANDARD LVDS DIFF_TERM_ADV TERM_100} [get_ports {fmc_la_p[25]}] ;# J25.G27 LA25_P
#set_property -dict {LOC AM14 IOSTANDARD LVDS DIFF_TERM_ADV TERM_100} [get_ports {fmc_la_n[25]}] ;# J25.G28 LA25_N
#set_property -dict {LOC AM12 IOSTANDARD LVDS DIFF_TERM_ADV TERM_100} [get_ports {fmc_la_p[26]}] ;# J25.D26 LA26_P
#set_property -dict {LOC AN12 IOSTANDARD LVDS DIFF_TERM_ADV TERM_100} [get_ports {fmc_la_n[26]}] ;# J25.D27 LA26_N
#set_property -dict {LOC AR12 IOSTANDARD LVDS DIFF_TERM_ADV TERM_100} [get_ports {fmc_la_p[27]}] ;# J25.C26 LA27_P
#set_property -dict {LOC AR11 IOSTANDARD LVDS DIFF_TERM_ADV TERM_100} [get_ports {fmc_la_n[27]}] ;# J25.C27 LA27_N
#set_property -dict {LOC AL10 IOSTANDARD LVDS DIFF_TERM_ADV TERM_100} [get_ports {fmc_la_p[28]}] ;# J25.H31 LA28_P
#set_property -dict {LOC AM10 IOSTANDARD LVDS DIFF_TERM_ADV TERM_100} [get_ports {fmc_la_n[28]}] ;# J25.H32 LA28_N
#set_property -dict {LOC AJ14 IOSTANDARD LVDS DIFF_TERM_ADV TERM_100} [get_ports {fmc_la_p[29]}] ;# J25.G30 LA29_P
#set_property -dict {LOC AK14 IOSTANDARD LVDS DIFF_TERM_ADV TERM_100} [get_ports {fmc_la_n[29]}] ;# J25.G31 LA29_N
#set_property -dict {LOC AG12 IOSTANDARD LVDS DIFF_TERM_ADV TERM_100} [get_ports {fmc_la_p[30]}] ;# J25.H34 LA30_P
#set_property -dict {LOC AH12 IOSTANDARD LVDS DIFF_TERM_ADV TERM_100} [get_ports {fmc_la_n[30]}] ;# J25.H35 LA30_N
#set_property -dict {LOC AJ12 IOSTANDARD LVDS DIFF_TERM_ADV TERM_100} [get_ports {fmc_la_p[31]}] ;# J25.G33 LA31_P
#set_property -dict {LOC AK12 IOSTANDARD LVDS DIFF_TERM_ADV TERM_100} [get_ports {fmc_la_n[31]}] ;# J25.G34 LA31_N
#set_property -dict {LOC AL8  IOSTANDARD LVDS DIFF_TERM_ADV TERM_100} [get_ports {fmc_la_p[32]}] ;# J25.H37 LA32_P
#set_property -dict {LOC AL7  IOSTANDARD LVDS DIFF_TERM_ADV TERM_100} [get_ports {fmc_la_n[32]}] ;# J25.H38 LA32_N
#set_property -dict {LOC AL9  IOSTANDARD LVDS DIFF_TERM_ADV TERM_100} [get_ports {fmc_la_p[33]}] ;# J25.G36 LA33_P
#set_property -dict {LOC AM9  IOSTANDARD LVDS DIFF_TERM_ADV TERM_100} [get_ports {fmc_la_n[33]}] ;# J25.G37 LA33_N

#set_property -dict {LOC AN21 IOSTANDARD LVDS DIFF_TERM_ADV TERM_100} [get_ports {fmc_clk0_m2c_p}] ;# J25.H4 CLK0_M2C_P
#set_property -dict {LOC AP21 IOSTANDARD LVDS DIFF_TERM_ADV TERM_100} [get_ports {fmc_clk0_m2c_n}] ;# J25.H5 CLK0_M2C_N

#set_property -dict {LOC AN11 IOSTANDARD LVDS DIFF_TERM_ADV TERM_100} [get_ports {fmc_refclk_m2c_p}] ;# J25.L24 REFCLK_M2C_P
#set_property -dict {LOC AP11 IOSTANDARD LVDS DIFF_TERM_ADV TERM_100} [get_ports {fmc_refclk_m2c_n}] ;# J25.L25 REFCLK_M2C_N
#set_property -dict {LOC AV10 IOSTANDARD LVDS                       } [get_ports {fmc_sync_c2m_p}]   ;# J25.L16 SYNC_C2M_P
#set_property -dict {LOC AW10 IOSTANDARD LVDS                       } [get_ports {fmc_sync_c2m_n}]   ;# J25.L17 SYNC_C2M_N
#set_property -dict {LOC AN10 IOSTANDARD LVDS DIFF_TERM_ADV TERM_100} [get_ports {fmc_sync_m2c_p}]   ;# J25.L28 SYNC_M2C_P
#set_property -dict {LOC AP10 IOSTANDARD LVDS DIFF_TERM_ADV TERM_100} [get_ports {fmc_sync_m2c_n}]   ;# J25.L29 SYNC_M2C_N

#set_property -dict {LOC A10  IOSTANDARD LVCMOS18} [get_ports {fmc_pg_m2c}]           ;# J25.F1 PG_M2C
#set_property -dict {LOC C10  IOSTANDARD LVCMOS12} [get_ports {fmc_prsnt_m2c_l}]      ;# J25.H2 PRSNT_M2C_L
#set_property -dict {LOC B10  IOSTANDARD LVCMOS12} [get_ports {fmc_hspc_prsnt_m2c_l}] ;# J25.Z1 HSPC_PRSNT_M2C_L

set_property -dict {LOC E33 } [get_ports {fmc_dp_c2m_p[0]}]  ;# MGTYTXP3_130 GTYE4_CHANNEL_X0Y41 / GTYE4_COMMON_X0Y10 from J25.C2  DP0_C2M_P
set_property -dict {LOC E34 } [get_ports {fmc_dp_c2m_n[0]}]  ;# MGTYTXN3_130 GTYE4_CHANNEL_X0Y41 / GTYE4_COMMON_X0Y10 from J25.C3  DP0_C2M_N
set_property -dict {LOC F36 } [get_ports {fmc_dp_m2c_p[0]}]  ;# MGTYRXP3_130 GTYE4_CHANNEL_X0Y41 / GTYE4_COMMON_X0Y10 from J25.C6  DP0_M2C_P
set_property -dict {LOC F37 } [get_ports {fmc_dp_m2c_n[0]}]  ;# MGTYRXN3_130 GTYE4_CHANNEL_X0Y41 / GTYE4_COMMON_X0Y10 from J25.C7  DP0_M2C_N
set_property -dict {LOC H31 } [get_ports {fmc_dp_c2m_p[1]}]  ;# MGTYTXP0_130 GTYE4_CHANNEL_X0Y43 / GTYE4_COMMON_X0Y10 from J25.A22 DP1_C2M_P
set_property -dict {LOC H32 } [get_ports {fmc_dp_c2m_n[1]}]  ;# MGTYTXN0_130 GTYE4_CHANNEL_X0Y43 / GTYE4_COMMON_X0Y10 from J25.A23 DP1_C2M_N
set_property -dict {LOC J38 } [get_ports {fmc_dp_m2c_p[1]}]  ;# MGTYRXP0_130 GTYE4_CHANNEL_X0Y43 / GTYE4_COMMON_X0Y10 from J25.A2  DP1_M2C_P
set_property -dict {LOC J39 } [get_ports {fmc_dp_m2c_n[1]}]  ;# MGTYRXN0_130 GTYE4_CHANNEL_X0Y43 / GTYE4_COMMON_X0Y10 from J25.A3  DP1_M2C_N
set_property -dict {LOC G33 } [get_ports {fmc_dp_c2m_p[2]}]  ;# MGTYTXP1_130 GTYE4_CHANNEL_X0Y42 / GTYE4_COMMON_X0Y10 from J25.A26 DP2_C2M_P
set_property -dict {LOC G34 } [get_ports {fmc_dp_c2m_n[2]}]  ;# MGTYTXN1_130 GTYE4_CHANNEL_X0Y42 / GTYE4_COMMON_X0Y10 from J25.A27 DP2_C2M_N
set_property -dict {LOC H36 } [get_ports {fmc_dp_m2c_p[2]}]  ;# MGTYRXP1_130 GTYE4_CHANNEL_X0Y42 / GTYE4_COMMON_X0Y10 from J25.A6  DP2_M2C_P
set_property -dict {LOC H37 } [get_ports {fmc_dp_m2c_n[2]}]  ;# MGTYRXN1_130 GTYE4_CHANNEL_X0Y42 / GTYE4_COMMON_X0Y10 from J25.A7  DP2_M2C_N
set_property -dict {LOC F31 } [get_ports {fmc_dp_c2m_p[3]}]  ;# MGTYTXP2_130 GTYE4_CHANNEL_X0Y40 / GTYE4_COMMON_X0Y10 from J25.A30 DP3_C2M_P
set_property -dict {LOC F32 } [get_ports {fmc_dp_c2m_n[3]}]  ;# MGTYTXN2_130 GTYE4_CHANNEL_X0Y40 / GTYE4_COMMON_X0Y10 from J25.A31 DP3_C2M_N
set_property -dict {LOC G38 } [get_ports {fmc_dp_m2c_p[3]}]  ;# MGTYRXP2_130 GTYE4_CHANNEL_X0Y40 / GTYE4_COMMON_X0Y10 from J25.A10 DP3_M2C_P
set_property -dict {LOC G39 } [get_ports {fmc_dp_m2c_n[3]}]  ;# MGTYRXN2_130 GTYE4_CHANNEL_X0Y40 / GTYE4_COMMON_X0Y10 from J25.A11 DP3_M2C_N
set_property -dict {LOC U33 } [get_ports fmc_mgt_refclk_0_0_p] ;# MGTREFCLK0P_130 from U48.38 OUT4_P
set_property -dict {LOC U34 } [get_ports fmc_mgt_refclk_0_0_n] ;# MGTREFCLK0N_130 from U48.37 OUT4_N
#set_property -dict {LOC T31 } [get_ports fmc_mgt_refclk_0_1_p] ;# MGTREFCLK1P_130 from J25.D4 GBTCLK0_M2C_P
#set_property -dict {LOC T32 } [get_ports fmc_mgt_refclk_0_1_n] ;# MGTREFCLK1N_130 from J25.D5 GBTCLK0_M2C_N

# reference clock
create_clock -period 6.206 -name fmc_mgt_refclk_0_0 [get_ports fmc_mgt_refclk_0_0_p]
#create_clock -period 6.400 -name fmc_mgt_refclk_0_1 [get_ports fmc_mgt_refclk_0_1_p]

set_property -dict {LOC C33 } [get_ports {fmc_dp_c2m_p[4]}]  ;# MGTYTXP1_131 GTYE4_CHANNEL_X0Y38 / GTYE4_COMMON_X0Y9 from J25.A34 DP4_C2M_P
set_property -dict {LOC C34 } [get_ports {fmc_dp_c2m_n[4]}]  ;# MGTYTXN1_131 GTYE4_CHANNEL_X0Y38 / GTYE4_COMMON_X0Y9 from J25.A35 DP4_C2M_N
set_property -dict {LOC D36 } [get_ports {fmc_dp_m2c_p[4]}]  ;# MGTYRXP1_131 GTYE4_CHANNEL_X0Y38 / GTYE4_COMMON_X0Y9 from J25.A14 DP4_M2C_P
set_property -dict {LOC D37 } [get_ports {fmc_dp_m2c_n[4]}]  ;# MGTYRXN1_131 GTYE4_CHANNEL_X0Y38 / GTYE4_COMMON_X0Y9 from J25.A15 DP4_M2C_N
set_property -dict {LOC A33 } [get_ports {fmc_dp_c2m_p[5]}]  ;# MGTYTXP3_131 GTYE4_CHANNEL_X0Y36 / GTYE4_COMMON_X0Y9 from J25.A38 DP5_C2M_P
set_property -dict {LOC A34 } [get_ports {fmc_dp_c2m_n[5]}]  ;# MGTYTXN3_131 GTYE4_CHANNEL_X0Y36 / GTYE4_COMMON_X0Y9 from J25.A39 DP5_C2M_N
set_property -dict {LOC B36 } [get_ports {fmc_dp_m2c_p[5]}]  ;# MGTYRXP3_131 GTYE4_CHANNEL_X0Y36 / GTYE4_COMMON_X0Y9 from J25.A18 DP5_M2C_P
set_property -dict {LOC B37 } [get_ports {fmc_dp_m2c_n[5]}]  ;# MGTYRXN3_131 GTYE4_CHANNEL_X0Y36 / GTYE4_COMMON_X0Y9 from J25.A19 DP5_M2C_N
set_property -dict {LOC B31 } [get_ports {fmc_dp_c2m_p[6]}]  ;# MGTYTXP2_131 GTYE4_CHANNEL_X0Y37 / GTYE4_COMMON_X0Y9 from J25.B36 DP6_C2M_P
set_property -dict {LOC B32 } [get_ports {fmc_dp_c2m_n[6]}]  ;# MGTYTXN2_131 GTYE4_CHANNEL_X0Y37 / GTYE4_COMMON_X0Y9 from J25.B37 DP6_C2M_N
set_property -dict {LOC C38 } [get_ports {fmc_dp_m2c_p[6]}]  ;# MGTYRXP2_131 GTYE4_CHANNEL_X0Y37 / GTYE4_COMMON_X0Y9 from J25.B16 DP6_M2C_P
set_property -dict {LOC C39 } [get_ports {fmc_dp_m2c_n[6]}]  ;# MGTYRXN2_131 GTYE4_CHANNEL_X0Y37 / GTYE4_COMMON_X0Y9 from J25.B17 DP6_M2C_N
set_property -dict {LOC D31 } [get_ports {fmc_dp_c2m_p[7]}]  ;# MGTYTXP0_131 GTYE4_CHANNEL_X0Y39 / GTYE4_COMMON_X0Y9 from J25.B32 DP7_C2M_P
set_property -dict {LOC D32 } [get_ports {fmc_dp_c2m_n[7]}]  ;# MGTYTXN0_131 GTYE4_CHANNEL_X0Y39 / GTYE4_COMMON_X0Y9 from J25.B33 DP7_C2M_N
set_property -dict {LOC E38 } [get_ports {fmc_dp_m2c_p[7]}]  ;# MGTYRXP0_131 GTYE4_CHANNEL_X0Y39 / GTYE4_COMMON_X0Y9 from J25.B12 DP7_M2C_P
set_property -dict {LOC E39 } [get_ports {fmc_dp_m2c_n[7]}]  ;# MGTYRXN0_131 GTYE4_CHANNEL_X0Y39 / GTYE4_COMMON_X0Y9 from J25.B13 DP7_M2C_N
set_property -dict {LOC P31 } [get_ports fmc_mgt_refclk_1_0_p] ;# MGTREFCLK0P_131 from U48.35 OUT3_P
set_property -dict {LOC P32 } [get_ports fmc_mgt_refclk_1_0_n] ;# MGTREFCLK0N_131 from U48.34 OUT3_N
#set_property -dict {LOC M31 } [get_ports fmc_mgt_refclk_1_1_p] ;# MGTREFCLK1P_131 from J25.B20 GBTCLK1_M2C_P
#set_property -dict {LOC M32 } [get_ports fmc_mgt_refclk_1_1_n] ;# MGTREFCLK1N_131 from J25.B21 GBTCLK1_M2C_N

# reference clock
create_clock -period 6.206 -name fmc_mgt_refclk_1_0 [get_ports fmc_mgt_refclk_1_0_p]
#create_clock -period 6.400 -name fmc_mgt_refclk_1_1 [get_ports fmc_mgt_refclk_1_1_p]

# RFDC
set_property -dict {LOC Y2  } [get_ports {adc_vin_p[0]}]  ;# ADC_VIN_I23_227_P from J7 (RA) via T5
set_property -dict {LOC Y1  } [get_ports {adc_vin_n[0]}]  ;# ADC_VIN_I23_227_N from J7 (RA) via T5
set_property -dict {LOC AB2 } [get_ports {adc_vin_p[1]}]  ;# ADC_VIN_I01_227_P from J17 (V) via T13
set_property -dict {LOC AB1 } [get_ports {adc_vin_n[1]}]  ;# ADC_VIN_I01_227_N from J17 (V) via T13
set_property -dict {LOC AD2 } [get_ports {adc_vin_p[2]}]  ;# ADC_VIN_I23_226_P from J8 (RA) via T6
set_property -dict {LOC AD1 } [get_ports {adc_vin_n[2]}]  ;# ADC_VIN_I23_226_N from J8 (RA) via T6
set_property -dict {LOC AF2 } [get_ports {adc_vin_p[3]}]  ;# ADC_VIN_I01_226_P from J18 (V) via T14
set_property -dict {LOC AF1 } [get_ports {adc_vin_n[3]}]  ;# ADC_VIN_I01_226_N from J18 (V) via T14
set_property -dict {LOC AH2 } [get_ports {adc_vin_p[4]}]  ;# ADC_VIN_I23_225_P from J9 (RA) via T7
set_property -dict {LOC AH1 } [get_ports {adc_vin_n[4]}]  ;# ADC_VIN_I23_225_N from J9 (RA) via T7
set_property -dict {LOC AK2 } [get_ports {adc_vin_p[5]}]  ;# ADC_VIN_I01_225_P from J19 (V) via T15
set_property -dict {LOC AK1 } [get_ports {adc_vin_n[5]}]  ;# ADC_VIN_I01_225_N from J19 (V) via T15
set_property -dict {LOC AM2 } [get_ports {adc_vin_p[6]}]  ;# ADC_VIN_I23_224_P from J10 (RA) via T8
set_property -dict {LOC AM1 } [get_ports {adc_vin_n[6]}]  ;# ADC_VIN_I23_224_N from J10 (RA) via T8
set_property -dict {LOC AP2 } [get_ports {adc_vin_p[7]}]  ;# ADC_VIN_I01_224_P from J20 (V) via T16
set_property -dict {LOC AP1 } [get_ports {adc_vin_n[7]}]  ;# ADC_VIN_I01_224_N from J20 (V) via T16

set_property -dict {LOC AF5 } [get_ports {adc_refclk_0_p}]  ;# ADC_224_REFCLK_P from U83.23 RFoutAP
set_property -dict {LOC AF4 } [get_ports {adc_refclk_0_n}]  ;# ADC_224_REFCLK_N from U83.22 RFoutAN
set_property -dict {LOC AD5 } [get_ports {adc_refclk_1_p}]  ;# ADC_225_REFCLK_P from U83.19 RFoutBP
set_property -dict {LOC AD4 } [get_ports {adc_refclk_1_n}]  ;# ADC_225_REFCLK_N from U83.18 RFoutBN
set_property -dict {LOC AB5 } [get_ports {adc_refclk_2_p}]  ;# ADC_226_REFCLK_P from U82.23 RFoutAP
set_property -dict {LOC AB4 } [get_ports {adc_refclk_2_n}]  ;# ADC_226_REFCLK_N from U82.22 RFoutAN
set_property -dict {LOC Y5  } [get_ports {adc_refclk_3_p}]  ;# ADC_227_REFCLK_P from U82.19 RFoutBP
set_property -dict {LOC Y4  } [get_ports {adc_refclk_3_n}]  ;# ADC_227_REFCLK_N from U82.18 RFoutBN

set_property -dict {LOC C2  } [get_ports {dac_vout_p[0]}]  ;# DAC_VOUT3_229_P from J3 (RA) via T1
set_property -dict {LOC C1  } [get_ports {dac_vout_n[0]}]  ;# DAC_VOUT3_229_N from J3 (RA) via T1
set_property -dict {LOC E2  } [get_ports {dac_vout_p[1]}]  ;# DAC_VOUT2_229_P from J13 (V) via T9
set_property -dict {LOC E1  } [get_ports {dac_vout_n[1]}]  ;# DAC_VOUT2_229_N from J13 (V) via T9
set_property -dict {LOC G2  } [get_ports {dac_vout_p[2]}]  ;# DAC_VOUT1_229_P from J4 (RA) via T2
set_property -dict {LOC G1  } [get_ports {dac_vout_n[2]}]  ;# DAC_VOUT1_229_N from J4 (RA) via T2
set_property -dict {LOC J2  } [get_ports {dac_vout_p[3]}]  ;# DAC_VOUT0_229_P from J14 (V) via T10
set_property -dict {LOC J1  } [get_ports {dac_vout_n[3]}]  ;# DAC_VOUT0_229_N from J14 (V) via T10
set_property -dict {LOC L2  } [get_ports {dac_vout_p[4]}]  ;# DAC_VOUT3_228_P from J5 (RA) via T3
set_property -dict {LOC L1  } [get_ports {dac_vout_n[4]}]  ;# DAC_VOUT3_228_N from J5 (RA) via T3
set_property -dict {LOC N2  } [get_ports {dac_vout_p[5]}]  ;# DAC_VOUT2_228_P from J15 (V) via T11
set_property -dict {LOC N1  } [get_ports {dac_vout_n[5]}]  ;# DAC_VOUT2_228_N from J15 (V) via T11
set_property -dict {LOC R2  } [get_ports {dac_vout_p[6]}]  ;# DAC_VOUT1_228_P from J6 (RA) via T4
set_property -dict {LOC R1  } [get_ports {dac_vout_n[6]}]  ;# DAC_VOUT1_228_N from J6 (RA) via T4
set_property -dict {LOC U2  } [get_ports {dac_vout_p[7]}]  ;# DAC_VOUT0_228_P from J16 (V) via T12
set_property -dict {LOC U1  } [get_ports {dac_vout_n[7]}]  ;# DAC_VOUT0_228_N from J16 (V) via T12

#set_property -dict {LOC R5  } [get_ports {dac_refclk_0_p}]  ;# DAC_228_REFCLK_P from U81.23 RFoutAP
#set_property -dict {LOC R4  } [get_ports {dac_refclk_0_n}]  ;# DAC_228_REFCLK_N from U81.22 RFoutAN
set_property -dict {LOC N5  } [get_ports {dac_refclk_1_p}]  ;# DAC_229_REFCLK_P from U81.19 RFoutBP
set_property -dict {LOC N4  } [get_ports {dac_refclk_1_n}]  ;# DAC_229_REFCLK_N from U81.18 RFoutBN

set_property -dict {LOC U5  } [get_ports {rfdc_sysref_p}]  ;# SYSREF_P_228 from U2.1 CLKout0_P
set_property -dict {LOC U4  } [get_ports {rfdc_sysref_n}]  ;# SYSREF_N_228 from U2.2 CLKout0_N
