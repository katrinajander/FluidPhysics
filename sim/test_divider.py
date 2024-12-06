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
from cocotb.types import LogicArray
# import 

async def send_new_divide(dut, dividend, divisor):
    dut.dividend_in = dividend
    dut.divisor_in = divisor
    await ClockCycles(dut.clk_in, 1)

@cocotb.test()
async def test_a(dut):
    """cocotb test for divider"""
    dut._log.info("Starting...")
    cocotb.start_soon(Clock(dut.clk_in, 10, units="ns").start())
    dut.rst_in.value = 1
    await ClockCycles(dut.clk_in, 5)
    dut.rst_in.value = 0
    dut.data_valid_in = 1
    await send_new_divide(dut, LogicArray('00000000000000000000000001100111'), LogicArray('00000000000000000000000000001100'))
    dut.data_valid_in = 1
    await send_new_divide(dut, -14, 3)
    dut.data_valid_in = 1
    await send_new_divide(dut, -14, -3)
    dut.data_valid_in = 1
    await send_new_divide(dut, 18, -3)
    dut.data_valid_in = 1
    await send_new_divide(dut, 18, 3)
    dut.data_valid_in = 1
    await send_new_divide(dut, 15, -3)
    await ClockCycles(dut.clk_in, 1)
    dut.data_valid_in = 0
    await ClockCycles(dut.clk_in, 100)
    # await send_pixel_row(dut, 1, 8, 23, 23, 23)

    await ClockCycles(dut.clk_in, 200)

def divider_runner():
    """Simulate the counter using the Python runner."""
    hdl_toplevel_lang = os.getenv("HDL_TOPLEVEL_LANG", "verilog")
    sim = os.getenv("SIM", "icarus")
    proj_path = Path(__file__).resolve().parent.parent
    sys.path.append(str(proj_path / "sim" / "model"))
    sources = [proj_path / "hdl" / "divider.sv"]
    build_test_args = ["-Wall"]
    parameters = {} #ADD MORE HERE
    sys.path.append(str(proj_path / "sim"))
    runner = get_runner(sim)
    runner.build(
        sources=sources,
        hdl_toplevel="divider",
        always=True,
        build_args=build_test_args,
        parameters=parameters,
        timescale = ('1ns','1ps'),
        waves=True
    )
    run_test_args = []
    runner.test(
        hdl_toplevel="divider",
        test_module="test_divider",
        test_args=run_test_args,
        waves=True
    )

if __name__ == "__main__":
    divider_runner()