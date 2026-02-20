/*
 * Copyright (c) 2024 Marco Frank
 * SPDX-License-Identifier: Apache-2.0
 */

`default_nettype none

module tt_um_wta (
    input  wire [7:0] ui_in,    // Dedicated inputs
    output wire [7:0] uo_out,   // Dedicated outputs
    input  wire [7:0] uio_in,   // IOs: Input path
    output wire [7:0] uio_out,  // IOs: Output path
    output wire [7:0] uio_oe,   // IOs: Enable path (active high: 0=input, 1=output)
    input  wire       ena,      // always 1 when the design is powered, so you can ignore it
    input  wire       clk,      // clock
    input  wire       rst_n     // reset_n - low to reset
);

  // PINS --------------------------------------------------
  // ui_in[3:0]   = input spike currents (1 per neuron)
  // ui_in[7:4]   = threshold control
  // uo_out[3:0]  = spike outputs
  // uo_out[7:4]  = unused
  // uio_in[1:0]  = leak control
  // uio_in[7:2]  = unused
  // uio_out[7:0] = unused
  // uio_oe[7:0]  = unused
  // -------------------------------------------------------

  // Control Signals
  wire [1:0] leak       = uio_in[1:0];
  wire [7:0] threshold  = {4'b0000, ui_in[7:4]};

  // Internal Signals
  wire [3:0] spike;
  wire [7:0] state0, state1, state2, state3;

  // Global Winner-Take-All inhibit
  wire global_inhibit;
  assign global_inhibit = |spike;

  // List all unused inputs to prevent warnings
  wire _unused = &{ena, uio_in[7:2], state0[6:0], state1[6:0], state2[6:0], state3[6:0], 1'b0};

  // instantiate lif network
  lif_wta neuron0 (.current(ui_in[0]), .clk(clk), .reset_n(rst_n), .leak(leak), .threshold(threshold), .global_inhibit(global_inhibit), .state(state0), .spike(spike[0]));
  lif_wta neuron1 (.current(ui_in[1]), .clk(clk), .reset_n(rst_n), .leak(leak), .threshold(threshold), .global_inhibit(global_inhibit), .state(state1), .spike(spike[1]));
  lif_wta neuron2 (.current(ui_in[2]), .clk(clk), .reset_n(rst_n), .leak(leak), .threshold(threshold), .global_inhibit(global_inhibit), .state(state2), .spike(spike[2]));
  lif_wta neuron3 (.current(ui_in[3]), .clk(clk), .reset_n(rst_n), .leak(leak), .threshold(threshold), .global_inhibit(global_inhibit), .state(state3), .spike(spike[3]));

  // Spike outputs
  assign uo_out[3:0] = spike;

  // Expose MSB of each membrane state
  assign uo_out[7:4] = {state3[7], state2[7], state1[7], state0[7]};

  // No bidirectional outputs used
  assign uio_out = 8'b00000000;
  assign uio_oe  = 8'b00000000;   // 0 = input mode

endmodule
