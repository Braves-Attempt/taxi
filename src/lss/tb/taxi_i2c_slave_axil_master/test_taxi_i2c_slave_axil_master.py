#!/usr/bin/env python
# SPDX-License-Identifier: CERN-OHL-S-2.0
"""

Copyright (c) 2020-2025 FPGA Ninja, LLC

Authors:
- Alex Forencich

"""

import itertools
import logging
import os
import random
import struct

import cocotb_test.simulator

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, Timer
from cocotb.regression import TestFactory

from cocotbext.i2c import I2cMaster
from cocotbext.axi import AxiLiteBus, AxiLiteRam


class TB:
    def __init__(self, dut):
        self.dut = dut

        self.log = logging.getLogger("cocotb.tb")
        self.log.setLevel(logging.DEBUG)

        cocotb.fork(Clock(dut.clk, 8, units="ns").start())

        self.i2c_master = I2cMaster(sda=dut.i2c_sda_o, sda_o=dut.i2c_sda_i,
            scl=dut.i2c_scl_o, scl_o=dut.i2c_scl_i, speed=4000e3)

        self.axil_ram = AxiLiteRam(AxiLiteBus.from_entity(dut.m_axil), dut.clk, dut.rst, size=2**16)

        dut.enable.setimmediatevalue(1)
        dut.device_address.setimmediatevalue(0x50)

    def set_idle_generator(self, generator=None):
        if generator:
            self.axil_ram.write_if.b_channel.set_pause_generator(generator())
            self.axil_ram.read_if.r_channel.set_pause_generator(generator())

    def set_backpressure_generator(self, generator=None):
        if generator:
            self.axil_ram.write_if.aw_channel.set_pause_generator(generator())
            self.axil_ram.write_if.w_channel.set_pause_generator(generator())
            self.axil_ram.read_if.ar_channel.set_pause_generator(generator())

    async def cycle_reset(self):
        self.dut.rst.setimmediatevalue(0)
        await RisingEdge(self.dut.clk)
        await RisingEdge(self.dut.clk)
        self.dut.rst.value = 1
        await RisingEdge(self.dut.clk)
        await RisingEdge(self.dut.clk)
        self.dut.rst.value = 0
        await RisingEdge(self.dut.clk)
        await RisingEdge(self.dut.clk)


async def run_test_write(dut, data_in=None, idle_inserter=None, backpressure_inserter=None):

    tb = TB(dut)

    byte_lanes = tb.axil_ram.write_if.byte_lanes

    await tb.cycle_reset()

    tb.set_idle_generator(idle_inserter)
    tb.set_backpressure_generator(backpressure_inserter)

    for length in range(1, byte_lanes*2):
        for offset in range(byte_lanes):
            tb.log.info("length %d, offset %d", length, offset)
            addr = offset+0x1000
            test_data = bytearray([x % 256 for x in range(length)])

            tb.axil_ram.write(addr-128, b'\xaa'*(length+256))

            await tb.i2c_master.write(0x50, struct.pack('>H', addr)+test_data)
            await tb.i2c_master.send_stop()

            tb.log.debug("%s", tb.axil_ram.hexdump_str((addr & ~0xf)-16, (((addr & 0xf)+length-1) & ~0xf)+48))

            assert tb.axil_ram.read(addr, length) == test_data
            assert tb.axil_ram.read(addr-1, 1) == b'\xaa'
            assert tb.axil_ram.read(addr+length, 1) == b'\xaa'

    await RisingEdge(dut.clk)
    await RisingEdge(dut.clk)


async def run_test_read(dut, data_in=None, idle_inserter=None, backpressure_inserter=None):

    tb = TB(dut)

    byte_lanes = tb.axil_ram.write_if.byte_lanes

    await tb.cycle_reset()

    tb.set_idle_generator(idle_inserter)
    tb.set_backpressure_generator(backpressure_inserter)

    for length in range(1, byte_lanes*2):
        for offset in range(byte_lanes):
            tb.log.info("length %d, offset %d", length, offset)
            addr = offset+0x1000
            test_data = bytearray([x % 256 for x in range(length)])

            tb.axil_ram.write(addr, test_data)

            await tb.i2c_master.write(0x50, struct.pack('>H', addr))
            data = await tb.i2c_master.read(0x50, length)
            await tb.i2c_master.send_stop()

            assert data == test_data

    await RisingEdge(dut.clk)
    await RisingEdge(dut.clk)


def cycle_pause():
    return itertools.cycle([1, 1, 1, 0])


if getattr(cocotb, 'top', None) is not None:

    for test in [run_test_write, run_test_read]:

        factory = TestFactory(test)
        factory.add_option("idle_inserter", [None, cycle_pause])
        factory.add_option("backpressure_inserter", [None, cycle_pause])
        factory.generate_tests()


# cocotb-test

tests_dir = os.path.abspath(os.path.dirname(__file__))
rtl_dir = os.path.abspath(os.path.join(tests_dir, '..', '..', 'rtl'))
lib_dir = os.path.abspath(os.path.join(tests_dir, '..', '..', 'lib'))
taxi_src_dir = os.path.abspath(os.path.join(lib_dir, 'taxi', 'src'))


def process_f_files(files):
    lst = {}
    for f in files:
        if f[-2:].lower() == '.f':
            with open(f, 'r') as fp:
                l = fp.read().split()
            for f in process_f_files([os.path.join(os.path.dirname(f), x) for x in l]):
                lst[os.path.basename(f)] = f
        else:
            lst[os.path.basename(f)] = f
    return list(lst.values())


def test_taxi_i2c_slave_axil_master(request):
    dut = "taxi_i2c_slave_axil_master"
    module = os.path.splitext(os.path.basename(__file__))[0]
    toplevel = module

    verilog_sources = [
        os.path.join(tests_dir, f"{toplevel}.sv"),
        os.path.join(rtl_dir, f"{dut}.f"),
    ]

    verilog_sources = process_f_files(verilog_sources)

    parameters = {}

    parameters['FILTER_LEN'] = 4
    parameters['AXIL_DATA_W'] = 32
    parameters['AXIL_ADDR_W'] = 16

    extra_env = {f'PARAM_{k}': str(v) for k, v in parameters.items()}

    sim_build = os.path.join(tests_dir, "sim_build",
        request.node.name.replace('[', '-').replace(']', ''))

    cocotb_test.simulator.run(
        simulator="verilator",
        python_search=[tests_dir],
        verilog_sources=verilog_sources,
        toplevel=toplevel,
        module=module,
        parameters=parameters,
        sim_build=sim_build,
        extra_env=extra_env,
    )
