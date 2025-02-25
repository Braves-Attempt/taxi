# SPDX-License-Identifier: MIT
#
# Copyright (c) 2025 FPGA Ninja, LLC
#
# Authors:
# - Alex Forencich
#

# FPGA settings
FPGA_PART = xcku3p-ffvb676-2-e
FPGA_TOP = fpga
FPGA_ARCH = kintexuplus

# Files for synthesis
SYN_FILES = ../rtl/fpga.sv
SYN_FILES += ../rtl/fpga_core.sv
SYN_FILES += ../lib/taxi/rtl/eth/us/taxi_eth_mac_25g_us.f
SYN_FILES += ../lib/taxi/rtl/axis/taxi_axis_async_fifo.f
SYN_FILES += ../lib/taxi/rtl/sync/taxi_sync_reset.sv
SYN_FILES += ../lib/taxi/rtl/sync/taxi_sync_signal.sv
SYN_FILES += ../lib/taxi/rtl/io/taxi_debounce_switch.sv

# XDC files
XDC_FILES = ../fpga.xdc
XDC_FILES += ../lib/taxi/syn/vivado/taxi_eth_mac_fifo.tcl
XDC_FILES += ../lib/taxi/syn/vivado/taxi_axis_async_fifo.tcl
XDC_FILES += ../lib/taxi/syn/vivado/taxi_sync_reset.tcl

# IP
IP_TCL_FILES = ../lib/taxi/rtl/eth/us/taxi_eth_mac_25g_us_gty_10g_161.tcl

# Configuration
# CONFIG_TCL_FILES = ./config.tcl

include ../common/vivado.mk

program: $(PROJECT).bit
	echo "open_hw_manager" > program.tcl
	echo "connect_hw_server" >> program.tcl
	echo "open_hw_target" >> program.tcl
	echo "current_hw_device [lindex [get_hw_devices] 0]" >> program.tcl
	echo "refresh_hw_device -update_hw_probes false [current_hw_device]" >> program.tcl
	echo "set_property PROGRAM.FILE {$(PROJECT).bit} [current_hw_device]" >> program.tcl
	echo "program_hw_devices [current_hw_device]" >> program.tcl
	echo "exit" >> program.tcl
	vivado -nojournal -nolog -mode batch -source program.tcl
