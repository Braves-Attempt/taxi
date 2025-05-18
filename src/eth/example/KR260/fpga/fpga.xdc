# SPDX-License-Identifier: MIT
#
# Copyright (c) 2025 FPGA Ninja, LLC
#
# Authors:
# - Alex Forencich
#

# XDC constraints for the Xilinx KR260 board
# part: xck26-sfvc784-2LV-c

# General configuration
set_property BITSTREAM.GENERAL.COMPRESS true           [current_design]

# System clocks
# 25 MHz system clock
set_property -dict {LOC C3   IOSTANDARD LVCMOS18} [get_ports clk_25mhz] ;# HPA_CLK0_P som240_1_a6
create_clock -period 40.000 -name clk_25mhz [get_ports clk_25mhz]

# 25 MHz system clock
#set_property -dict {LOC L3 IOSTANDARD LVCMOS18} [get_ports clk_25mhz] ;# HPB_CLK0_P som240_2_d18
#create_clock -period 40.000 -name clk_25mhz [get_ports clk_25mhz]

# LEDs
set_property -dict {LOC F8   IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 8} [get_ports {led[0]}] ;# HPA14P som240_1_d13
set_property -dict {LOC E8   IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 8} [get_ports {led[1]}] ;# HPA14N som240_1_d14

set_property -dict {LOC G8   IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 8} [get_ports {sfp_led[0]}] ;# HPA13P som240_1_a12
set_property -dict {LOC F7   IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 8} [get_ports {sfp_led[1]}] ;# HPA13N som240_1_a13

set_false_path -to [get_ports {led[*] sfp_led[*]}]
set_output_delay 0 [get_ports {led[*] sfp_led[*]}]

# PMOD1
#set_property -dict {LOC H12  IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 8} [get_ports {pmod1[0]}] ;# J2.1 / HDA11 som240_1_a17
#set_property -dict {LOC E10  IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 8} [get_ports {pmod1[1]}] ;# J2.3 / HDA12 som240_1_d20
#set_property -dict {LOC D10  IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 8} [get_ports {pmod1[2]}] ;# J2.5 / HDA13 som240_1_d21
#set_property -dict {LOC C11  IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 8} [get_ports {pmod1[3]}] ;# J2.7 / HDA14 som240_1_d22
#set_property -dict {LOC B10  IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 8} [get_ports {pmod1[4]}] ;# J2.2 / HDA15 som240_1_b20
#set_property -dict {LOC E12  IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 8} [get_ports {pmod1[5]}] ;# J2.4 / HDA16_CC som240_1_b21
#set_property -dict {LOC D11  IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 8} [get_ports {pmod1[6]}] ;# J2.6 / HDA17 som240_1_b22
#set_property -dict {LOC B11  IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 8} [get_ports {pmod1[7]}] ;# J2.8 / HDA18 som240_1_c22

#set_false_path -to [get_ports {pmod1[*]}]
#set_output_delay 0 [get_ports {pmod1[*]}]

# PMOD2
#set_property -dict {LOC J11  IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 8} [get_ports {pmod2[0]}] ;# J18.1 / HDA02 som240_1_d18
#set_property -dict {LOC J10  IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 8} [get_ports {pmod2[1]}] ;# J18.3 / HDA03 som240_1_b16
#set_property -dict {LOC K13  IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 8} [get_ports {pmod2[2]}] ;# J18.5 / HDA04 som240_1_b17
#set_property -dict {LOC K12  IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 8} [get_ports {pmod2[3]}] ;# J18.7 / HDA05 som240_1_b18
#set_property -dict {LOC H11  IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 8} [get_ports {pmod2[4]}] ;# J18.2 / HDA06 som240_1_c18
#set_property -dict {LOC G10  IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 8} [get_ports {pmod2[5]}] ;# J18.4 / HDA07 som240_1_c19
#set_property -dict {LOC F12  IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 8} [get_ports {pmod2[6]}] ;# J18.6 / HDA08_CC som240_1_c20
#set_property -dict {LOC F11  IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 8} [get_ports {pmod2[7]}] ;# J18.8 / HDA09 som240_1_a15

#set_false_path -to [get_ports {pmod2[*]}]
#set_output_delay 0 [get_ports {pmod2[*]}]

