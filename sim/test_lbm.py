import cocotb
import os
import random
import sys
from math import log
import logging
from pathlib import Path
from cocotb.clock import Clock
from cocotb.triggers import Timer, ClockCycles, RisingEdge, FallingEdge, ReadOnly, with_timeout
from cocotb.utils import get_sim_time as gst
from cocotb.runner import get_runner
from cocotb.types import LogicArray

# import

# async def send_new_divide(dut, dividend, divisor):
#     dut.dividend_in = dividend
#     dut.divisor_in = divisor
#     await ClockCycles(dut.clk_in, 1)


@cocotb.test()
async def test_a(dut):
    """cocotb test for lbm"""
    dut._log.info("Starting...")
    cocotb.start_soon(Clock(dut.clk_in, 10, units="ns").start())
    dut.sw_in.value = 3
    dut.rst_in.value = 1
    dut.btn_in.value = 0
    await ClockCycles(dut.clk_in, 10)  # setup
    dut.rst_in.value = 0
    await ClockCycles(dut.clk_in, 10)  # start setup
    dut.state.value = 3
    await ClockCycles(dut.clk_in, 10)  # go to waiting
    # await ClockCycles(dut.clk_in, 40000)  # setup
    dut.btn_in.value = 1
    for i in range(1000):
        dut.bram_data_in.value = 0xFF00000000000000AA
        await ClockCycles(dut.clk_in, 1)


def lbm_runner():
    """Simulate the counter using the Python runner."""
    hdl_toplevel_lang = os.getenv("HDL_TOPLEVEL_LANG", "verilog")
    sim = os.getenv("SIM", "icarus")
    proj_path = Path(__file__).resolve().parent.parent
    sys.path.append(str(proj_path / "sim" / "model"))
    sources = [proj_path / "hdl" / "lbm.sv"]
    sources += [proj_path / "hdl" / "collision.sv"]
    sources += [proj_path / "hdl" / "divider.sv"]
    sources += [proj_path / "hdl" / "streaming.sv"]
    sources += [proj_path / "hdl" / "principal_to_all.sv"]
    sources += [proj_path / "hdl" / "addr_calc.sv"]
    sources += [proj_path / "hdl" / "addr_history.sv"]
    sources += [proj_path / "hdl" / "setup.sv"]
    sources += [proj_path / "hdl" / "line_barrier.sv"]
    sources += [proj_path / "hdl" / "circle_barrier.sv"]
    sources += [proj_path / "hdl" / "pipeline.sv"]
    build_test_args = ["-Wall"]
    parameters = {"HPIXELS": 10, "VPIXELS": 10}
    sys.path.append(str(proj_path / "sim"))
    runner = get_runner(sim)
    runner.build(
        sources=sources,
        hdl_toplevel="lbm",
        always=True,
        build_args=build_test_args,
        parameters=parameters,
        timescale=('1ns', '1ps'),
        waves=True,
    )
    run_test_args = []
    runner.test(hdl_toplevel="lbm", test_module="test_lbm", test_args=run_test_args, waves=True)


if __name__ == "__main__":
    lbm_runner()
