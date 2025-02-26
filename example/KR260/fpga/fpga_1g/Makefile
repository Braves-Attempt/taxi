# SPDX-License-Identifier: MIT
#
# Copyright (c) 2025 FPGA Ninja, LLC
#
# Authors:
# - Alex Forencich
#

# FPGA settings
FPGA_PART = xck26-sfvc784-2LV-c
FPGA_TOP = fpga
FPGA_ARCH = zynquplus

# Files for synthesis
SYN_FILES = ../rtl/fpga.sv
SYN_FILES += ../rtl/fpga_core.sv
SYN_FILES += ../lib/taxi/rtl/eth/taxi_eth_mac_1g_fifo.f
SYN_FILES += ../lib/taxi/rtl/eth/taxi_eth_mac_1g_rgmii_fifo.f
SYN_FILES += ../lib/taxi/rtl/sync/taxi_sync_reset.sv
SYN_FILES += ../lib/taxi/rtl/sync/taxi_sync_signal.sv

# XDC files
XDC_FILES = ../fpga.xdc
XDC_FILES += ../eth_rgmii.xdc
XDC_FILES += ../lib/taxi/syn/vivado/taxi_rgmii_phy_if.tcl
XDC_FILES += ../lib/taxi/syn/vivado/taxi_eth_mac_1g_rgmii.tcl
XDC_FILES += ../lib/taxi/syn/vivado/taxi_eth_mac_fifo.tcl
XDC_FILES += ../lib/taxi/syn/vivado/taxi_axis_async_fifo.tcl
XDC_FILES += ../lib/taxi/syn/vivado/taxi_sync_reset.tcl
XDC_FILES += ../lib/taxi/syn/vivado/taxi_sync_signal.tcl

# IP
IP_TCL_FILES = ../ip/basex_pcs_pma_0.tcl

# Configuration
CONFIG_TCL_FILES = ./config.tcl

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
