import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, Timer
import logging
import os
import sys
from cocotb.runner import get_runner
from pathlib import Path

@cocotb.test()
async def test_ethernet_transmission(dut):
    """
    Testbench for Ethernet top-level module transmission
    Capture and log signals during the frame transmission
    Captures transmitted data when eth_txen is high
    """
    # Initialize clock
    clock = Clock(dut.clk_100mhz, 10, units='ns')
    cocotb.start_soon(clock.start())

    # Initialize variables
    dut.eth_intn.value = 1  # Interrupt not active
    transmitted_data = []  # List to store transmitted bytes

    await Timer(20, units='ms')

    # Monitor for 20ms
    end_time = 20_000  # 20ms in ns
    current_time = 0
    # print('hi')
    
    while current_time < end_time:
        await RisingEdge(dut.clk_100mhz)
        
        # Check if transmission is enabled
        if dut.eth_txen.value == 1:
            # Read and store the transmitted data
            current_byte = dut.eth_txd.value.integer
            transmitted_data.append(current_byte)
            # print('hi')
            logging.info(f"Time {current_time}ns: Captured byte: 0x{current_byte:02x}")
            if len(transmitted_data) > 200:
                break
        
        current_time += 10  # Increment by clock period

    # Convert captured bytes to string representation
    hex_string = ' '.join([f"{byte:02x}" for byte in transmitted_data])
    
    logging.info(f"\nTransmission Complete!")
    logging.info(f"Captured {len(transmitted_data)} bytes")
    logging.info(f"Transmitted data (hex): {hex_string}")
    print(hex_string)
    
    # Log final signal states
    logging.info(f"\nFinal Signal States:")
    logging.info(f"  eth_txen (Transmit Enable): {dut.eth_txen.value}")
    logging.info(f"  eth_txd (Transmit Data): {dut.eth_txd.value}")
    logging.info(f"  eth_refclk (Reference Clock): {dut.eth_refclk.value}")

    # assert dut.eth_rstn.value == 1, "Ethernet PHY should be out of reset"

def is_runner():
    """Ethernet Testbench Runner."""
    hdl_toplevel_lang = os.getenv("HDL_TOPLEVEL_LANG", "verilog")
    sim = os.getenv("SIM", "icarus")
    proj_path = Path(__file__).resolve().parent.parent
    sys.path.append(str(proj_path / "sim" / "model"))
    sources = [proj_path / "hdl" / "top_level.sv"]
    sources += [proj_path / "hdl" / "tx_scheduler.sv"]
    sources += [proj_path / "hdl" / "write_scheduler.sv"]
    sources += [proj_path / "hdl" / "crc32.sv"]
    sources += [proj_path / "hdl" / "endian_swap.sv"]
    # sources += [proj_path / "hdl" / "clk_wiz_2_clk_wiz.v"]
    build_test_args = ["-Wall"]
    parameters = {}
    sys.path.append(str(proj_path / "sim"))
    runner = get_runner(sim)
    runner.build(
        sources=sources,
        hdl_toplevel="top_level",
        always=True,
        build_args=build_test_args,
        parameters=parameters,
        timescale = ('1ns','1ps'),
        waves=True
    )
    run_test_args = []
    runner.test(
        hdl_toplevel="top_level",
        test_module="test_top_level",
        test_args=run_test_args,
        waves=True
    )

if __name__ == "__main__":
    is_runner()