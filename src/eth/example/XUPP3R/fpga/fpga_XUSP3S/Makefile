# SPDX-License-Identifier: MIT
#
# Copyright (c) 2025 FPGA Ninja, LLC
#
# Authors:
# - Alex Forencich
#

# FPGA settings
FPGA_PART = xcvu095-ffvb2104-2-e
FPGA_TOP = fpga
FPGA_ARCH = virtexu

RTL_DIR = ../rtl
LIB_DIR = ../lib
TAXI_SRC_DIR = $(LIB_DIR)/taxi/src

# Files for synthesis
SYN_FILES = $(RTL_DIR)/fpga_xusp3s.sv
SYN_FILES += $(RTL_DIR)/fpga_core.sv
SYN_FILES += $(TAXI_SRC_DIR)/eth/rtl/us/taxi_eth_mac_25g_us.f
SYN_FILES += $(TAXI_SRC_DIR)/xfcp/rtl/taxi_xfcp_if_uart.f
SYN_FILES += $(TAXI_SRC_DIR)/xfcp/rtl/taxi_xfcp_switch.sv
SYN_FILES += $(TAXI_SRC_DIR)/xfcp/rtl/taxi_xfcp_mod_stats.f
SYN_FILES += $(TAXI_SRC_DIR)/axis/rtl/taxi_axis_async_fifo.f
SYN_FILES += $(TAXI_SRC_DIR)/sync/rtl/taxi_sync_reset.sv
SYN_FILES += $(TAXI_SRC_DIR)/sync/rtl/taxi_sync_signal.sv

# XDC files
XDC_FILES = ../fpga_xusp3s.xdc
XDC_FILES += $(TAXI_SRC_DIR)/eth/syn/vivado/taxi_eth_mac_fifo.tcl
XDC_FILES += $(TAXI_SRC_DIR)/axis/syn/vivado/taxi_axis_async_fifo.tcl
XDC_FILES += $(TAXI_SRC_DIR)/sync/syn/vivado/taxi_sync_reset.tcl
XDC_FILES += $(TAXI_SRC_DIR)/sync/syn/vivado/taxi_sync_signal.tcl

# IP
IP_TCL_FILES += $(TAXI_SRC_DIR)/eth/rtl/us/taxi_eth_phy_25g_us_gty_25g_322.tcl

# Configuration
#CONFIG_TCL_FILES = config.tcl

include ../common/vivado.mk

%_fallback.bit: %.bit
	echo "open_project $*.xpr" > generate_fallback_bit.tcl
	echo "open_run impl_1" >> generate_fallback_bit.tcl
	echo "startgroup" >> generate_fallback_bit.tcl
	echo "set_property BITSTREAM.CONFIG.SPI_32BIT_ADDR NO [current_design]" >> generate_fallback_bit.tcl
	echo "endgroup" >> generate_fallback_bit.tcl
	echo "write_bitstream -verbose -force $*_fallback.bit" >> generate_fallback_bit.tcl
	echo "undo" >> generate_fallback_bit.tcl
	echo "exit" >> generate_fallback_bit.tcl
	vivado -nojournal -nolog -mode batch -source generate_fallback_bit.tcl
	mkdir -p rev
	EXT=bit; COUNT=100; \
	while [ -e rev/$*_rev$$COUNT.$$EXT ]; \
	do COUNT=$$((COUNT+1)); done; \
	COUNT=$$((COUNT-1)); \
	cp $@ rev/$*_fallback_rev$$COUNT.$$EXT; \
	echo "Output: rev/$*_fallback_rev$$COUNT.$$EXT";

program: $(FPGA_TOP).bit
	echo "open_hw" > program.tcl
	echo "connect_hw_server" >> program.tcl
	echo "open_hw_target" >> program.tcl
	echo "current_hw_device [lindex [get_hw_devices] 0]" >> program.tcl
	echo "refresh_hw_device -update_hw_probes false [current_hw_device]" >> program.tcl
	echo "set_property PROGRAM.FILE {$(FPGA_TOP).bit} [current_hw_device]" >> program.tcl
	echo "program_hw_devices [current_hw_device]" >> program.tcl
	echo "exit" >> program.tcl
	vivado -nojournal -nolog -mode batch -source program.tcl

