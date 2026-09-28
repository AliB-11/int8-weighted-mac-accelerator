`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
//
// kernel_reg.sv
// Stationary weight bank for the weight-stationary convolution accelerator.
// Loads K signed INT8 weights, one per cycle, then holds them fixed until
// `clear` is pulsed to begin a fresh load (used for the kernel-reload test).
// 
//////////////////////////////////////////////////////////////////////////////////


module kernel_reg#(

    parameter int DW = 8,   // data width (signed weight)
    parameter int K  = 5    // kernel size (number of taps)
)(
    input  logic                    clk,
    input  logic                    rst_n,
    input  logic                    clear,     // pulse: reset load state for a fresh kernel
    input  logic                    load_en,   // load one weight this cycle
    input  logic signed [DW-1:0]    w_in,
    output logic signed [DW-1:0]    weights [K-1:0],
    output logic                    full       // all K weights loaded
);
 
    logic [$clog2(K+1)-1:0] load_cnt;
 
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            load_cnt <= '0;
            full     <= 1'b0;
            for (int i = 0; i < K; i++) weights[i] <= '0;
        end else if (clear) begin
            // Fresh load requested - drop full, restart the counter.
            // Weight values themselves are left as-is until overwritten;
            // `full` gates mac_row's use of them so stale values are never
            // read while a reload is in progress.
            load_cnt <= '0;
            full     <= 1'b0;
        end else if (load_en && !full) begin
            weights[load_cnt] <= w_in;
            if (load_cnt == K[$clog2(K+1)-1:0] - 1'b1) begin
                full     <= 1'b1;
                load_cnt <= '0;
            end else begin
                load_cnt <= load_cnt + 1'b1;
            end
        end
    end

endmodule
