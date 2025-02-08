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

import cocotb_test.simulator

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge
from cocotb.utils import get_time_from_sim_steps
from cocotb.regression import TestFactory

from cocotbext.eth import GmiiSink, PtpClockSimTime
from cocotbext.axi import AxiStreamBus, AxiStreamSource, AxiStreamSink, AxiStreamFrame


class TB:
    def __init__(self, dut):
        self.dut = dut

        self.log = logging.getLogger("cocotb.tb")
        self.log.setLevel(logging.DEBUG)

        self._enable_generator = None
        self._enable_cr = None

        cocotb.start_soon(Clock(dut.clk, 8, units="ns").start())

        self.source = AxiStreamSource(AxiStreamBus.from_entity(dut.s_axis_tx), dut.clk, dut.rst)
        self.sink = GmiiSink(dut.gmii_txd, dut.gmii_tx_er, dut.gmii_tx_en,
            dut.clk, dut.rst, dut.clk_enable, dut.mii_select)

        self.ptp_clock = PtpClockSimTime(ts_tod=dut.ptp_ts, clock=dut.clk)
        self.tx_cpl_sink = AxiStreamSink(AxiStreamBus.from_entity(dut.m_axis_tx_cpl), dut.clk, dut.rst)

        dut.clk_enable.setimmediatevalue(1)
        dut.mii_select.setimmediatevalue(0)
        dut.cfg_ifg.setimmediatevalue(0)
        dut.cfg_tx_enable.setimmediatevalue(0)

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

    def set_enable_generator(self, generator=None):
        if self._enable_cr is not None:
            self._enable_cr.kill()
            self._enable_cr = None

        self._enable_generator = generator

        if self._enable_generator is not None:
            self._enable_cr = cocotb.start_soon(self._run_enable())

    def clear_enable_generator(self):
        self.set_enable_generator(None)

    async def _run_enable(self):
        for val in self._enable_generator:
            self.dut.clk_enable.value = val
            await RisingEdge(self.dut.clk)


async def run_test(dut, payload_lengths=None, payload_data=None, ifg=12, enable_gen=None, mii_sel=False):

    tb = TB(dut)

    tb.dut.cfg_ifg.value = ifg
    tb.dut.cfg_tx_enable.value = 1
    tb.dut.mii_select.value = mii_sel

    if enable_gen is not None:
        tb.set_enable_generator(enable_gen())

    await tb.reset()

    test_frames = [payload_data(x) for x in payload_lengths()]

    for test_data in test_frames:
        await tb.source.send(AxiStreamFrame(test_data, tid=0, tuser=2))

    for test_data in test_frames:
        rx_frame = await tb.sink.recv()
        tx_cpl = await tb.tx_cpl_sink.recv()

        ptp_ts_ns = int(tx_cpl.tdata[0]) / 2**16

        rx_frame_sfd_ns = get_time_from_sim_steps(rx_frame.sim_time_sfd, "ns")

        tb.log.info("TX frame PTP TS: %f ns", ptp_ts_ns)
        tb.log.info("RX frame SFD sim time: %f ns", rx_frame_sfd_ns)
        tb.log.info("Difference: %f ns", abs(rx_frame_sfd_ns - ptp_ts_ns))

        assert rx_frame.get_payload() == test_data
        assert rx_frame.check_fcs()
        assert rx_frame.error is None
        assert abs(rx_frame_sfd_ns - ptp_ts_ns - (32 if enable_gen else 8)) < 0.01

    assert tb.sink.empty()

    await RisingEdge(dut.clk)
    await RisingEdge(dut.clk)


