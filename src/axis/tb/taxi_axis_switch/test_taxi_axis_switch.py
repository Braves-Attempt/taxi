#!/usr/bin/env python
# SPDX-License-Identifier: CERN-OHL-S-2.0
"""

Copyright (c) 2021-2025 FPGA Ninja, LLC

Authors:
- Alex Forencich

"""

import itertools
import logging
import os
import random

import cocotb_test.simulator
import pytest

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, Event
from cocotb.regression import TestFactory

from cocotbext.axi import AxiStreamBus, AxiStreamFrame, AxiStreamSource, AxiStreamSink


class TB(object):
    def __init__(self, dut):
        self.dut = dut

        self.log = logging.getLogger("cocotb.tb")
        self.log.setLevel(logging.DEBUG)

        cocotb.start_soon(Clock(dut.clk, 10, units="ns").start())

        self.source = [AxiStreamSource(AxiStreamBus.from_entity(bus), dut.clk, dut.rst) for bus in dut.s_axis]
        self.sink = [AxiStreamSink(AxiStreamBus.from_entity(bus), dut.clk, dut.rst) for bus in dut.m_axis]

    def set_idle_generator(self, generator=None):
        if generator:
            for source in self.source:
                source.set_pause_generator(generator())

    def set_backpressure_generator(self, generator=None):
        if generator:
            for sink in self.sink:
                sink.set_pause_generator(generator())

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


async def run_test(dut, payload_lengths=None, payload_data=None, idle_inserter=None, backpressure_inserter=None, s=0, m=0):

    tb = TB(dut)

    id_width = len(tb.source[0].bus.tid)
    id_count = 2**id_width
    id_mask = id_count-1

    dest_width = len(tb.source[0].bus.tdest)
    dest_shift = dest_width-(len(tb.sink)-1).bit_length()

    src_width = (len(tb.source)-1).bit_length()
    src_mask = 2**src_width-1 if src_width else 0
    src_shift = id_width-src_width
    max_count = 2**src_shift

    cur_id = 1

    await tb.reset()

    tb.set_idle_generator(idle_inserter)
    tb.set_backpressure_generator(backpressure_inserter)

    test_frames = []

    for test_data in [payload_data(x) for x in payload_lengths()]:
        test_frame = AxiStreamFrame(test_data)
        test_frame.tid = cur_id | (s << src_shift)
        test_frame.tdest = m << dest_shift

        test_frames.append(test_frame)
        await tb.source[s].send(test_frame)

        cur_id = (cur_id + 1) % max_count

    for test_frame in test_frames:
        rx_frame = await tb.sink[m].recv()

        assert rx_frame.tdata == test_frame.tdata
        assert (rx_frame.tid & id_mask) == test_frame.tid
        assert ((rx_frame.tid >> src_shift) & src_mask) == s
        assert (rx_frame.tid >> id_width) == s
        # assert rx_frame.tdest == test_frame.tdest
        assert not rx_frame.tuser

    assert all(s.empty() for s in tb.sink)

    await RisingEdge(dut.clk)
    await RisingEdge(dut.clk)


async def run_test_tuser_assert(dut, s=0, m=0):

    tb = TB(dut)

    dest_width = len(tb.sink[0].bus.tdest)
    dest_shift = dest_width

    await tb.reset()

    test_data = bytearray(itertools.islice(itertools.cycle(range(256)), 32))
    test_frame = AxiStreamFrame(test_data, tuser=1, tdest=m << dest_shift)
    await tb.source[s].send(test_frame)

    rx_frame = await tb.sink[m].recv()

    assert rx_frame.tdata == test_data
    assert rx_frame.tuser

    assert all(s.empty() for s in tb.sink)

    await RisingEdge(dut.clk)
    await RisingEdge(dut.clk)


async def run_arb_test(dut):

    tb = TB(dut)

    byte_lanes = tb.source[0].byte_lanes
    id_width = len(tb.source[0].bus.tid)
    id_count = 2**id_width
    id_mask = id_count-1

    dest_width = len(tb.source[0].bus.tdest)
    dest_shift = dest_width-(len(tb.sink)-1).bit_length()

    src_width = (len(tb.source)-1).bit_length()
    src_mask = 2**src_width-1 if src_width else 0
    src_shift = id_width-src_width
    max_count = 2**src_shift

    cur_id = 1

    await tb.reset()

    test_frames = []

    length = byte_lanes*16
    test_data = bytearray(itertools.islice(itertools.cycle(range(256)), length))

    for k in range(5):
        test_frame = AxiStreamFrame(test_data, tx_complete=Event())

        src_ind = 0

        if k == 0:
            src_ind = 0
        elif k == 4:
            await test_frames[1].tx_complete.wait()
            for j in range(8):
                await RisingEdge(dut.clk)
            src_ind = 0
        else:
            src_ind = 1

        test_frame.tid = cur_id | (src_ind << src_shift)
        test_frame.tdest = 0

        test_frames.append(test_frame)
        await tb.source[src_ind].send(test_frame)

        cur_id = (cur_id + 1) % max_count

    for k in [0, 1, 2, 4, 3]:
        test_frame = test_frames[k]
        rx_frame = await tb.sink[0].recv()

        assert rx_frame.tdata == test_frame.tdata
        assert (rx_frame.tid & id_mask) == test_frame.tid
        assert ((rx_frame.tid >> src_shift) & src_mask) == (rx_frame.tid >> id_width)
        assert rx_frame.tdest == 0
        assert not rx_frame.tuser

    assert all(s.empty() for s in tb.sink)

    await RisingEdge(dut.clk)
    await RisingEdge(dut.clk)


