# SPDX-License-Identifier: CERN-OHL-S-2.0
#
# Copyright (c) 2020-2025 FPGA Ninja, LLC
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

DUT      = taxi_axil_register
COCOTB_TEST_MODULES = test_$(DUT)
COCOTB_TOPLEVEL     = test_$(DUT)
MODULE   = $(COCOTB_TEST_MODULES)
TOPLEVEL = $(COCOTB_TOPLEVEL)
VERILOG_SOURCES += $(COCOTB_TOPLEVEL).sv
VERILOG_SOURCES += $(RTL_DIR)/$(DUT).f

# handle file list files
process_f_file = $(call process_f_files,$(addprefix $(dir $1),$(shell cat $1)))
process_f_files = $(foreach f,$1,$(if $(filter %.f,$f),$(call process_f_file,$f),$f))
uniq_base = $(if $1,$(call uniq_base,$(foreach f,$1,$(if $(filter-out $(notdir $(lastword $1)),$(notdir $f)),$f,))) $(lastword $1))
VERILOG_SOURCES := $(call uniq_base,$(call process_f_files,$(VERILOG_SOURCES)))

REG_TYPE ?= 1

# module parameters
export PARAM_DATA_W := 32
export PARAM_ADDR_W := 32
export PARAM_STRB_W := $(shell expr $(PARAM_DATA_W) / 8 )
export PARAM_AWUSER_EN := 0
export PARAM_AWUSER_W := 1
export PARAM_WUSER_EN := 0
export PARAM_WUSER_W := 1
export PARAM_BUSER_EN := 0
export PARAM_BUSER_W := 1
export PARAM_ARUSER_EN := 0
export PARAM_ARUSER_W := 1
export PARAM_RUSER_EN := 0
export PARAM_RUSER_W := 1
export PARAM_AW_REG_TYPE := $(REG_TYPE)
export PARAM_W_REG_TYPE := $(REG_TYPE)
export PARAM_B_REG_TYPE := $(REG_TYPE)
export PARAM_AR_REG_TYPE := $(REG_TYPE)
export PARAM_R_REG_TYPE := $(REG_TYPE)

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