# PMOD3
#set_property -dict {LOC AE12 IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 8} [get_ports {pmod3[0]}] ;# J19.1 / HDB00_CC som240_2_d44
#set_property -dict {LOC AF12 IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 8} [get_ports {pmod3[1]}] ;# J19.3 / HDB01 som240_2_d45
#set_property -dict {LOC AG10 IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 8} [get_ports {pmod3[2]}] ;# J19.5 / HDB02 som240_2_d46
#set_property -dict {LOC AH10 IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 8} [get_ports {pmod3[3]}] ;# J19.7 / HDB03 som240_2_d48
#set_property -dict {LOC AF11 IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 8} [get_ports {pmod3[4]}] ;# J19.2 / HDB04 som240_2_d49
#set_property -dict {LOC AG11 IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 8} [get_ports {pmod3[5]}] ;# J19.4 / HDB05 som240_2_d50
#set_property -dict {LOC AH12 IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 8} [get_ports {pmod3[6]}] ;# J19.6 / HDB06 som240_2_c46
#set_property -dict {LOC AH11 IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 8} [get_ports {pmod3[7]}] ;# J19.8 / HDB07 som240_2_c47

#set_false_path -to [get_ports {pmod3[*]}]
#set_output_delay 0 [get_ports {pmod3[*]}]

# PMOD4
#set_property -dict {LOC AC12 IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 8} [get_ports {pmod4[0]}] ;# J20.1 / HDB08_CC som240_2_c48
#set_property -dict {LOC AD12 IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 8} [get_ports {pmod4[1]}] ;# J20.3 / HDB09 som240_2_c50
#set_property -dict {LOC AE10 IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 8} [get_ports {pmod4[2]}] ;# J20.5 / HDB10 som240_2_c51
#set_property -dict {LOC AF10 IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 8} [get_ports {pmod4[3]}] ;# J20.7 / HDB11 som240_2_c52
#set_property -dict {LOC AD11 IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 8} [get_ports {pmod4[4]}] ;# J20.2 / HDB12 som240_2_b44
#set_property -dict {LOC AD10 IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 8} [get_ports {pmod4[5]}] ;# J20.4 / HDB13 som240_2_b45
#set_property -dict {LOC AA11 IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 8} [get_ports {pmod4[6]}] ;# J20.6 / HDB14 som240_2_b46
#set_property -dict {LOC AA10 IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 8} [get_ports {pmod4[7]}] ;# J20.8 / HDB15 som240_2_b48

#set_false_path -to [get_ports {pmod4[*]}]
#set_output_delay 0 [get_ports {pmod4[*]}]

# Gigabit Ethernet RGMII PHY
set_property -dict {LOC D4   IOSTANDARD LVCMOS18} [get_ports {phy2_rx_clk}] ;# from U79.32 RX_CLK / HPA09P_CLK som240_1_d10
set_property -dict {LOC A1   IOSTANDARD LVCMOS18} [get_ports {phy2_rxd[0]}] ;# from U79.33 RX_D0_SGMII_COP / HPA06N som240_1_a4
set_property -dict {LOC B3   IOSTANDARD LVCMOS18} [get_ports {phy2_rxd[1]}] ;# from U79.34 RX_D1_SGMII_CON / HPA07P som240_1_b7
set_property -dict {LOC A3   IOSTANDARD LVCMOS18} [get_ports {phy2_rxd[2]}] ;# from U79.35 RX_D2_SGMII_SOP / HPA07N som240_1_b8
set_property -dict {LOC B4   IOSTANDARD LVCMOS18} [get_ports {phy2_rxd[3]}] ;# from U79.36 RX_D3_SGMII_SON / HPA08P som240_1_c9
set_property -dict {LOC A4   IOSTANDARD LVCMOS18} [get_ports {phy2_rx_ctl}] ;# from U79.38 RX_CTRL / HPA08N som240_1_c10
set_property -dict {LOC A2   IOSTANDARD LVCMOS18 SLEW FAST DRIVE 12} [get_ports {phy2_tx_clk}] ;# from U79.29 GTX_CLK / HPA06P_CLK som240_1_a3
set_property -dict {LOC E1   IOSTANDARD LVCMOS18 SLEW FAST DRIVE 12} [get_ports {phy2_txd[0]}] ;# from U79.28 TX_D0_SGMII_SIN / HPA01P som240_1_d7
set_property -dict {LOC D1   IOSTANDARD LVCMOS18 SLEW FAST DRIVE 12} [get_ports {phy2_txd[1]}] ;# from U79.27 TX_D1_SGMII_SIP / HPA01N som240_1_d8
set_property -dict {LOC F2   IOSTANDARD LVCMOS18 SLEW FAST DRIVE 12} [get_ports {phy2_txd[2]}] ;# from U79.26 TX_D2 / HPA02P som240_1_d4
set_property -dict {LOC E2   IOSTANDARD LVCMOS18 SLEW FAST DRIVE 12} [get_ports {phy2_txd[3]}] ;# from U79.25 TX_D3 / HPA02N som240_1_d5
set_property -dict {LOC F1   IOSTANDARD LVCMOS18 SLEW FAST DRIVE 12} [get_ports {phy2_tx_ctl}] ;# from U79.37 TX_CTRL / HPA00_CCN som240_1_c4
set_property -dict {LOC B1   IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 12} [get_ports {phy2_reset_n}] ;# from U79.43 RESET_B / HPA05_CCN som240_1_b2
#set_property -dict {LOC F3   IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 12} [get_ports {phy2_mdio}] ;# from U79.17 MDIO / HPA03N som240_1_c7
#set_property -dict {LOC G3   IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 12} [get_ports {phy2_mdc}] ;# from U79.16 MDC / HPA03P som240_1_c6
#set_property -dict {LOC E4   IOSTANDARD LVCMOS18} [get_ports {phy2_led[0]}] ;# from U79.47 LED_0 / HPA04P som240_1_b4
#set_property -dict {LOC E3   IOSTANDARD LVCMOS18} [get_ports {phy2_led[1]}] ;# from U79.46 LED_1 / HPA04N som240_1_b5
#set_property -dict {LOC C1   IOSTANDARD LVCMOS18} [get_ports {phy2_led[2]}] ;# from U79.45 LED_2 / HPA05_CCP som240_1_b1