async def run_stress_test(dut, idle_inserter=None, backpressure_inserter=None):

    tb = TB(dut)

    byte_lanes = tb.source[0].byte_lanes
    id_width = len(tb.source[0].bus.tid)
    id_count = 2**id_width
    id_mask = id_count-1

    dest_width = len(tb.source[0].bus.tdest)
    dest_shift = dest_width-(len(tb.sink)-1).bit_length()

    src_width = (len(tb.source)-1).bit_length()
    src_mask = 2**src_width-1 if src_width else 0
    src_shift = id_width-src_width
    max_count = 2**src_shift

    cur_id = 1

    await tb.reset()

    tb.set_idle_generator(idle_inserter)
    tb.set_backpressure_generator(backpressure_inserter)

    test_frames = [[list() for y in tb.sink] for x in tb.source]

    for p in range(len(tb.source)):
        for k in range(128):
            length = random.randint(1, byte_lanes*16)
            test_data = bytearray(itertools.islice(itertools.cycle(range(256)), length))
            test_frame = AxiStreamFrame(test_data)
            test_frame.tid = cur_id | (p << src_shift)
            dest = random.randrange(len(tb.sink))
            test_frame.tdest = dest << dest_shift

            test_frames[p][dest].append(test_frame)
            await tb.source[p].send(test_frame)

            cur_id = (cur_id + 1) % max_count

    for lst in test_frames:
        while any(lst):
            rx_frame = await tb.sink[[dest for dest, x in enumerate(lst) if x][0]].recv()

            test_frame = None

            for lst_a in test_frames:
                for lst_b in lst_a:
                    if lst_b and lst_b[0].tid == (rx_frame.tid & id_mask):
                        test_frame = lst_b.pop(0)
                        break

            assert test_frame is not None

            assert rx_frame.tdata == test_frame.tdata
            assert (rx_frame.tid & id_mask) == test_frame.tid
            assert ((rx_frame.tid >> src_shift) & src_mask) == (rx_frame.tid >> id_width)
            assert not rx_frame.tuser

    assert all(s.empty() for s in tb.sink)

    await RisingEdge(dut.clk)
    await RisingEdge(dut.clk)


def cycle_pause():
    return itertools.cycle([1, 1, 1, 0])


def size_list():
    data_width = len(cocotb.top.s_axis[0].tdata)
    byte_width = data_width // 8
    return list(range(1, byte_width*4+1))+[512]+[1]*64


def incrementing_payload(length):
    return bytearray(itertools.islice(itertools.cycle(range(256)), length))


if cocotb.SIM_NAME:

    s_count = len(cocotb.top.s_axis)
    m_count = len(cocotb.top.m_axis)

    factory = TestFactory(run_test)
    factory.add_option("payload_lengths", [size_list])
    factory.add_option("payload_data", [incrementing_payload])
    factory.add_option("idle_inserter", [None, cycle_pause])
    factory.add_option("backpressure_inserter", [None, cycle_pause])
    factory.add_option("s", range(min(s_count, 2)))
    factory.add_option("m", range(min(m_count, 2)))
    factory.generate_tests()

    for test in [run_test_tuser_assert]:
        factory = TestFactory(test)
        factory.add_option("s", range(min(s_count, 2)))
        factory.add_option("m", range(min(m_count, 2)))
        factory.generate_tests()

    if s_count > 1:
        factory = TestFactory(run_arb_test)
        factory.generate_tests()

    factory = TestFactory(run_stress_test)
    factory.add_option("idle_inserter", [None, cycle_pause])
    factory.add_option("backpressure_inserter", [None, cycle_pause])
    factory.generate_tests()


# cocotb-test

tests_dir = os.path.dirname(__file__)
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


@pytest.mark.parametrize("data_w", [8, 16, 32])
@pytest.mark.parametrize("m_count", [1, 4])
@pytest.mark.parametrize("s_count", [1, 4])
def test_axis_switch(request, s_count, m_count, data_w):
    dut = "taxi_axis_switch"
    module = os.path.splitext(os.path.basename(__file__))[0]
    toplevel = module

    verilog_sources = [
        os.path.join(tests_dir, f"{toplevel}.sv"),
        os.path.join(rtl_dir, f"{dut}.f"),
    ]

    verilog_sources = process_f_files(verilog_sources)

    parameters = {}

    parameters['M_COUNT'] = m_count
    parameters['S_COUNT'] = s_count
    parameters['DATA_W'] = data_w
    parameters['KEEP_EN'] = int(parameters['DATA_W'] > 8)
    parameters['KEEP_W'] = (parameters['DATA_W'] + 7) // 8
    parameters['ID_EN'] = 1
    parameters['S_ID_W'] = 16
    parameters['M_ID_W'] = parameters['S_ID_W'] + (s_count-1).bit_length()
    parameters['DEST_EN'] = 1
    parameters['M_DEST_W'] = 8
    parameters['S_DEST_W'] = parameters['M_DEST_W'] + (m_count-1).bit_length()
    parameters['USER_EN'] = 1
    parameters['USER_W'] = 1
    parameters['AUTO_ADDR'] = 1
    parameters['UPDATE_TID'] = 1
    parameters['S_REG_TYPE'] = 0
    parameters['M_REG_TYPE'] = 2
    parameters['ARB_ROUND_ROBIN'] = 1
    parameters['ARB_LSB_HIGH_PRIO'] = 1

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
