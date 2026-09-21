


`timescale 1ns/100ps
`ifndef DISABLE_DEFAULT_NET
`default_nettype none
`endif

`include "define_state.h"

module MS2_CS(
		input logic Clock,		
		input logic resetn,
		input logic M2_start_Cs,
		input logic mode, 
		
		//inputs for reading RAM T and RAM C
		input logic read_data_a[1], 
		input logic read_data_a[2], 
		
		//outputs for RAM T, C and Cs 
		output logic address_a[1],	
		output logic address_a[2], 
		output logic address_a[3],
	
	   output logic address_b[1], 
      output logic address_b[2], 
		output logic address_b[3], 
	
		//outputs for write enable 
		output logic write_en_a[3],
		output logic write_en_b[3],
		
		//write data
		output logic write_data_a[3],
		output logic write_data_b[3],
	

		output logic M2_finish_Cs
	
	
);


	M2_Cs_state_type M2_state;



	//DPRAM: 0 is S', 1 is C, 2 is T, 3 is S
	
	
	logic [7:0] address_a [3:0];  //256 locations so 8 bits required for address a and b 
	logic [7:0] address_b [3:0];
	
	logic [31:0] write_data_a [3:0], 
	logic [31:0] write_data_b [3:0];  //32 bits of data 
	
	logic [31:0] read_data_a [3:0];

   logic write_en_a [3:0], 
	logic write_en_b [3:0]; 	

	
	
	logic [31:0] mult_op_1_1, mult_op_1_2, mult_op_2_1, mult_op_2_2, mult_op_3_1 , mult_op_3_2;

	logic [63:0] Mult_result_long_1, Mult_result_long_2, Mult_result_long_3; //do we need this again?
	
	logic [31:0] Mult_result_1, Mult_result_2, Mult_result_3;
	
	
	assign Mult_result_long_1 = mult_op_1_1 * mult_op_1_2; 

	assign Mult_result_long_2 = mult_op_2_1 * mult_op_2_2;

	assign Mult_result_long_3 = mult_op_3_1 * mult_op_3_2; 
	
	
	assign Mult_result_1 = Mult_result_long_1[31:0];

	assign Mult_result_2 = Mult_result_long_2[31:0];

	assign Mult_result_3 = Mult_result_long_3[31:0];
	
	logic [31:0] accum_1, accum_2, accum_3, accum_3_buf; 
	
	logic flag_1;
	
	logic col_counter [2:0];
	
	logic  iteration;  //mode
	
	logic e_counter [7:0];
	
	// S' has already been saved into a DP_RAM (inst_0), we write S values to (inst_3)
	//Each Y location in the DP-RAM contains two y-values 
	
	always_ff @(posedge clock or negedge resetn) begin
	
		if(!resetn) begin 
		
		flag_1 <= 1'b0; //flag 1 is set to zero when we are doing the very first block of Y/U/V
		col_counter <= 2'b0; //checks whether we are computing for 3 T values or 2 T values
//		mode <= 1'b0; //starts with the Y blocks 
		iteration <= 1'b0; //only matters for Y blocks as it needs to go through the state structure twice per value 
		e_counter <= 8'b0;
		
		end
		
		
		S_CS_IDLE: begin 
		
		
		iteration <= 1'b0;
		e_counter <= 8'b0;
		flag_1 <= 1'b0;
		col_counter <= 3'b0;
		address_a[2] <= 8'b0;
		address_b[2] <= 8'b0;
		address_a[1] <= 8'b0;
		address_a[3] <= 8'b0;
		address_b[3] <= 8'b1;
		
		if(M2_start_Ct == 1'b1)begin
		M2_state <= S_LI_0;
		end 
		
		
		end
		
		S_LI_0: begin 
		
		address_a[1] <= 8'b1;
		address_a[2] <= 8'b1;
		address_b[1] <= 8'd97;
		
		M2_state <= S_CT_0;
		
		
		end
		//In one cc u set address, in the next u get read_add, in the next u use it
		
		S_CS_0: begin
		
		mult_op_1_1 <= $signed(read_data_a[2][31:0]); //T0, Y16     Is $signed() necessary here? T is alr 32 bits
		mult_op_2_1 <= $signed(read_data_a[2][31:0]); //T0 
		mult_op_3_1 <= $signed(read_data_a[2][31:0]); //T0
		 
		if(mode == 1'b0) begin
		mult_op_1_2 <= $signed(read_data_a[1][29:20]);//C0,0 
		mult_op_2_2 <= $signed(read_data_a[1][19:10]);//C0,1 
		mult_op_3_2 <= $signed(read_data_a[1][9:0]);//C0,2 
		address_a[1] <= address_a[1] + 8'b1; 
		end 
		else begin 
		mult_op_1_2 <= $signed(read_data_b[1][29:20]);//C0,0 
		mult_op_2_2 <= $signed(read_data_b[1][19:10]);//C0,1 
		mult_op_3_2 <= $signed(read_data_b[1][9:0]);//C0,2 
		address_b[1] <= address_b[1] + 8'b1; 
		end 
		

		address_a[2] <= address_a[2] + 8'b1;
		
		/*
		if(mode == 1'b1) begin
		if(col_counter == 3'd3)begin
		address_b[2] <= address_a[2];
		end
		end
		else begin 
		if(col_counter == 3'd6) begin 
		address_b[2] <= address_a[2];
		end
		end*/ 
		
		
		/*
		if(mode == 1'b0)begin
		if(e_counter < 8'd248)begin
		address_a[1] <= address_a[1] + 8'b1; 
		end 
		end 
		else begin
		if(e_counter < 8'd24)begin */
		//address_a[1] <= address_a[1] + 8'b1; 
		//end
		//end
		
		
		
		
		if(flag_1) begin //address_a[0] != 8'b0
		accum_1 <=  13'd4096 + ((accum_1 + Mult_result_1) >>> 5);
		accum_2 <=  13'd4096 + ((accum_2 + Mult_result_2) >>> 5);
		accum_3 <=  13'd4096 + ((accum_3 + Mult_result_3) >>> 5);
		end
		
		
		M2_state <= S_CS_1;
		
		end
		
		S_CS_1: begin 
		
		if(flag_1)begin
		
		if(mode == 1'b0)begin 
		
		if(iteration == 1'b0) begin
		
		write_data_a[3] <= accum_1;
		write_data_b[3] <= accum_2;
		
		write_en_a[3] <= 1'b1;
		write_en_b[3] <= 1'b1; 
		
		if(e_counter == 8'd96) begin
		M2_state <= S_CS_IDLE;
		M2_finish_Cs <= 1'b1;
		end
		
		end
		end 
		
		else begin
		write_data_a[3] <= accum_1;
		write_data_b[3] <= accum_2;
		
		write_en_a[3] <= 1'b1;
		write_en_b[3] <= 1'b1; 
		
		if(e_counter == 8'd24) 
		M2_State <= S_CS_IDLE;
		M2_finish_Cs <= 1'b1;
		end
		end
		end
		
		
		mult_op_1_1 <= $signed(read_data_a[2][31:0]); //T1
		mult_op_2_1 <= $signed(read_data_a[2][31:0]); //T1
		mult_op_3_1 <= $signed(read_data_a[2][31:0]); //T1
		
		if(mode == 1'b0) begin
		mult_op_1_2 <= $signed(read_data_a[1][29:20]);//C0,0 
		mult_op_2_2 <= $signed(read_data_a[1][19:10]);//C0,1 
		mult_op_3_2 <= $signed(read_data_a[1][9:0]);//C0,2 
		address_a[1] <= address_a[1] + 8'b1; 
		end 
		else begin 
		mult_op_1_2 <= $signed(read_data_b[1][29:20]);//C0,0 
		mult_op_2_2 <= $signed(read_data_b[1][19:10]);//C0,1 
		mult_op_3_2 <= $signed(read_data_b[1][9:0]);//C0,2 
		address_b[1] <= address_b[1] + 8'b1; 
		end
		
		/*
		if(mode == 0)begin
		if(e_counter < 8'd248)begin
		address_a[1] <= address_a[1] + 8'b1; 
		end 
		end 
		else begin 
		if(e_counter < 8'd24)begin */
		//end
		//end
		
		accum_1 <= Mult_result_1;
		accum_2 <= Mult_result_2; 
		accum_3 <= Mult_result_3;
		
		accum_3_buf <= accum_3;
		
		address_a[2] <= address_a[2] + 8'b1;
		
		M2_state <= S_CS_2;

		end
		
		S_CS_2: begin 
		
		if(flag_1) begin
		
		if(mode == 1'b0) begin 
		if(iteration == 1'b0) begin
		address_a[3] <= address_a[3] + 8'd2;
		if(col_counter == 3'd3 || col_counter == 3'd6) begin
		address_b[3] <= address_b[3] + 8'd2;
		write_en_a[3] <= 1'b0;
		end 
		else begin 
		address_b[3] <= address_b[3] + 8'd3;
		write_data_a[3] <= accum_3_buf;
		
		end
		write_en_b[3] <= 1'b0; 
		end
		end
		
		else begin 
		if(col_counter < 3'd3) begin
		write_data_a[3] <= accum_3_buf;
		address_b[3] <= address_b[3] + 8'd3;
		end 
		else begin 
		address_b[3] <= address_b[3] + 8'd2;
		end
		write_en_b[3] <= 1'b0; 
		end
		end
		
		
		mult_op_1_1 <= $signed(read_data_a[2][31:0]); //T2
		mult_op_2_1 <= $signed(read_data_a[2][31:0]); //T2
		mult_op_3_1 <= $signed(read_data_a[2][31:0]); //T2
		
		if(mode == 1'b0) begin
		mult_op_1_2 <= $signed(read_data_a[1][29:20]);//C0,0 
		mult_op_2_2 <= $signed(read_data_a[1][19:10]);//C0,1 
		mult_op_3_2 <= $signed(read_data_a[1][9:0]);//C0,2 
		address_a[1] <= address_a[1] + 8'b1; 
		end 
		else begin 
		mult_op_1_2 <= $signed(read_data_b[1][29:20]);//C0,0 
		mult_op_2_2 <= $signed(read_data_b[1][19:10]);//C0,1 
		mult_op_3_2 <= $signed(read_data_b[1][9:0]);//C0,2 
		address_b[1] <= address_b[1] + 8'b1; 
		end
		
		address_a[2] <= address_a[2] + 8'b1; 
		
		
		M2_state <= S_CS_3;
		
		
		end
		
		S_CS_3: begin 
		if(flag_1) begin 
		
		if(mode == 1'b0) begin 
		if(iteration == 1'b0) begin 
		
		if(!(col_counter == 3'd3 || col_counter == 3'd6)) begin
		write_en_a[3] <= 1'b0; 
		address_a[3] <= address_a[3] + 8'd1;
		end 
		end
		else begin 
		
		if(col_counter < 3'd3) begin
		write_en_a[3] <= 1'b0; 
		address_a[3] <= address_a[3] + 8'd1;
		end 
		end
		end
		
		mult_op_1_1 <= $signed(read_data_a[2][31:0]); //T3
		mult_op_2_1 <= $signed(read_data_a[2][31:0]); //T3
		mult_op_3_1 <= $signed(read_data_a[2][31:0]); //T3
		
		if(mode == 1'b0) begin
		mult_op_1_2 <= $signed(read_data_a[1][29:20]);//C0,0 
		mult_op_2_2 <= $signed(read_data_a[1][19:10]);//C0,1 
		mult_op_3_2 <= $signed(read_data_a[1][9:0]);//C0,2 
		address_a[1] <= address_a[1] + 8'b1; 
		end 
		else begin 
		mult_op_1_2 <= $signed(read_data_b[1][29:20]);//C0,0 
		mult_op_2_2 <= $signed(read_data_b[1][19:10]);//C0,1 
		mult_op_3_2 <= $signed(read_data_b[1][9:0]);//C0,2 
		address_b[1] <= address_b[1] + 8'b1; 
		end
		
		
		address_a[2] <= address_a[2] + 8'b1;
		
		accum_1 <= accum_1 + Mult_result_1;
		accum_2 <= accum_2 + Mult_result_2;
		accum_3 <= accum_3 + Mult_result_3;
		
		M2_state <= S_CS_4;

		end 
		
		S_CS_4: begin 
		
		mult_op_1_1 <= $signed(read_data_a[2][31:0]); //T4
		mult_op_2_1 <= $signed(read_data_a[2][31:0]); //T4
		mult_op_3_1 <= $signed(read_data_a[2][31:0]); //T4
		
		if(mode == 1'b0) begin
		mult_op_1_2 <= $signed(read_data_a[1][29:20]);//C0,0 
		mult_op_2_2 <= $signed(read_data_a[1][19:10]);//C0,1 
		mult_op_3_2 <= $signed(read_data_a[1][9:0]);//C0,2 
		address_a[1] <= address_a[1] + 8'b1; 
		end 
		else begin 
		mult_op_1_2 <= $signed(read_data_b[1][29:20]);//C0,0 
		mult_op_2_2 <= $signed(read_data_b[1][19:10]);//C0,1 
		mult_op_3_2 <= $signed(read_data_b[1][9:0]);//C0,2 
		address_b[1] <= address_b[1] + 8'b1; 
		end
		
		address_a[2] <= address_a[2] + 8'b1;
	
		
		
		M2_state <= S_CS_5;
		
		
		end
		
		S_CS_5: begin 
		
		mult_op_1_1 <= $signed(read_data_a[2][31:0]); //T5
		mult_op_2_1 <= $signed(read_data_a[2][31:0]); //T5
		mult_op_3_1 <= $signed(read_data_a[2][31:0]); //T5
		
		if(mode == 1'b0) begin
		mult_op_1_2 <= $signed(read_data_a[1][29:20]);//C0,0 
		mult_op_2_2 <= $signed(read_data_a[1][19:10]);//C0,1 
		mult_op_3_2 <= $signed(read_data_a[1][9:0]);//C0,2 
		address_a[1] <= address_a[1] + 8'b1; 
		end 
		else begin 
		mult_op_1_2 <= $signed(read_data_b[1][29:20]);//C0,0 
		mult_op_2_2 <= $signed(read_data_b[1][19:10]);//C0,1 
		mult_op_3_2 <= $signed(read_data_b[1][9:0]);//C0,2 
		address_b[1] <= address_b[1] + 8'b1; 
		end
		
		
		address_a[2] <= address_a[2] + 8'b1;
		
		
		accum_1 <= accum_1 + Mult_result_1;
		accum_2 <= accum_2 + Mult_result_2;
		accum_3 <= accum_3 + Mult_result_3;
		
		M2_state <= S_CS_6;
		
		end
		
		S_CS_6: begin 
		
		mult_op_1_1 <= $signed(read_data_a[2][31:0]); //T6
		mult_op_2_1 <= $signed(read_data_a[2][31:0]); //T6
		mult_op_3_1 <= $signed(read_data_a[2][31:0]); //T6
		
		if(mode == 1'b0) begin
		mult_op_1_2 <= $signed(read_data_a[1][29:20]);//C0,0 
		mult_op_2_2 <= $signed(read_data_a[1][19:10]);//C0,1 
		mult_op_3_2 <= $signed(read_data_a[1][9:0]);//C0,2 
		
		end 
		else begin 
		mult_op_1_2 <= $signed(read_data_b[1][29:20]);//C0,0 
		mult_op_2_2 <= $signed(read_data_b[1][19:10]);//C0,1 
		mult_op_3_2 <= $signed(read_data_b[1][9:0]);//C0,2 
		
		end
		
		if(mode == 1'b0) begin 
		if (iteration == 1'b1) begin
			if(col_counter == 3'd6)begin 
			address_a[1] <= 8'b0;
			address_a[2] <= address_a[2] + 8'b1;
			end
			else begin
			address_a[2] <= address_b[2];
			address_a[1] <= address_a[1] + 8'b1;
			end 
		end 
		else begin
			address_a[2] <= address_a[2] + 8'b1;
			address_a[1] <= address_a[1] + 8'b1;
		
		end
		end
		else begin
		
		if(col_counter == 3'd2) begin 
		address_a[2] <= address_a[2] + 8'b1;
		address_b[1] <= 8'd96;
		end
		else begin 
		address_a[2] <= address_b[2];
		address_b[1] <= address_b[1] + 8'b1;
		end
		end
		
		
		
		
		M2_state <= S_CS_7;
		
	
		end
		
		S_CS_7: begin 
		
		mult_op_1_1 <= $signed(read_data_a[2][31:0]); //Y7
		mult_op_2_1 <= $signed(read_data_a[2][31:0]); //Y7
		mult_op_3_1 <= $signed(read_data_a[2][31:0]); //Y7
		
		if(mode == 1'b0) begin
		mult_op_1_2 <= $signed(read_data_a[1][29:20]);//C0,0 
		mult_op_2_2 <= $signed(read_data_a[1][19:10]);//C0,1 
		mult_op_3_2 <= $signed(read_data_a[1][9:0]);//C0,2 
		address_a[1] <= address_a[1] + 8'b1; 
		end 
		else begin 
		mult_op_1_2 <= $signed(read_data_b[1][29:20]);//C0,0 
		mult_op_2_2 <= $signed(read_data_b[1][19:10]);//C0,1 
		mult_op_3_2 <= $signed(read_data_b[1][9:0]);//C0,2 
		address_b[1] <= address_b[1] + 8'b1; 
		end
		
		address_a[2] <= address_a[2] + 8'b1;

		
		accum_1 <= accum_1 + Mult_result_1;
		accum_2 <= accum_2 + Mult_result_2;
		accum_3 <= accum_3 + Mult_result_3;
		
		flag_1 <= 1'b1;
		
		
		if(mode == 1'b0) begin 
		
		if(iteration == 1'b0) begin 
		
		if(col_counter < 3'd6) begin
		col_counter <= col_counter + 3'b1;
		end 
		else begin
		col_counter <= 3'd1;
		end 
		end
		
		end 
		
		else begin
		if(col_counter < 3'd3) begin 
		col_counter <= col_counter + 3'b1;
		end 
		else begin
		col_counter <= 3'd1;
		end 
		end
		
		if(mode == 1'b0)
		iteration <= ~iteration;
		
		
		if(mode == 1'b1) begin
		if(col_counter == 3'd2)begin
		address_b[2] <= address_a[2];
		end
		end
		else begin 
		if(col_counter == 3'd5) begin 
		address_b[2] <= address_a[2];
		end
		end
		
		
		e_counter <= e_counter + 1'b1;
		
		M2_state <= S_CS_0;
		
		
		
		end 
	
	end
	
	
	endmodule 
	
		
		

