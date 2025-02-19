#!/usr/bin/env python
# SPDX-License-Identifier: MIT
"""

Copyright (c) 2020-2025 FPGA Ninja, LLC

Authors:
- Alex Forencich

"""

import logging
import os

import cocotb_test.simulator

import cocotb
from cocotb.log import SimLog
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, Timer, Combine

from cocotbext.eth import GmiiFrame, GmiiSource, GmiiSink, RgmiiPhy


class TB:
    def __init__(self, dut, speed=1000e6):
        self.dut = dut

        self.log = SimLog("cocotb.tb")
        self.log.setLevel(logging.DEBUG)

        cocotb.start_soon(Clock(dut.sfp_gmii_clk, 8, units="ns").start())

        self.baset_phy2 = RgmiiPhy(dut.phy2_rgmii_txd, dut.phy2_rgmii_tx_ctl, dut.phy2_rgmii_tx_clk,
            dut.phy2_rgmii_rxd, dut.phy2_rgmii_rx_ctl, dut.phy2_rgmii_rx_clk, speed=speed)

        self.baset_phy3 = RgmiiPhy(dut.phy3_rgmii_txd, dut.phy3_rgmii_tx_ctl, dut.phy3_rgmii_tx_clk,
            dut.phy3_rgmii_rxd, dut.phy3_rgmii_rx_ctl, dut.phy3_rgmii_rx_clk, speed=speed)

        self.sfp_source = GmiiSource(dut.sfp_gmii_rxd, dut.sfp_gmii_rx_er, dut.sfp_gmii_rx_dv,
            dut.sfp_gmii_clk, dut.sfp_gmii_rst, dut.sfp_gmii_clk_en)
        self.sfp_sink = GmiiSink(dut.sfp_gmii_txd, dut.sfp_gmii_tx_er, dut.sfp_gmii_tx_en,
            dut.sfp_gmii_clk, dut.sfp_gmii_rst, dut.sfp_gmii_clk_en)

        cocotb.start_soon(self._run_clk())

    async def init(self):

        self.dut.rst.setimmediatevalue(0)
        self.dut.sfp_gmii_rst.setimmediatevalue(0)

        for k in range(10):
            await RisingEdge(self.dut.clk)

        self.dut.rst.value = 1
        self.dut.sfp_gmii_rst.value = 1

        for k in range(10):
            await RisingEdge(self.dut.clk)

        self.dut.rst.value = 0
        self.dut.sfp_gmii_rst.value = 0

    async def _run_clk(self):
        t = Timer(2, 'ns')
        while True:
            self.dut.clk.value = 1
            await t
            self.dut.clk90.value = 1
            await t
            self.dut.clk.value = 0
            await t
            self.dut.clk90.value = 0
            await t


async def mac_test(tb, source, sink):
    tb.log.info("Test MAC")

    tb.log.info("Multiple small packets")

    count = 64

    pkts = [bytearray([(x+k) % 256 for x in range(60)]) for k in range(count)]

    for p in pkts:
        await source.send(GmiiFrame.from_payload(p))

    for k in range(count):
        rx_frame = await sink.recv()

        tb.log.info("RX frame: %s", rx_frame)

        assert rx_frame.get_payload() == pkts[k]
        assert rx_frame.check_fcs()
        assert rx_frame.error is None

    tb.log.info("Multiple large packets")

    count = 32

    pkts = [bytearray([(x+k) % 256 for x in range(1514)]) for k in range(count)]

    for p in pkts:
        await source.send(GmiiFrame.from_payload(p))

    for k in range(count):
        rx_frame = await sink.recv()

        tb.log.info("RX frame: %s", rx_frame)

        assert rx_frame.get_payload() == pkts[k]
        assert rx_frame.check_fcs()
        assert rx_frame.error is None

    tb.log.info("MAC test done")


@cocotb.test()
async def run_test(dut):

    tb = TB(dut)

    await tb.init()

    tb.log.info("Start BASE-T MAC loopback test on PHY2")

    phy2_test_cr = cocotb.start_soon(mac_test(tb, tb.baset_phy2.rx, tb.baset_phy2.tx))

    tb.log.info("Start BASE-T MAC loopback test on PHY3")

    phy3_test_cr = cocotb.start_soon(mac_test(tb, tb.baset_phy3.rx, tb.baset_phy3.tx))

    tb.log.info("Start SFP MAC loopback test")

    sfp_test_cr = cocotb.start_soon(mac_test(tb, tb.sfp_source, tb.sfp_sink))

    await Combine(phy2_test_cr, phy3_test_cr, sfp_test_cr)

    await RisingEdge(dut.clk)
    await RisingEdge(dut.clk)


# cocotb-test

tests_dir = os.path.abspath(os.path.dirname(__file__))
rtl_dir = os.path.abspath(os.path.join(tests_dir, '..', '..', 'rtl'))
lib_dir = os.path.abspath(os.path.join(rtl_dir, '..', 'lib'))


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


def test_fpga_core(request):
    dut = "fpga_core"
    module = os.path.splitext(os.path.basename(__file__))[0]
    toplevel = dut

    verilog_sources = [
        os.path.join(rtl_dir, f"{dut}.sv"),
        os.path.join(lib_dir, "taxi", "rtl", "eth", "taxi_eth_mac_1g_fifo.f"),
        os.path.join(lib_dir, "taxi", "rtl", "eth", "taxi_eth_mac_1g_rgmii_fifo.f"),
        os.path.join(lib_dir, "taxi", "rtl", "sync", "taxi_sync_reset.sv"),
        os.path.join(lib_dir, "taxi", "rtl", "sync", "taxi_sync_signal.sv"),
    ]

    verilog_sources = process_f_files(verilog_sources)

    parameters = {}

    parameters['SIM'] = "1'b1"
    parameters['VENDOR'] = "\"XILINX\""
    parameters['FAMILY'] = "\"zynquplus\""
    parameters['USE_CLK90'] = "1'b1"

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
