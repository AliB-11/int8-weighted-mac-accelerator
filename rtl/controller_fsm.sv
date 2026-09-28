`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
//
// controller_fsm.sv
// Sequences the whole datapath: IDLE -> LOAD_WEIGHTS -> STREAM_IN -> STREAM_OUT -> DONE -> IDLE
//
// STREAM_IN does double duty as "feed the sliding window" AND "compute" -
// unlike doc 2's array (which needs a dedicated multi-cycle COMPUTE state
// to drain a ROWS+COLS+K-2 cycle pipeline), mac_row here is a one-cycle
// combinational adder tree, so a result is ready the cycle after each shift.
//
// STREAM_OUT exists only to catch mac_row's *last* registered result after
// the final input sample (x_last) has been shifted in - mac_row has a
// one-cycle registered latency, so the last valid acc value doesn't appear
// until one cycle after the last shift.
//
// NOTE: this first-pass version has NO input-side backpressure (x_ready is
// simply "high whenever in STREAM_IN") and no output-side buffering beyond
// mac_row's own register. That's an intentional simplification for this
// scope, mirroring doc 2's own acknowledged wrapper simplifications (no
// TLAST, no double-buffering) - worth flagging as a known limitation, not
// silently hiding it.
// 
//////////////////////////////////////////////////////////////////////////////////




module controller_fsm #(
    parameter int K = 5
)(
    input  logic clk,
    input  logic rst_n,
 
    input  logic start,           // pulse: begin a new kernel load + stream
 
    // kernel_reg interface
    input  logic w_valid,
    output logic w_ready,
    input  logic kernel_full,
    output logic kernel_load_en,
    output logic kernel_clear,
 
    // line_buffer interface
    input  logic x_valid,
    output logic x_ready,
    input  logic x_last,          // host asserts alongside the final x_valid sample
    output logic buf_shift_en,
    output logic buf_clear,
    input  logic window_valid,
 
    // mac_row interface
    input  logic mac_valid_out,
    output logic result_pop       // a fresh, valid result is available on acc this cycle
);
 
    typedef enum logic [2:0] {
        IDLE,
        LOAD_WEIGHTS,
        STREAM_IN,
        STREAM_OUT,
        DONE
    } state_t;
 
    state_t state, next_state;
 
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) state <= IDLE;
        else        state <= next_state;
    end
 
    always_comb begin
        next_state = state;
        case (state)
            IDLE: begin
                if (start) next_state = LOAD_WEIGHTS;
            end
 
            LOAD_WEIGHTS: begin
                if (kernel_full) next_state = STREAM_IN;
            end
 
            STREAM_IN: begin
                if (x_valid && x_ready && x_last) next_state = STREAM_OUT;
            end
 
            STREAM_OUT: begin
                // drain cycle: final window is evaluated here (mac_row is pipelined)
                next_state = DONE;
            end
 
            DONE: begin
                next_state = IDLE;
            end
 
            default: next_state = IDLE;  // one-hot/illegal-state recovery
        endcase
    end
 
    always_comb begin
        kernel_clear    = (state == IDLE) && start;
        kernel_load_en  = (state == LOAD_WEIGHTS) && w_valid;
        w_ready         = (state == LOAD_WEIGHTS) && !kernel_full;
 
        buf_clear       = (state == IDLE) && start;
        x_ready         = (state == STREAM_IN);
        buf_shift_en    = (state == STREAM_IN) && x_valid && x_ready;
 
        result_pop      = mac_valid_out;  // valid_out already means 'real result'
    end
 
endmodule
