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
import sys

import cocotb_test.simulator

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge
from cocotb.regression import TestFactory

from cocotbext.eth import XgmiiSource, XgmiiFrame

try:
    from baser import BaseRSerdesSink
except ImportError:
    # attempt import from current directory
    sys.path.insert(0, os.path.join(os.path.dirname(__file__)))
    try:
        from baser import BaseRSerdesSink
    finally:
        del sys.path[0]


class TB:
    def __init__(self, dut):
        self.dut = dut

        self.log = logging.getLogger("cocotb.tb")
        self.log.setLevel(logging.DEBUG)

        cocotb.start_soon(Clock(dut.clk, 6.4, units="ns").start())

        self.source = XgmiiSource(dut.xgmii_txd, dut.xgmii_txc, dut.clk, dut.rst)
        self.sink = BaseRSerdesSink(dut.encoded_tx_data, dut.encoded_tx_hdr, dut.clk, scramble=False)

        dut.xgmii_tx_valid.setimmediatevalue(1)
        dut.tx_gbx_sync_in.setimmediatevalue(0)

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


async def run_test(dut, payload_lengths=None, payload_data=None, ifg=12, enable_dic=True,
        force_offset_start=False):

    tb = TB(dut)

    tb.source.ifg = ifg
    tb.source.enable_dic = enable_dic
    tb.source.force_offset_start = force_offset_start

    await tb.reset()

    test_frames = [payload_data(x) for x in payload_lengths()]

    for test_data in test_frames:
        test_frame = XgmiiFrame.from_payload(test_data)
        await tb.source.send(test_frame)

    for test_data in test_frames:
        rx_frame = await tb.sink.recv()

        assert rx_frame.get_payload() == test_data
        assert rx_frame.check_fcs()

    assert tb.sink.empty()

    await RisingEdge(dut.clk)
    await RisingEdge(dut.clk)


async def run_test_alignment(dut, payload_data=None, ifg=12, enable_dic=True,
        force_offset_start=False):

    tb = TB(dut)

    byte_lanes = tb.source.byte_lanes

    tb.source.ifg = ifg
    tb.source.enable_dic = enable_dic
    tb.source.force_offset_start = force_offset_start

    for length in range(60, 92):

        await tb.reset()

        test_frames = [payload_data(length) for k in range(10)]
        start_lane = []

        for test_data in test_frames:
            test_frame = XgmiiFrame.from_payload(test_data)
            await tb.source.send(test_frame)

        for test_data in test_frames:
            rx_frame = await tb.sink.recv()

            assert rx_frame.get_payload() == test_data
            assert rx_frame.check_fcs()
            assert rx_frame.ctrl is None

            start_lane.append(rx_frame.start_lane)

        tb.log.info("length: %d", length)
        tb.log.info("start_lane: %s", start_lane)

        start_lane_ref = []

        # compute expected starting lanes
        lane = 0
        deficit_idle_count = 0

        for test_data in test_frames:
            if ifg == 0:
                lane = 0
            if force_offset_start and byte_lanes > 4:
                lane = 4

            start_lane_ref.append(lane)
            lane = (lane + len(test_data)+4+ifg) % byte_lanes

            if enable_dic:
                offset = lane % 4
                if deficit_idle_count+offset >= 4:
                    offset += 4
                lane = (lane - offset) % byte_lanes
                deficit_idle_count = (deficit_idle_count + offset) % 4
            else:
                offset = lane % 4
                if offset > 0:
                    offset += 4
                lane = (lane - offset) % byte_lanes

        tb.log.info("start_lane_ref: %s", start_lane_ref)

        assert start_lane_ref == start_lane

        await RisingEdge(dut.clk)

    assert tb.sink.empty()

    await RisingEdge(dut.clk)
    await RisingEdge(dut.clk)


def size_list():
    return list(range(60, 128)) + [512, 1514, 9214] + [60]*10


def incrementing_payload(length):
    return bytearray(itertools.islice(itertools.cycle(range(256)), length))


def cycle_en():
    return itertools.cycle([0, 0, 0, 1])


if cocotb.SIM_NAME:

    factory = TestFactory(run_test)
    factory.add_option("payload_lengths", [size_list])
    factory.add_option("payload_data", [incrementing_payload])
    factory.add_option("ifg", [12])
    factory.add_option("enable_dic", [True, False])
    factory.add_option("force_offset_start", [False, True])
    factory.generate_tests()

    factory = TestFactory(run_test_alignment)
    factory.add_option("payload_data", [incrementing_payload])
    factory.add_option("ifg", [12])
    factory.add_option("enable_dic", [True, False])
    factory.add_option("force_offset_start", [False, True])
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


def test_taxi_xgmii_baser_enc_64(request):
    dut = "taxi_xgmii_baser_enc_64"
    module = os.path.splitext(os.path.basename(__file__))[0]
    toplevel = dut

    verilog_sources = [
        os.path.join(rtl_dir, f"{dut}.sv"),
    ]

    verilog_sources = process_f_files(verilog_sources)

    parameters = {}

    parameters['DATA_W'] = 64
    parameters['CTRL_W'] = parameters['DATA_W'] // 8
    parameters['HDR_W'] = 2
    parameters['GBX_IF_EN'] = 0

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
