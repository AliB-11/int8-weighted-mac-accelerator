`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
//
// conv_top.sv
// Top-level serial wrapper. Solves the same pin-count problem doc 2's
// wrapper solves: weights and samples stream in one byte per cycle over a
// valid/ready handshake instead of being exposed as wide parallel ports.
// This is the module that gets instantiated as the top level for synthesis.
//
// KNOWN SIMPLIFICATION: y_ready is accepted on the port but not yet used to
// apply backpressure upstream (no skid buffer). Fine for this scope; would
// need addressing for a "production" version, same spirit as doc 2's own
// noted wrapper limitations.
// 
//////////////////////////////////////////////////////////////////////////////////

 
module conv_top #(
    parameter int DW        = 8,
    parameter int K         = 5,
    parameter int ACC_WIDTH = 2*DW + $clog2(K) + 2
)(
    input  logic clk,
    input  logic rst_n,
 
    input  logic start,
 
    // weight load stream
    input  logic                    w_valid,
    output logic                    w_ready,
    input  logic signed [DW-1:0]    w_data,
 
    // sample input stream
    input  logic                    x_valid,
    output logic                    x_ready,
    input  logic signed [DW-1:0]    x_data,
    input  logic                    x_last,
 
    // result output stream
    output logic                          y_valid,
    input  logic                          y_ready,   // accepted, not yet used - see note above
    output logic signed [ACC_WIDTH-1:0]   y_data
);
 
    logic signed [DW-1:0] weights [K-1:0];
    logic                 kernel_full;
    logic                 kernel_load_en, kernel_clear;
 
    logic signed [DW-1:0] window [K-1:0];
    logic                 window_valid;
    logic                 buf_shift_en, buf_clear;
 
    logic signed [ACC_WIDTH-1:0] mac_acc;
    logic                        mac_valid_out;
 
    logic result_pop;
 
    // shift_q = buf_shift_en delayed one cycle. The window registers only
    // hold the new sample the cycle AFTER a shift, so mac_row must evaluate
    // the window then. (Using buf_shift_en directly would evaluate the
    // pre-shift window and never compute the final window of the stream.)
    logic shift_q;
 
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) shift_q <= 1'b0;
        else        shift_q <= buf_shift_en;
    end
 
    kernel_reg #(
        .DW (DW),
        .K  (K)
    ) u_kernel_reg (
        .clk     (clk),
        .rst_n   (rst_n),
        .clear   (kernel_clear),
        .load_en (kernel_load_en),
        .w_in    (w_data),
        .weights (weights),
        .full    (kernel_full)
    );
 
    line_buffer #(
        .DW (DW),
        .K  (K)
    ) u_line_buffer (
        .clk          (clk),
        .rst_n        (rst_n),
        .clear        (buf_clear),
        .shift_en     (buf_shift_en),
        .x_in         (x_data),
        .window       (window),
        .window_valid (window_valid)
    );
 
    mac_row #(
        .DW        (DW),
        .K         (K),
        .ACC_WIDTH (ACC_WIDTH)
    ) u_mac_row (
        .clk       (clk),
        .rst_n     (rst_n),
        .window    (window),
        .weights   (weights),
        // Evaluate the freshly updated window the cycle after each shift,
        // but only once the window holds K real samples.
        .valid_in  (shift_q && window_valid),
        .acc       (mac_acc),
        .valid_out (mac_valid_out)
    );
 
    controller_fsm #(
        .K (K)
    ) u_controller (
        .clk            (clk),
        .rst_n          (rst_n),
        .start          (start),
        .w_valid        (w_valid),
        .w_ready        (w_ready),
        .kernel_full    (kernel_full),
        .kernel_load_en (kernel_load_en),
        .kernel_clear   (kernel_clear),
        .x_valid        (x_valid),
        .x_ready        (x_ready),
        .x_last         (x_last),
        .buf_shift_en   (buf_shift_en),
        .buf_clear      (buf_clear),
        .window_valid   (window_valid),
        .mac_valid_out  (mac_valid_out),
        .result_pop     (result_pop)
    );
 
    assign y_valid = result_pop;
    assign y_data  = mac_acc;
 
endmodule
 