create_clock -period 8.000 -name {phy2_rx_clk} [get_ports {phy2_rx_clk}]

set_false_path -to [get_ports {phy2_reset_n}]
set_output_delay 0 [get_ports {phy2_reset_n}]
# set_false_path -from [get_ports {phy2_led[*]}]
# set_input_delay 0 [get_ports {phy2_led[*]}]

#set_false_path -to [get_ports {phy2_mdio phy2_mdc}]
#set_output_delay 0 [get_ports {phy2_mdio phy2_mdc}]
#set_false_path -from [get_ports {phy2_mdio}]
#set_input_delay 0 [get_ports {phy2_mdio}]

set_property -dict {LOC K4   IOSTANDARD LVCMOS18} [get_ports {phy3_rx_clk}] ;# from U80.32 RX_CLK / HPB09P_CLK som240_2_c11
set_property -dict {LOC H1   IOSTANDARD LVCMOS18} [get_ports {phy3_rxd[0]}] ;# from U80.33 RX_D0_SGMII_COP / HPB06N som240_2_a21
set_property -dict {LOC K2   IOSTANDARD LVCMOS18} [get_ports {phy3_rxd[1]}] ;# from U80.34 RX_D1_SGMII_CON / HPB07P som240_2_b15
set_property -dict {LOC J2   IOSTANDARD LVCMOS18} [get_ports {phy3_rxd[2]}] ;# from U80.35 RX_D2_SGMII_SOP / HPB07N som240_2_b16
set_property -dict {LOC H4   IOSTANDARD LVCMOS18} [get_ports {phy3_rxd[3]}] ;# from U80.36 RX_D3_SGMII_SON / HPB08P som240_2_a14
set_property -dict {LOC H3   IOSTANDARD LVCMOS18} [get_ports {phy3_rx_ctl}] ;# from U80.38 RX_CTRL HBP08N som240_2_a15
set_property -dict {LOC J1   IOSTANDARD LVCMOS18 SLEW FAST DRIVE 12} [get_ports {phy3_tx_clk}] ;# from U80.29 GTX_CLK / HPB06P_CLK som240_2_a20
set_property -dict {LOC U9   IOSTANDARD LVCMOS18 SLEW FAST DRIVE 12} [get_ports {phy3_txd[0]}] ;# from U80.28 TX_D0_SGMII_SIN / HPB01P som240_2_d12
set_property -dict {LOC V9   IOSTANDARD LVCMOS18 SLEW FAST DRIVE 12} [get_ports {phy3_txd[1]}] ;# from U80.27 TX_D1_SGMII_SIP / HPB01N som240_2_d13
set_property -dict {LOC U8   IOSTANDARD LVCMOS18 SLEW FAST DRIVE 12} [get_ports {phy3_txd[2]}] ;# from U80.26 TX_D2 / HPB02P som240_2_c17
set_property -dict {LOC V8   IOSTANDARD LVCMOS18 SLEW FAST DRIVE 12} [get_ports {phy3_txd[3]}] ;# from U80.25 TX_D3 / HPB02N som240_2_c18
set_property -dict {LOC Y8   IOSTANDARD LVCMOS18 SLEW FAST DRIVE 12} [get_ports {phy3_tx_ctl}] ;# from U80.37 TX_CTRL / HPB00_CCN som240_2_d16
set_property -dict {LOC K1   IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 12} [get_ports {phy3_reset_n}] ;# from U80.43 RESET_B / HPB05_CCN som240_2_b19
#set_property -dict {LOC T8   IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 12} [get_ports {phy3_mdio}] ;# from U80.17 MDIO / HPB03N som240_2_b25
#set_property -dict {LOC R8   IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 12} [get_ports {phy3_mdc}] ;# from U80.16 MDC / HPB03P som240_2_b24
#set_property -dict {LOC R7   IOSTANDARD LVCMOS18} [get_ports {phy3_led[0]}] ;# from U80.47 LED_0 / HPB04P som240_2_d21
#set_property -dict {LOC T7   IOSTANDARD LVCMOS18} [get_ports {phy3_led[1]}] ;# from U80.46 LED_1 / HPB04N som240_2_d22
#set_property -dict {LOC L1   IOSTANDARD LVCMOS18} [get_ports {phy3_led[2]}] ;# from U80.45 LED_2 / HPB05_CCP som240_2_b18

