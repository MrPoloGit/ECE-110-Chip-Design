# SPDX-FileCopyrightText: © 2024 Tiny Tapeout
# SPDX-License-Identifier: Apache-2.0

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles

def set_threshold(dut, value):
    # threshold is ui_in[7:4]
    current_inputs = dut.ui_in.value.integer & 0x0F
    dut.ui_in.value = (value << 4) | current_inputs

def set_currents(dut, value):
    # currents are ui_in[3:0]
    threshold_bits = dut.ui_in.value.integer & 0xF0
    dut.ui_in.value = threshold_bits | (value & 0x0F)

def set_leak(dut, value):
    # leak is uio_in[1:0]
    dut.uio_in.value = value & 0x03

@cocotb.test()
async def test_project(dut):
    dut._log.info("Start tests")

    clock = Clock(dut.clk, 1, units="ns")
    cocotb.start_soon(clock.start())

    # Reset test -------------------------------------------------------
    dut._log.info("Test 0: Reset")
    dut.rst_n.value = 0
    dut.ui_in.value = 0
    dut.uio_in.value = 0
    await ClockCycles(dut.clk, 10)
    dut.rst_n.value = 1
    await ClockCycles(dut.clk, 5)
    assert dut.uo_out.value.integer == 0, "Output not zero after reset"

    # Test 1: Single neuron integration and spike ----------------------
    dut._log.info("Test 1: Single neuron spike")

    set_threshold(dut, 4)     # threshold = 4
    set_leak(dut, 0)          # no leak
    set_currents(dut, 0b0001) # neuron0 active

    spike_seen = False
    for i in range(10):
        await ClockCycles(dut.clk, 1)
        spikes = dut.uo_out.value.integer & 0x0F
        if spikes & 0b0001:
            spike_seen = True
            break

    assert spike_seen, "Neuron 0 did not spike as expected"

    # Test 2: Refractory behavior --------------------------------------
    dut._log.info("Test 2: Refractory period")

    spike_count = 0
    for i in range(20):
        await ClockCycles(dut.clk, 1)
        spikes = dut.uo_out.value.integer & 0x0F
        if spikes & 0b0001:
            spike_count += 1

    # Should not spike continuously due to refractory
    assert spike_count <= 2, "Global inhibit not working"

    # Test 3: Winner-Take-All ------------------------------------------
    dut._log.info("Test 3: Winner-Take-All competition")

    # Reset
    dut.rst_n.value = 0
    await ClockCycles(dut.clk, 5)
    dut.rst_n.value = 1
    await ClockCycles(dut.clk, 5)
    set_threshold(dut, 3)
    set_leak(dut, 0)

    # Activate neuron0 and neuron1
    set_currents(dut, 0b0011)
    await ClockCycles(dut.clk, 10)
    spikes = dut.uo_out.value.integer & 0x0F

    # Only one neuron should spike at a time
    assert spikes in [0b0001, 0b0010, 0], "WTA violation: multiple spikes detected"

    # Test 4: Leak behavior --------------------------------------------
    dut._log.info("Test 4: Leak decay")
    dut.rst_n.value = 0
    await ClockCycles(dut.clk, 5)
    dut.rst_n.value = 1
    await ClockCycles(dut.clk, 5)
    set_threshold(dut, 15)
    set_leak(dut, 2)  # strong leak
    set_currents(dut, 0b0001)
    await ClockCycles(dut.clk, 5)

    # remove current
    set_currents(dut, 0)
    prev_state = dut.uo_out.value.integer >> 4
    await ClockCycles(dut.clk, 5)
    new_state = dut.uo_out.value.integer >> 4
    assert new_state <= prev_state, "Leak not reducing membrane potential"

    dut._log.info("Finished tests")
