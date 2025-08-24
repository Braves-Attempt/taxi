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
