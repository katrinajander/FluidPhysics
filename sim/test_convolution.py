import cocotb
import os
import random
import sys
from math import log
import logging
from pathlib import Path
from cocotb.clock import Clock
from cocotb.triggers import Timer, ClockCycles, RisingEdge, FallingEdge, ReadOnly,with_timeout
from cocotb.utils import get_sim_time as gst
from cocotb.runner import get_runner
# import 

async def send_pixel_row(dut, hcount, vcount, pixel_value_r, pixel_value_g, pixel_value_b):
    dut.hcount_in.value = hcount
    dut.vcount_in.value = vcount
    # dut.data_in = pixel_value_r + pixel_value_g + pixel_value_b
    dut.data_in.value = (0x1F << 32) | (0x1F << 16) | (0x1F << 0)
    dut.data_valid_in.value = 1
    await ClockCycles(dut.clk_in, 1)
    # dut.data_valid_in = 0

async def horiz_blank(dut, hcount_start, num_cols):
    dut.data_valid_in = 0
    for i in range(num_cols):
        dut.hcount_in = hcount_start + i
        await ClockCycles(dut.clk_in, 1)

@cocotb.test()
async def test_a(dut):
    """cocotb test for video signal generation"""
    dut._log.info("Starting...")
    cocotb.start_soon(Clock(dut.clk_in, 10, units="ns").start())
    dut.rst_in.value = 1
    await ClockCycles(dut.clk_in, 5)
    dut.rst_in.value = 0
    dut.data_valid_in = 1
    for i in range(10):
        await send_pixel_row(dut, i, 1, 31, 63, 31)
    # await send_pixel_row(dut, 1, 8, 23, 23, 23)

    await ClockCycles(dut.clk_in, 200)

def convolution_runner():
    """Simulate the counter using the Python runner."""
    hdl_toplevel_lang = os.getenv("HDL_TOPLEVEL_LANG", "verilog")
    sim = os.getenv("SIM", "icarus")
    proj_path = Path(__file__).resolve().parent.parent
    sys.path.append(str(proj_path / "sim" / "model"))
    sources = [proj_path / "hdl" / "convolution.sv"]
    sources += [proj_path / "hdl" / "kernels.sv"]
    build_test_args = ["-Wall"]
    parameters = {'K_SELECT' : 5} #identity = 0
    sys.path.append(str(proj_path / "sim"))
    runner = get_runner(sim)
    runner.build(
        sources=sources,
        hdl_toplevel="convolution",
        always=True,
        build_args=build_test_args,
        parameters=parameters,
        timescale = ('1ns','1ps'),
        waves=True
    )
    run_test_args = []
    runner.test(
        hdl_toplevel="convolution",
        test_module="test_convolution",
        test_args=run_test_args,
        waves=True
    )

if __name__ == "__main__":
    convolution_runner()