%.mcs %.prm: %.bit
	echo "write_cfgmem -force -format mcs -size 64 -interface SPIx4 -loadbit {up 0x00000000 $*.bit} -checksum -file $*.mcs" > generate_mcs.tcl
	echo "exit" >> generate_mcs.tcl
	vivado -nojournal -nolog -mode batch -source generate_mcs.tcl
	mkdir -p rev
	COUNT=100; \
	while [ -e rev/$*_rev$$COUNT.bit ]; \
	do COUNT=$$((COUNT+1)); done; \
	COUNT=$$((COUNT-1)); \
	for x in .mcs .prm; \
	do cp $*$$x rev/$*_rev$$COUNT$$x; \
	echo "Output: rev/$*_rev$$COUNT$$x"; done;

%_fallback.mcs %_fallback.prm: %_fallback.bit
	echo "write_cfgmem -force -format mcs -size 64 -interface SPIx4 -loadbit {up 0x03000000 $*_fallback.bit} -checksum -file $*_fallback.mcs" > generate_fallback_mcs.tcl
	echo "exit" >> generate_fallback_mcs.tcl
	vivado -nojournal -nolog -mode batch -source generate_fallback_mcs.tcl
	mkdir -p rev
	COUNT=100; \
	while [ -e rev/$*_rev$$COUNT.bit ]; \
	do COUNT=$$((COUNT+1)); done; \
	COUNT=$$((COUNT-1)); \
	for x in .mcs .prm; \
	do cp $*_fallback$$x rev/$*_fallback_rev$$COUNT$$x; \
	echo "Output: rev/$*_fallback_rev$$COUNT$$x"; done;

%_full.mcs %_full.prm: %_fallback.bit %.bit
	echo "write_cfgmem -force -format mcs -size 64 -interface SPIx4 -loadbit {up 0x00000000 $*.bit up 0x03000000 $*_fallback.bit} -checksum -file $*_full.mcs" > generate_full_mcs.tcl
	echo "exit" >> generate_full_mcs.tcl
	vivado -nojournal -nolog -mode batch -source generate_full_mcs.tcl
	mkdir -p rev
	COUNT=100; \
	while [ -e rev/$*_rev$$COUNT.bit ]; \
	do COUNT=$$((COUNT+1)); done; \
	COUNT=$$((COUNT-1)); \
	for x in .mcs .prm; \
	do cp $*_full$$x rev/$*_full_rev$$COUNT$$x; \
	echo "Output: rev/$*_full_rev$$COUNT$$x"; done;