async def run_test_underrun(dut, ifg=12, enable_gen=None, mii_sel=False):

    tb = TB(dut)

    tb.dut.cfg_ifg.value = ifg
    tb.dut.cfg_tx_enable.value = 1
    tb.dut.mii_select.value = mii_sel

    if enable_gen is not None:
        tb.set_enable_generator(enable_gen())

    await tb.reset()

    test_data = bytes(x for x in range(60))

    for k in range(3):
        test_frame = AxiStreamFrame(test_data)
        await tb.source.send(test_frame)

    for k in range(200 if mii_sel else 100):
        while True:
            await RisingEdge(dut.clk)
            if dut.clk_enable.value.integer:
                break

    tb.source.pause = True

    for k in range(10):
        while True:
            await RisingEdge(dut.clk)
            if dut.clk_enable.value.integer:
                break

    tb.source.pause = False

    for k in range(3):
        rx_frame = await tb.sink.recv()

        if k == 1:
            assert rx_frame.error[-1] == 1
        else:
            assert rx_frame.get_payload() == test_data
            assert rx_frame.check_fcs()
            assert rx_frame.error is None

    assert tb.sink.empty()

    await RisingEdge(dut.clk)
    await RisingEdge(dut.clk)


async def run_test_error(dut, ifg=12, enable_gen=None, mii_sel=False):

    tb = TB(dut)

    tb.dut.cfg_ifg.value = ifg
    tb.dut.cfg_tx_enable.value = 1
    tb.dut.mii_select.value = mii_sel

    if enable_gen is not None:
        tb.set_enable_generator(enable_gen())

    await tb.reset()

    test_data = bytes(x for x in range(60))

    for k in range(3):
        test_frame = AxiStreamFrame(test_data)
        if k == 1:
            test_frame.tuser = 1
        await tb.source.send(test_frame)

    for k in range(3):
        rx_frame = await tb.sink.recv()

        if k == 1:
            assert rx_frame.error[-1] == 1
        else:
            assert rx_frame.get_payload() == test_data
            assert rx_frame.check_fcs()
            assert rx_frame.error is None

    assert tb.sink.empty()

    await RisingEdge(dut.clk)
    await RisingEdge(dut.clk)


def size_list():
    return list(range(60, 128)) + [512, 1514] + [60]*10


def incrementing_payload(length):
    return bytearray(itertools.islice(itertools.cycle(range(256)), length))


def cycle_en():
    return itertools.cycle([0, 0, 0, 1])


if cocotb.SIM_NAME:

    factory = TestFactory(run_test)
    factory.add_option("payload_lengths", [size_list])
    factory.add_option("payload_data", [incrementing_payload])
    factory.add_option("ifg", [12])
    factory.add_option("enable_gen", [None, cycle_en])
    factory.add_option("mii_sel", [False, True])
    factory.generate_tests()

    for test in [run_test_underrun, run_test_error]:

        factory = TestFactory(test)
        factory.add_option("ifg", [12])
        factory.add_option("enable_gen", [None, cycle_en])
        factory.add_option("mii_sel", [False, True])
        factory.generate_tests()


# cocotb-test

tests_dir = os.path.abspath(os.path.dirname(__file__))
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


def test_taxi_axis_gmii_tx(request):
    dut = "taxi_axis_gmii_tx"
    module = os.path.splitext(os.path.basename(__file__))[0]
    toplevel = module

    verilog_sources = [
        os.path.join(tests_dir, f"{toplevel}.sv"),
        os.path.join(rtl_dir, "eth", f"{dut}.sv"),
        os.path.join(rtl_dir, "lfsr", "taxi_lfsr.sv"),
        os.path.join(rtl_dir, "axis", "taxi_axis_if.sv"),
    ]

    verilog_sources = process_f_files(verilog_sources)

    parameters = {}

    parameters['DATA_W'] = 8
    parameters['PADDING_EN'] = 1
    parameters['MIN_FRAME_LEN'] = 64
    parameters['PTP_TS_EN'] = 1
    parameters['PTP_TS_W'] = 96
    parameters['TX_TAG_W'] = 16
    parameters['TX_CPL_CTRL_IN_TUSER'] = 1

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