create_clock -period 8.000 -name {phy3_rx_clk} [get_ports {phy3_rx_clk}]

set_false_path -to [get_ports {phy3_reset_n}]
set_output_delay 0 [get_ports {phy3_reset_n}]
# set_false_path -from [get_ports {phy3_led[*]}]
# set_input_delay 0 [get_ports {phy3_led[*]}]

#set_false_path -to [get_ports {phy3_mdio phy3_mdc}]
#set_output_delay 0 [get_ports {phy3_mdio phy3_mdc}]
#set_false_path -from [get_ports {phy3_mdio}]
#set_input_delay 0 [get_ports {phy3_mdio}]

# SFP+ Interface
set_property -dict {LOC T2  } [get_ports sfp_rx_p] ;# MGTHRXP2_224 GTHE4_CHANNEL_X1Y12 / GTHE4_COMMON_X1Y3 / GTH_DP2_C2M_P som240_2_b1
set_property -dict {LOC T1  } [get_ports sfp_rx_n] ;# MGTHRXN2_224 GTHE4_CHANNEL_X1Y12 / GTHE4_COMMON_X1Y3 / GTH_DP2_C2M_N som240_2_b2
set_property -dict {LOC R4  } [get_ports sfp_tx_p] ;# MGTHTXP2_224 GTHE4_CHANNEL_X1Y12 / GTHE4_COMMON_X1Y3 / GTH_DP2_M2C_P som240_2_b5
set_property -dict {LOC R3  } [get_ports sfp_tx_n] ;# MGTHTXN2_224 GTHE4_CHANNEL_X1Y12 / GTHE4_COMMON_X1Y3 / GTH_DP2_M2C_N som240_2_b6
set_property -dict {LOC Y6  } [get_ports sfp_mgt_refclk_p] ;# MGTREFCLK0P_224 from U90 / GTH_REFCLK0_C2M_P som240_2_c3
set_property -dict {LOC Y5  } [get_ports sfp_mgt_refclk_n] ;# MGTREFCLK0N_224 from U90 / GTH_REFCLK0_C2M_N som240_2_c4
set_property -dict {LOC Y10  IOSTANDARD LVCMOS33 SLEW SLOW DRIVE 8} [get_ports sfp_tx_disable] ;# HDB19 som240_2_a47
set_property -dict {LOC A10  IOSTANDARD LVCMOS33} [get_ports sfp_tx_fault]   ;# HDA19 som240_1_c23
set_property -dict {LOC J12  IOSTANDARD LVCMOS33} [get_ports sfp_rx_los]     ;# HDA10 som240_1_a16
set_property -dict {LOC W10  IOSTANDARD LVCMOS33} [get_ports sfp_mod_abs]    ;# HDB18 som240_2_a46
set_property -dict {LOC AB11 IOSTANDARD LVCMOS33 SLEW SLOW DRIVE 8} [get_ports sfp_i2c_scl]    ;# HDB16 som240_2_b49
set_property -dict {LOC AC11 IOSTANDARD LVCMOS33 SLEW SLOW DRIVE 8} [get_ports sfp_i2c_sda]    ;# HDB17 som240_2_b50

# 156.25 MHz MGT reference clock
create_clock -period 6.400 -name sfp_mgt_refclk [get_ports sfp_mgt_refclk_p]

set_false_path -to [get_ports {sfp_tx_disable}]
set_output_delay 0 [get_ports {sfp_tx_disable}]
set_false_path -from [get_ports {sfp_tx_fault sfp_rx_los sfp_mod_abs}]
set_input_delay 0 [get_ports {sfp_tx_fault sfp_rx_los sfp_mod_abs}]

set_false_path -to [get_ports {sfp_i2c_sda sfp_i2c_scl}]
set_output_delay 0 [get_ports {sfp_i2c_sda sfp_i2c_scl}]
set_false_path -from [get_ports {sfp_i2c_sda sfp_i2c_scl}]
set_input_delay 0 [get_ports {sfp_i2c_sda sfp_i2c_scl}]
