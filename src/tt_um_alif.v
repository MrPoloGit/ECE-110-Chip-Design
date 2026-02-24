/*
 * Copyright (c) 2024 Marco Frank
 * SPDX-License-Identifier: Apache-2.0
 */

`default_nettype none

module tt_um_alif (
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
  // ui_in[7:0]   = input current
  // uo_out[7:0]  = state output
  // uio_in[7:0]  = unused
  // uio_out[0]   = spike output (high for one cycle when V >= 30)
  // uio_out[7:1] = driven 0
  // uio_oe[7:0]  = 1
  // -------------------------------------------------------

  assign uio_out[7:1] = 7'b0;
  assign uio_oe       = 1;

  wire _unused = &{ena, uio_in, 1'b0};

  localparam BASE_THRESHOLD = 8'd120;
  localparam ADAPT_STEP = 8'd20;
  localparam RESET_VALUE = 8'd0;

  alif #(
      .BASE_THRESHOLD(BASE_THRESHOLD),
      .ADAPT_STEP    (ADAPT_STEP),
      .RESET_VALUE   (RESET_VALUE)
  ) neuron0 (
      .current (ui_in),
      .clk     (clk),
      .reset_n (rst_n),
      .state   (uo_out),
      .spike   (uio_out[0])
  );

endmodule