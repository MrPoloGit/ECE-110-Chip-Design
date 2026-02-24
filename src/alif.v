`default_nettype none

module alif #(
    parameter [7:0] BASE_THRESHOLD = 8'd120,
    parameter [7:0] ADAPT_STEP     = 8'd20,
    parameter [7:0] RESET_VALUE    = 8'd0
)(
    input  wire [7:0] current,
    input  wire       clk,
    input  wire       reset_n,
    output reg  [7:0] state,
    output wire       spike
);

    wire [7:0] next_state;
    wire [7:0] next_adapt;
    reg  [7:0] adapt;       // adaptation variable
    wire [7:0] threshold;   // dynamic threshold

    // Sequential logic
    always @(posedge clk) begin
        if (!reset_n) begin
            state <= 0;
            adapt <= 0;
        end else begin
            if (spike) begin
                state <= RESET_VALUE;
                adapt <= next_adapt + ADAPT_STEP; // increase threshold
            end else begin
                state <= next_state;
                adapt <= next_adapt;
            end
        end
    end

    // Adaptation decay
    assign next_adapt = adapt - (adapt >> 3);  // slow decay (~12%)

    // Next state logic
    assign next_state = current + (state >> 1);

    // Threshold = base + adapt
    assign threshold = BASE_THRESHOLD + adapt;

    // Spike Condition
    assign spike = (state >= threshold);

endmodule