flash: $(FPGA_TOP).mcs $(FPGA_TOP).prm
	echo "open_hw" > flash.tcl
	echo "connect_hw_server" >> flash.tcl
	echo "open_hw_target" >> flash.tcl
	echo "current_hw_device [lindex [get_hw_devices] 0]" >> flash.tcl
	echo "refresh_hw_device -update_hw_probes false [current_hw_device]" >> flash.tcl
	echo "create_hw_cfgmem -hw_device [current_hw_device] [lindex [get_cfgmem_parts {mt25ql512-spi-x1_x2_x4}] 0]" >> flash.tcl
	echo "current_hw_cfgmem -hw_device [current_hw_device] [get_property PROGRAM.HW_CFGMEM [current_hw_device]]" >> flash.tcl
	echo "set_property PROGRAM.FILES [list \"$(FPGA_TOP).mcs\"] [current_hw_cfgmem]" >> flash.tcl
	echo "set_property PROGRAM.PRM_FILES [list \"$(FPGA_TOP).prm\"] [current_hw_cfgmem]" >> flash.tcl
	echo "set_property PROGRAM.ERASE 1 [current_hw_cfgmem]" >> flash.tcl
	echo "set_property PROGRAM.CFG_PROGRAM 1 [current_hw_cfgmem]" >> flash.tcl
	echo "set_property PROGRAM.VERIFY 1 [current_hw_cfgmem]" >> flash.tcl
	echo "set_property PROGRAM.CHECKSUM 0 [current_hw_cfgmem]" >> flash.tcl
	echo "set_property PROGRAM.ADDRESS_RANGE {use_file} [current_hw_cfgmem]" >> flash.tcl
	echo "set_property PROGRAM.UNUSED_PIN_TERMINATION {pull-none} [current_hw_cfgmem]" >> flash.tcl
	echo "create_hw_bitstream -hw_device [current_hw_device] [get_property PROGRAM.HW_CFGMEM_BITFILE [current_hw_device]]" >> flash.tcl
	echo "program_hw_devices [current_hw_device]" >> flash.tcl
	echo "refresh_hw_device [current_hw_device]" >> flash.tcl
	echo "program_hw_cfgmem -hw_cfgmem [current_hw_cfgmem]" >> flash.tcl
	echo "boot_hw_device [current_hw_device]" >> flash.tcl
	echo "exit" >> flash.tcl
	vivado -nojournal -nolog -mode batch -source flash.tcl

flash%: $(FPGA_TOP)%.mcs $(FPGA_TOP)%.prm
	echo "open_hw" > flash$*.tcl
	echo "connect_hw_server" >> flash$*.tcl
	echo "open_hw_target" >> flash$*.tcl
	echo "current_hw_device [lindex [get_hw_devices] 0]" >> flash$*.tcl
	echo "refresh_hw_device -update_hw_probes false [current_hw_device]" >> flash$*.tcl
	echo "create_hw_cfgmem -hw_device [current_hw_device] [lindex [get_cfgmem_parts {mt25ql512-spi-x1_x2_x4}] 0]" >> flash$*.tcl
	echo "current_hw_cfgmem -hw_device [current_hw_device] [get_property PROGRAM.HW_CFGMEM [current_hw_device]]" >> flash$*.tcl
	echo "set_property PROGRAM.FILES [list \"$(FPGA_TOP)$*.mcs\"] [current_hw_cfgmem]" >> flash$*.tcl
	echo "set_property PROGRAM.PRM_FILES [list \"$(FPGA_TOP)$*.prm\"] [current_hw_cfgmem]" >> flash$*.tcl
	echo "set_property PROGRAM.ERASE 1 [current_hw_cfgmem]" >> flash$*.tcl
	echo "set_property PROGRAM.CFG_PROGRAM 1 [current_hw_cfgmem]" >> flash$*.tcl
	echo "set_property PROGRAM.VERIFY 1 [current_hw_cfgmem]" >> flash$*.tcl
	echo "set_property PROGRAM.CHECKSUM 0 [current_hw_cfgmem]" >> flash$*.tcl
	echo "set_property PROGRAM.ADDRESS_RANGE {use_file} [current_hw_cfgmem]" >> flash$*.tcl
	echo "set_property PROGRAM.UNUSED_PIN_TERMINATION {pull-none} [current_hw_cfgmem]" >> flash$*.tcl
	echo "create_hw_bitstream -hw_device [current_hw_device] [get_property PROGRAM.HW_CFGMEM_BITFILE [current_hw_device]]" >> flash$*.tcl
	echo "program_hw_devices [current_hw_device]" >> flash$*.tcl
	echo "refresh_hw_device [current_hw_device]" >> flash$*.tcl
	echo "program_hw_cfgmem -hw_cfgmem [current_hw_cfgmem]" >> flash$*.tcl
	echo "boot_hw_device [current_hw_device]" >> flash$*.tcl
	echo "exit" >> flash$*.tcl
	vivado -nojournal -nolog -mode batch -source flash$*.tcl

