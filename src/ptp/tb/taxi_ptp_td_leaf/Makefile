# SPDX-License-Identifier: CERN-OHL-S-2.0
#
# Copyright (c) 2023-2025 FPGA Ninja, LLC
#
# Authors:
# - Alex Forencich

TOPLEVEL_LANG = verilog

SIM ?= verilator
WAVES ?= 0

COCOTB_HDL_TIMEUNIT = 1ns
COCOTB_HDL_TIMEPRECISION = 1ps

RTL_DIR = ../../rtl
LIB_DIR = ../../lib
TAXI_SRC_DIR = $(LIB_DIR)/taxi/src

DUT      = taxi_ptp_td_leaf
COCOTB_TEST_MODULES = test_$(DUT)
COCOTB_TOPLEVEL     = $(DUT)
MODULE   = $(COCOTB_TEST_MODULES)
TOPLEVEL = $(COCOTB_TOPLEVEL)
VERILOG_SOURCES += $(RTL_DIR)/$(DUT).sv

# handle file list files
process_f_file = $(call process_f_files,$(addprefix $(dir $1),$(shell cat $1)))
process_f_files = $(foreach f,$1,$(if $(filter %.f,$f),$(call process_f_file,$f),$f))
uniq_base = $(if $1,$(call uniq_base,$(foreach f,$1,$(if $(filter-out $(notdir $(lastword $1)),$(notdir $f)),$f,))) $(lastword $1))
VERILOG_SOURCES := $(call uniq_base,$(call process_f_files,$(VERILOG_SOURCES)))

# module parameters
export PARAM_TS_REL_EN := "1'b1"
export PARAM_TS_TOD_EN := "1'b1"
export PARAM_TS_FNS_W := 16
export PARAM_TS_REL_NS_W := 48
export PARAM_TS_TOD_S_W := 48
export PARAM_TS_REL_W := $(shell expr $(PARAM_TS_REL_NS_W) + $(PARAM_TS_FNS_W))
export PARAM_TS_TOD_W := $(shell expr $(PARAM_TS_TOD_S_W) + 32 + $(PARAM_TS_FNS_W))
export PARAM_TD_SDI_PIPELINE := 2

ifeq ($(SIM), icarus)
	PLUSARGS += -fst

	COMPILE_ARGS += $(foreach v,$(filter PARAM_%,$(.VARIABLES)),-P $(COCOTB_TOPLEVEL).$(subst PARAM_,,$(v))=$($(v)))
else ifeq ($(SIM), verilator)
	COMPILE_ARGS += $(foreach v,$(filter PARAM_%,$(.VARIABLES)),-G$(subst PARAM_,,$(v))=$($(v)))

	ifeq ($(WAVES), 1)
		COMPILE_ARGS += --trace-fst
		VERILATOR_TRACE = 1
	endif
endif

include $(shell cocotb-config --makefiles)/Makefile.sim
