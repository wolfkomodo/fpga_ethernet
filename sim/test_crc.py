import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, Timer
import logging
import os
import sys
from cocotb.runner import get_runner
from pathlib import Path
import zlib
import struct

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, Timer
import zlib
import struct

@cocotb.test()
async def test_crc32_single_byte(dut):
    """Test CRC32 with single bytes"""
    
    # Create clock
    clock = Clock(dut.clk, 10, units="ns")
    cocotb.start_soon(clock.start())
    
    # Initialize and reset
    dut.rst.value = 0
    dut.valid.value = 0
    dut.data.value = 0
    
    # Wait a few cycles for stability
    for _ in range(5):
        await RisingEdge(dut.clk)
    
    # Assert reset for multiple cycles
    dut.rst.value = 1
    for _ in range(5):
        await RisingEdge(dut.clk)
    dut.rst.value = 0
    
    # Wait a few more cycles before starting
    for _ in range(5):
        await RisingEdge(dut.clk)
    
    # Test data
    test_data = b"Hello, World!"
    expected_crc = zlib.crc32(test_data)
    
    # Process byte by byte
    for byte in test_data:
        dut.data.value = byte
        dut.valid.value = 1
        await RisingEdge(dut.clk)
        
    # Two extra cycles to flush pipeline    
    dut.valid.value = 0
    await RisingEdge(dut.clk)
    await RisingEdge(dut.clk)
    
    # Get results and compare
    actual_crc = int(dut.crc.value)
    
    if actual_crc != expected_crc:
        dut._log.error(f"CRC mismatch! Got {hex(actual_crc)}, expected {hex(expected_crc)}")
    else:
        dut._log.info(f"CRC match! {hex(actual_crc)}")

@cocotb.test()
async def test_crc32_random_data(dut):
    """Test CRC32 with random data"""
    import random
    
    # Create clock
    clock = Clock(dut.clk, 10, units="ns")
    cocotb.start_soon(clock.start())
    
    # Run multiple random test cases
    for test in range(5):
        # Initialize and reset
        dut.rst.value = 0
        dut.valid.value = 0
        dut.data.value = 0
        
        # Wait a few cycles for stability
        for _ in range(5):
            await RisingEdge(dut.clk)
        
        # Assert reset for multiple cycles
        dut.rst.value = 1
        for _ in range(5):
            await RisingEdge(dut.clk)
        dut.rst.value = 0
        
        # Wait a few more cycles before starting
        for _ in range(5):
            await RisingEdge(dut.clk)
        
        # Generate random data
        length = random.randint(1, 50)
        test_data = bytes([random.randint(0, 255) for _ in range(length)])
        expected_crc = zlib.crc32(test_data)
        
        # Process byte by byte
        for byte in test_data:
            dut.data.value = byte
            dut.valid.value = 1
            await RisingEdge(dut.clk)
            
        # Two extra cycles to flush pipeline    
        dut.valid.value = 0
        await RisingEdge(dut.clk)
        await RisingEdge(dut.clk)
        
        # Get results and compare
        actual_crc = int(dut.crc.value)
        
        if actual_crc != expected_crc:
            dut._log.error(f"Test {test}: CRC mismatch! Got {hex(actual_crc)}, expected {hex(expected_crc)}")
            dut._log.info(f"Test {test}: Input data: {test_data.hex()}")
        else:
            dut._log.info(f"Test {test}: CRC match! {hex(actual_crc)}")

def is_runner():
    """Ethernet Testbench Runner."""
    hdl_toplevel_lang = os.getenv("HDL_TOPLEVEL_LANG", "verilog")
    sim = os.getenv("SIM", "icarus")
    proj_path = Path(__file__).resolve().parent.parent
    sys.path.append(str(proj_path / "sim" / "model"))
    sources = [proj_path / "hdl" / "crc32.sv"]
    sources += [proj_path / "hdl" / "endian_swap.sv"]
    build_test_args = ["-Wall"]
    parameters = {}
    sys.path.append(str(proj_path / "sim"))
    runner = get_runner(sim)
    runner.build(
        sources=sources,
        hdl_toplevel="crc32",
        always=True,
        build_args=build_test_args,
        parameters=parameters,
        timescale = ('1ns','1ps'),
        waves=True
    )
    run_test_args = []
    runner.test(
        hdl_toplevel="crc32",
        test_module="test_crc",
        test_args=run_test_args,
        waves=True
    )

if __name__ == "__main__":
    is_runner()