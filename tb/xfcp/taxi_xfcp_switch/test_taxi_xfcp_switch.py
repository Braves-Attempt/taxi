#!/usr/bin/env python
# SPDX-License-Identifier: CERN-OHL-S-2.0
"""

Copyright (c) 2025 FPGA Ninja, LLC

Authors:
- Alex Forencich

"""

import itertools
import logging
import os
import struct
import sys

import cocotb_test.simulator
import pytest

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge
from cocotb.regression import TestFactory

from cocotbext.axi import AxiStreamBus, AxiStreamSource, AxiStreamSink

try:
    from xfcp import XfcpFrame
except ImportError:
    # attempt import from current directory
    sys.path.insert(0, os.path.join(os.path.dirname(__file__)))
    try:
        from xfcp import XfcpFrame
    finally:
        del sys.path[0]


class TB(object):
    def __init__(self, dut, baud=3e6):
        self.dut = dut

        self.log = logging.getLogger("cocotb.tb")
        self.log.setLevel(logging.DEBUG)

        cocotb.start_soon(Clock(dut.clk, 8, units="ns").start())

        self.up_source = AxiStreamSource(AxiStreamBus.from_entity(dut.up_xfcp_in), dut.clk, dut.rst)
        self.up_sink = AxiStreamSink(AxiStreamBus.from_entity(dut.up_xfcp_out), dut.clk, dut.rst)

        self.dn_sources = [AxiStreamSource(AxiStreamBus.from_entity(bus), dut.clk, dut.rst) for bus in dut.dn_xfcp_in]
        self.dn_sinks = [AxiStreamSink(AxiStreamBus.from_entity(bus), dut.clk, dut.rst) for bus in dut.dn_xfcp_out]

    def set_idle_generator(self, generator=None):
        if generator:
            self.up_source.set_pause_generator(generator())
            for src in self.dn_sources:
                src.set_pause_generator(generator())

    def set_backpressure_generator(self, generator=None):
        if generator:
            self.up_sink.set_pause_generator(generator())
            for snk in self.dn_sinks:
                snk.set_pause_generator(generator())

    async def reset(self):
        self.dut.rst.setimmediatevalue(0)
        await RisingEdge(self.dut.clk)
        await RisingEdge(self.dut.clk)
        self.dut.rst.value = 1
        await RisingEdge(self.dut.clk)
        await RisingEdge(self.dut.clk)
        self.dut.rst.value = 0
        await RisingEdge(self.dut.clk)
        await RisingEdge(self.dut.clk)


async def run_test_downstream(dut, idle_inserter=None, backpressure_inserter=None, port=0):

    tb = TB(dut)

    await tb.reset()

    tb.set_idle_generator(idle_inserter)
    tb.set_backpressure_generator(backpressure_inserter)

    pkt = XfcpFrame()
    pkt.path = [port]
    pkt.ptype = 0x01
    pkt.payload = bytearray(range(8))

    tb.log.debug("TX packet: %s", pkt)

    await tb.up_source.send(pkt.build())

    rx_frame = await tb.dn_sinks[port].recv()
    rx_pkt = XfcpFrame.parse(rx_frame.tdata)

    tb.log.debug("RX packet: %s", rx_pkt)

    assert rx_pkt.path == []
    assert rx_pkt.ptype == 0x01
    assert rx_pkt.payload == bytearray(range(8))

    await RisingEdge(dut.clk)
    await RisingEdge(dut.clk)


async def run_test_upstream(dut, idle_inserter=None, backpressure_inserter=None, port=0):

    tb = TB(dut)

    await tb.reset()

    tb.set_idle_generator(idle_inserter)
    tb.set_backpressure_generator(backpressure_inserter)

    pkt = XfcpFrame()
    pkt.ptype = 0x01
    pkt.payload = bytearray(range(8))

    tb.log.debug("TX packet: %s", pkt)

    await tb.dn_sources[port].send(pkt.build())

    rx_frame = await tb.up_sink.recv()
    rx_pkt = XfcpFrame.parse(rx_frame.tdata)

    tb.log.debug("RX packet: %s", rx_pkt)

    assert rx_pkt.path == [port]
    assert rx_pkt.ptype == 0x01
    assert rx_pkt.payload == bytearray(range(8))

    await RisingEdge(dut.clk)
    await RisingEdge(dut.clk)


async def run_test_id(dut, idle_inserter=None, backpressure_inserter=None):

    tb = TB(dut)

    await tb.reset()

    tb.set_idle_generator(idle_inserter)
    tb.set_backpressure_generator(backpressure_inserter)

    pkt = XfcpFrame()
    pkt.ptype = 0xFE
    pkt.payload = b''

    tb.log.debug("TX packet: %s", pkt)

    await tb.up_source.send(pkt.build())

    rx_frame = await tb.up_sink.recv()
    rx_pkt = XfcpFrame.parse(rx_frame.tdata)

    tb.log.debug("RX packet: %s", rx_pkt)

    assert len(rx_pkt.payload) == 32

    await RisingEdge(dut.clk)
    await RisingEdge(dut.clk)


def cycle_pause():
    return itertools.cycle([1, 1, 1, 0])


if cocotb.SIM_NAME:

    ports = len(cocotb.top.dn_xfcp_out)

    for test in [run_test_downstream, run_test_upstream]:

        factory = TestFactory(test)
        factory.add_option("idle_inserter", [None, cycle_pause])
        factory.add_option("backpressure_inserter", [None, cycle_pause])
        factory.add_option("port", list(range(ports)))
        factory.generate_tests()

    for test in [run_test_id]:

        factory = TestFactory(test)
        factory.add_option("idle_inserter", [None, cycle_pause])
        factory.add_option("backpressure_inserter", [None, cycle_pause])
        factory.generate_tests()


# cocotb-test

tests_dir = os.path.dirname(__file__)
rtl_dir = os.path.abspath(os.path.join(tests_dir, '..', '..', '..', 'rtl'))


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


@pytest.mark.parametrize("ports", [1, 4])
def test_taxi_xfcp_switch(request, ports):

    dut = "taxi_xfcp_switch"
    module = os.path.splitext(os.path.basename(__file__))[0]
    toplevel = module

    verilog_sources = [
        os.path.join(tests_dir, f"{toplevel}.sv"),
        os.path.join(rtl_dir, "xfcp", f"{dut}.f"),
    ]

    verilog_sources = process_f_files(verilog_sources)

    parameters = {}

    parameters['PORTS'] = ports

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
