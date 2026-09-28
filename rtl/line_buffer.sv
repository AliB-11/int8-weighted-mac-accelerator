`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
//
// line_buffer.sv
// K-deep sliding window over the input sample stream.
//
// Index convention (important - matches mac_row's direct pairing with
// kernel_reg's weights[], and matches the golden model, see notes below):
//   window[0]   = OLDEST sample currently in the window  -> pairs with weights[0]
//   window[K-1] = NEWEST sample just shifted in          -> pairs with weights[K-1]
// i.e. window[k] == x[n+k] for the window currently covering x[n..n+K-1],
// so y[n] = sum_k window[k] * weights[k] directly, no index reversal needed
// anywhere downstream.
// 
//////////////////////////////////////////////////////////////////////////////////



module line_buffer #(
    parameter int DW = 8,
    parameter int K  = 5
)(
    input  logic                    clk,
    input  logic                    rst_n,
    input  logic                    clear,        // pulse: reset window validity for a fresh stream
    input  logic                    shift_en,     // shift in x_in this cycle
    input  logic signed [DW-1:0]    x_in,
    output logic signed [DW-1:0]    window [K-1:0],
    output logic                    window_valid  // high once K real samples have shifted in
);
 
    logic [$clog2(K+1)-1:0] fill_cnt;
 
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            fill_cnt     <= '0;
            window_valid <= 1'b0;
            for (int i = 0; i < K; i++) window[i] <= '0;
        end else if (clear) begin
            fill_cnt     <= '0;
            window_valid <= 1'b0;
            // window contents are left as-is; window_valid dropping means
            // mac_row will not be told to treat them as valid until the
            // window is genuinely refilled with real samples.
        end else if (shift_en) begin
            // Shift left: window[K-1] (newest) is retired out of the
            // "newest" slot as everything moves down; a genuinely new
            // sample enters at window[K-1].
            for (int i = 0; i < K-1; i++) begin
                window[i] <= window[i+1];
            end
            window[K-1] <= x_in;
 
            if (!window_valid) begin
                if (fill_cnt == K[$clog2(K+1)-1:0] - 1'b1) begin
                    window_valid <= 1'b1;
                end else begin
                    fill_cnt <= fill_cnt + 1'b1;
                end
            end
        end
    end
 
endmodule
