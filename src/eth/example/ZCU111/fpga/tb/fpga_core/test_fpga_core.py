#!/usr/bin/env python
# SPDX-License-Identifier: MIT
"""

Copyright (c) 2020-2025 FPGA Ninja, LLC

Authors:
- Alex Forencich

"""

import logging
import os
import sys

import cocotb_test.simulator

import cocotb
from cocotb.log import SimLog
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, Combine

from cocotbext.eth import XgmiiFrame
from cocotbext.uart import UartSource, UartSink

try:
    from baser import BaseRSerdesSource, BaseRSerdesSink
except ImportError:
    # attempt import from current directory
    sys.path.insert(0, os.path.join(os.path.dirname(__file__)))
    try:
        from baser import BaseRSerdesSource, BaseRSerdesSink
    finally:
        del sys.path[0]


class TB:
    def __init__(self, dut, speed=1000e6):
        self.dut = dut

        self.log = SimLog("cocotb.tb")
        self.log.setLevel(logging.DEBUG)

        cocotb.start_soon(Clock(dut.clk_125mhz, 8, units="ns").start())

        self.sfp_sources = []
        self.sfp_sinks = []

        cocotb.start_soon(Clock(dut.sfp_mgt_refclk_0_p, 6.4, units="ns").start())

        for ch in dut.sfp_mac_inst.ch:
            cocotb.start_soon(Clock(ch.ch_inst.gt_inst.tx_clk, 6.4, units="ns").start())
            cocotb.start_soon(Clock(ch.ch_inst.gt_inst.rx_clk, 6.4, units="ns").start())

            self.sfp_sources.append(BaseRSerdesSource(ch.ch_inst.serdes_rx_data, ch.ch_inst.serdes_rx_hdr, ch.ch_inst.gt_inst.rx_clk, slip=ch.ch_inst.serdes_rx_bitslip, reverse=True))
            self.sfp_sinks.append(BaseRSerdesSink(ch.ch_inst.serdes_tx_data, ch.ch_inst.serdes_tx_hdr, ch.ch_inst.gt_inst.tx_clk, reverse=True))

        self.uart_source = UartSource(dut.uart_rxd, baud=3000000, bits=8, stop_bits=1)
        self.uart_sink = UartSink(dut.uart_txd, baud=3000000, bits=8, stop_bits=1)

        dut.btnu.setimmediatevalue(0)
        dut.btnl.setimmediatevalue(0)
        dut.btnd.setimmediatevalue(0)
        dut.btnr.setimmediatevalue(0)
        dut.btnc.setimmediatevalue(0)
        dut.sw.setimmediatevalue(0)
        dut.uart_rts.setimmediatevalue(0)

    async def init(self):

        self.dut.rst_125mhz.setimmediatevalue(0)

        for k in range(10):
            await RisingEdge(self.dut.clk_125mhz)

        self.dut.rst_125mhz.value = 1

        for k in range(10):
            await RisingEdge(self.dut.clk_125mhz)

        self.dut.rst_125mhz.value = 0

        for k in range(10):
            await RisingEdge(self.dut.clk_125mhz)


async def mac_test(tb, source, sink):
    tb.log.info("Test MAC")

    tb.log.info("Multiple small packets")

    count = 64

    pkts = [bytearray([(x+k) % 256 for x in range(60)]) for k in range(count)]

    for p in pkts:
        await source.send(XgmiiFrame.from_payload(p))

    for k in range(count):
        rx_frame = await sink.recv()

        tb.log.info("RX frame: %s", rx_frame)

        assert rx_frame.get_payload() == pkts[k]
        assert rx_frame.check_fcs()

    tb.log.info("Multiple large packets")

    count = 32

    pkts = [bytearray([(x+k) % 256 for x in range(1514)]) for k in range(count)]

    for p in pkts:
        await source.send(XgmiiFrame.from_payload(p))

    for k in range(count):
        rx_frame = await sink.recv()

        tb.log.info("RX frame: %s", rx_frame)

        assert rx_frame.get_payload() == pkts[k]
        assert rx_frame.check_fcs()

    tb.log.info("MAC test done")


@cocotb.test()
async def run_test(dut):

    tb = TB(dut)

    await tb.init()

    tests = []

    for k in range(len(tb.sfp_sources)):
        tb.log.info("Start SFP %d 10G MAC loopback test", k)
        tests.append(cocotb.start_soon(mac_test(tb, tb.sfp_sources[k], tb.sfp_sinks[k])))

    await Combine(*tests)

    await RisingEdge(dut.clk_125mhz)
    await RisingEdge(dut.clk_125mhz)


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


def test_fpga_core(request):
    dut = "fpga_core"
    module = os.path.splitext(os.path.basename(__file__))[0]
    toplevel = dut

    verilog_sources = [
        os.path.join(rtl_dir, f"{dut}.sv"),
        os.path.join(taxi_src_dir, "eth", "rtl", "us", "taxi_eth_mac_25g_us.f"),
        os.path.join(taxi_src_dir, "xfcp", "rtl", "taxi_xfcp_if_uart.f"),
        os.path.join(taxi_src_dir, "xfcp", "rtl", "taxi_xfcp_switch.sv"),
        os.path.join(taxi_src_dir, "xfcp", "rtl", "taxi_xfcp_mod_stats.f"),
        os.path.join(taxi_src_dir, "axis", "rtl", "taxi_axis_async_fifo.f"),
        os.path.join(taxi_src_dir, "sync", "rtl", "taxi_sync_reset.sv"),
        os.path.join(taxi_src_dir, "sync", "rtl", "taxi_sync_signal.sv"),
        os.path.join(taxi_src_dir, "io", "rtl", "taxi_debounce_switch.sv"),
    ]

    verilog_sources = process_f_files(verilog_sources)

    parameters = {}

    parameters['SIM'] = "1'b1"
    parameters['VENDOR'] = "\"XILINX\""
    parameters['FAMILY'] = "\"zynquplusRFSOC\""

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
