
`default_nettype none

module lif_wta (
    input wire       current,
    input wire       clk,
    input wire       reset_n,
    input wire [1:0] leak,
    input wire [7:0] threshold,
    input wire       global_inhibit,
    output reg [7:0] state,
    output reg       spike
);

    reg [3:0]  refractory;
    wire [7:0] leaked_state;
    wire [7:0] integrated_state;

    assign leaked_state     = state - (state >> leak);
    assign integrated_state = leaked_state + {7'b0000000, current};

    always @(posedge clk) begin
        if (!reset_n) begin
            state     <= 8'b00000000;
            spike     <= 1'b0;
            refractory <= 4'd0;
        end else begin
            spike <= 1'b0;

            if (refractory != 4'd0) begin
                refractory <= refractory - 1'b1;
            end else if (!global_inhibit) begin
                state <= integrated_state;
                // Threshold comparison
                if (integrated_state >= threshold) begin
                    spike      <= 1'b1;
                    state      <= 8'd0;     // reset membrane
                    refractory <= 4'd8;     // refractory period
                end
            end
        end
    end

endmodule
