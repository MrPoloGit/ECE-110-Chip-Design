# SPDX-FileCopyrightText: © 2024 Tiny Tapeout
# SPDX-License-Identifier: Apache-2.0

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles, RisingEdge

async def wait_for_spike(dut, max_cycles=300):
    for i in range(max_cycles):
        await RisingEdge(dut.clk)
        if int(dut.uio_out.value) & 0x01:
            return i
    return None


@cocotb.test()
async def test_project(dut):

    dut._log.info("Starting ALIF neuron test")

    clock = Clock(dut.clk, 10, units="ns")
    cocotb.start_soon(clock.start())

    # Test 0: Reset
    dut._log.info("Test 0: Reset")
    dut.rst_n.value = 0
    dut.ui_in.value = 0
    dut.uio_in.value = 0
    dut.ena.value = 1

    await ClockCycles(dut.clk, 10)
    dut.rst_n.value = 1
    await RisingEdge(dut.clk)
    await RisingEdge(dut.clk)

    assert int(dut.uo_out.value) == 0, "State not zero after reset"
    dut._log.info("Reset PASS")

    # TEST 1: No spontaneous spike
    dut._log.info("Test 1: No input, no spike")
    dut.ui_in.value = 0

    for i in range(50):
        await RisingEdge(dut.clk)
        assert (int(dut.uio_out.value) & 0x01) == 0, \
            f"Spontaneous spike at cycle {i}"

    dut._log.info("PASS")

    # TEST 2: Constant input causes spike
    dut._log.info("Test 2: Spike with constant input")

    dut.ui_in.value = 80  # strong enough current

    spike_cycle = await wait_for_spike(dut, 200)
    assert spike_cycle is not None, "Neuron did not spike under strong input"

    dut._log.info(f"Spike detected at cycle {spike_cycle}")

    # TEST 3: Reset behavior
    dut._log.info("Test 3: Reset Behavior")
    await RisingEdge(dut.clk)

    state_after = int(dut.uo_out.value)
    dut._log.info(f"State immediately after reset: {state_after}")
    assert state_after == 0, "State did not reset properly"

    dut._log.info("Reset PASS")

    # TEST 4: Adaptation limits firing rate
    dut._log.info("Test 4: Adaptation behavior")

    spike_count = 0
    window = 200

    for i in range(window):
        await RisingEdge(dut.clk)
        if int(dut.uio_out.value) & 0x01:
            spike_count += 1

    dut._log.info(f"Spikes in {window} cycles: {spike_count}")

    assert spike_count > 0, "No spikes observed"
    assert spike_count < window // 4, \
        "Firing rate too high — adaptation may be broken"

    dut._log.info("Adaptation PASS")

    # TEST 5: Nothing after removing input
    dut._log.info("Test 5: Nothing after input removal")

    dut.ui_in.value = 0
    await ClockCycles(dut.clk, 20)

    silent_spikes = 0
    for i in range(80):
        await RisingEdge(dut.clk)
        if int(dut.uio_out.value) & 0x01:
            silent_spikes += 1

    dut._log.info(f"Spikes after removing input: {silent_spikes}")
    assert silent_spikes == 0, "Neuron kept spiking after input removed"

    dut._log.info("="*60)
    dut._log.info("All ALIF tests passed!")
    dut._log.info("="*60)
