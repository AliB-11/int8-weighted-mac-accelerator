`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// mac_row.sv
// Parallel / direct-form MAC array (locked architecture choice - NOT a
// systolic/chained PE structure). All K multiplies fire the same cycle
// against the shared window/weights buses; a combinational adder tree
// sums them; the result is captured in a single registered accumulator..
// 
//////////////////////////////////////////////////////////////////////////////////


module mac_row #(
    parameter int DW        = 8,
    parameter int K         = 5,
    // Headroom: 2*DW bits per signed product, plus clog2(K) bits of growth
    // for summing K of them, plus 2 bits of margin (mirrors the reasoning
    // doc 2 used for its own INT32 accumulator, scaled down to this K).
    parameter int ACC_WIDTH = 2*DW + $clog2(K) + 2
)(
    input  logic                          clk,
    input  logic                          rst_n,
    input  logic signed [DW-1:0]          window  [K-1:0],
    input  logic signed [DW-1:0]          weights [K-1:0],
    input  logic                          valid_in,   // window/weights are a real, complete pairing this cycle
    output logic signed [ACC_WIDTH-1:0]   acc,
    output logic                          valid_out
);
 
    // use_dsp forces each multiply onto a dedicated DSP48E1 slice rather
    // than letting Vivado implement it in LUT fabric. NOTE: the attribute
    // must sit on a scalar signal driven directly by the multiply (same
    // pattern as doc 2's pe.sv). Putting it on an unpacked array declaration
    // was ignored by Vivado (first synthesis run reported 0 DSPs).
    logic signed [2*DW-1:0] products [K-1:0];
 
    for (genvar i = 0; i < K; i++) begin : g_mul
        (* use_dsp = "yes" *) logic signed [2*DW-1:0] prod;
        assign prod        = window[i] * weights[i];
        assign products[i] = prod;
    end
 
    // Pipeline stage 1: register each product. No reset on purpose: the
    // DSP48E1's internal multiplier register (MREG) only supports a
    // synchronous reset, so an async-reset flop here could not be absorbed
    // into the DSP. valid_q tells downstream logic whether prod_q is real.
    logic signed [2*DW-1:0] prod_q [K-1:0];
    logic                   valid_q;
 
    always_ff @(posedge clk) begin
        for (int i = 0; i < K; i++) prod_q[i] <= products[i];
    end
 
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) valid_q <= 1'b0;
        else        valid_q <= valid_in;
    end
 
    // Pipeline stage 2: sum the registered products into acc.
    logic signed [ACC_WIDTH-1:0] sum_comb;
 
    always_comb begin
        sum_comb = '0;
        for (int i = 0; i < K; i++) begin
            sum_comb = sum_comb + ACC_WIDTH'(prod_q[i]);
        end
    end
 
    // Two-cycle latency from (window, weights, valid_in) to (acc, valid_out).
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            acc       <= '0;
            valid_out <= 1'b0;
        end else begin
            acc       <= sum_comb;
            valid_out <= valid_q;
        end
    end
 
endmodule
 
 