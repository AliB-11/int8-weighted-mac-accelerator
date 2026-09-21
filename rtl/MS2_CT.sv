


	`timescale 1ns/100ps
	`ifndef DISABLE_DEFAULT_NET
	`default_nettype none
	`endif

	`include "define_state.h"

	module MS2_CT(
			input logic Clock,		
			input logic resetn,
			input logic M2_start_Ct,
			input logic mode,
			
			//inputs for reading_data from DPRAM S and C 
			input logic read_data_a[1:0], 
			input logic read_data_b[1:0], 
			
			//end signal 
			output logic M2_finish_Ct, 
			
			//outputs for DPRAM addresses 
			output logic address_a[2:0], 
			output logic address_b[2:0], 

			
			//outputs for write enables (only writing to DPRAM T) 
			
			output logic write_en_a, 
			output logic write_en_b,
			
			//outputs for write_data to DPRAM T
			output logic write_data_a,
			output logic write_data_b 
	);



	M2_Ct_state_type M2_state;

		
	
   logic [7:0] address_a [2:0];  //256 locations so 8 bits required for address a and b 
	logic [7:0] address_b [2:0];
	
	logic [31:0] write_data_a; 
	logic [31:0] write_data_b;  //32 bits of data 
	
	logic [31:0] read_data_a [1:0];
	logic [31:0] read_data_b [1:0];
	
	

   logic write_en_a; 
	logic write_en_b; 	

	
	
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
	
	logic  iteration; //mode
	
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
		//F,T,SF,TW,SF,TW,SF,TW,......TW,S,W
		//States for Fetching and storing whatever (Y,U/V) 
		
		//Last state in fetching: Set address_a and address_b for inst_a = to specific values (0 and 1)
		
		//Fetching Completed 
		//Move to Computing T 
		
		
		S_CT_IDLE: begin 
		
		
		iteration <= 1'b0;
		e_counter <= 8'b0;
		flag_1 <= 1'b0;
		col_counter <= 3'b0;
		address_a[1] <= 8'b0;
		address_b[1] <= 8'd96;
		address_a[0] <= 8'b0;
		address_b[0] <= 8'b0;
		address_a[2] <= 8'b0;
		address_b[2] <= 8'b1;
		
		if(M2_start_Ct == 1'b1)begin
		M2_state <= S_LI_0;
		end 
		
		S_LI_0: begin //Delay State 
		
		address_a[1] <= 8'b1;
		address_b[1] <= 8'd97;
		
		M2_state <= S_CT_0;
		
		
		end
		
		
		end
		
		S_CT_0: begin 
	
		//C00C01,C02C03,C04C05,C06C07,C08C09,C10C11,C12C13,C14C15,
		//C16C17,C18C19
		
		//We receive data from address 0 (inst_0) here 
		//We receive data from address 0 and address 1 (inst_1 RAM_C) from here 
		mult_op_1_1 <= $signed(read_data_a[0][31:16]); //Y0, Y16
		mult_op_2_1 <= $signed(read_data_a[0][31:16]); //Y0 
		mult_op_3_1 <= $signed(read_data_a[0][31:16]); //Y0 
		
		if(mode == 1'b0) begin
		mult_op_1_2 <= $signed(read_data_a[1][29:20]);//C0,0 
		mult_op_2_2 <= $signed(read_data_a[1][19:10]);//C0,1 
		mult_op_3_2 <= $signed(read_data_a[1][9:0]);//C0,2 
		address_a[1] <= address_a[1] + 8'b1;
		if(col_counter == 3'd6) begin 
		address_b[0] <= address_a[0];
		end 
		else begin 
		mult_op_1_2 <= $signed(read_data_b[1][29:20]);//C0,0 
		mult_op_2_2 <= $signed(read_data_b[1][19:10]);//C0,1 
		mult_op_3_2 <= $signed(read_data_b[1][9:0]);//C0,2 
		address_b[1] <= address_b[1] + 8'b1; 
		if(col_counter == 3'd3)begin
		address_b[0] <= address_a[0];
		end
		
		//In one cc u set address, in the next u get read_add, in the next u use it
		
		address_a[0] <= address_a[0] + 8'b1;

		if(flag_1) begin //address_a[0] != 8'b0
		accum_1 <= accum_1 + Mult_result_1;
		accum_2 <= accum_2 + Mult_result_2;
		accum_3 <= accum_3 + Mult_result_3;
		end 
		
		
		M2_state <= S_CT_1;
		
		end
		
		S_CT_1: begin 
		
		if(flag_1)begin
		
		if(mode == 1'b0)begin 
		
		if(iteration == 1'b0) begin
		
		write_data_a <= accum_1;
		write_data_b <= accum_2;
		/*
		address_a[2] <= address_a[2] + 8'd2;
		if(col_counter == 3'd3 || col_counter == 3'd6) begin
		address_b[2] <= address_b[2] + 8'd2;
		end 
		else begin 
		address_b[2] <= address_b[2] + 8'd3;
		end
		*/
		write_en_a <= 1'b1;
		write_en_b <= 1'b1; 
		
		if(e_counter == 8'd96) begin
		M2_state <= S_CT_IDLE;
		M2_finish_Ct <= 1'b1;
		end
		
		end
		end 
		
		else begin
		write_data_a <= accum_1;
		write_data_b <= accum_2;
		/*
		address_a[2] <= address_a[2] + 8'd2;
		if(col_counter < 3'd3) begin
		address_b[2] <= address_b[2] + 8'd3;
		end 
		else begin 
		address_b[2] <= address_b[2] + 8'd2;
		end
		*/
		
		write_en_a <= 1'b1;
		write_en_b <= 1'b1; 
		
		if(e_counter == 8'd24) 
		M2_State <= S_CT_IDLE;
		M2_finish_Ct <= 1'b1;
		end
		end
		
		
		mult_op_1_1 <= $signed(read_data_a[0][15:0]); //Y1
		mult_op_2_1 <= $signed(read_data_a[0][15:0]); //Y1
		mult_op_3_1 <= $signed(read_data_a[0][15:0]); //Y1 
		
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
		address_a[1] <= address_a[1] + 8'b1; 
		//end
		//end
		
		accum_1 <= Mult_result_1;
		accum_2 <= Mult_result_2; 
		accum_3 <= Mult_result_3;
		
		accum_3_buf <= accum_3;
		
		M2_state <= S_CT_2;

		end
		
		S_CT_2: begin 
		
		if(flag_1) begin
		
		if(mode == 1'b0) begin 
		if(iteration == 1'b0) begin
		
		address_a[2] <= address_a[2] + 8'd2;
		if(col_counter == 3'd3 || col_counter == 3'd6) begin
		address_b[2] <= address_b[2] + 8'd2;
		write_en_a <= 1'b0;
		end 
		else begin 
		address_b[2] <= address_b[2] + 8'd3;
		write_data_a <= accum_3_buf;
		
		end
		/*
		if(col_counter == 3'd3 || col_counter == 3'd6) begin
		write_en_a[2] <= 1'b0;
		end 
		else begin 
		write_data_a[2] <= accum_3_buf;
		address_a[2] <= address_a[2] + 8'd1;
		end
		*/
		write_en_b <= 1'b0; 
		end
		end 
		else begin 
		
		address_a[2] <= address_a[2] + 8'd2;
		if(col_counter < 3'd3) begin
		write_data_a <= accum_3_buf;
		address_b[2] <= address_b[2] + 8'd3;
		end 
		else begin 
		address_b[2] <= address_b[2] + 8'd2;
		end
		
		/*
		if(col_counter < 3'd3) begin
		write_data_a[2] <= accum_3_buf;
		address_a[2] <= address_a[2] + 8'd1;
		end 
		else begin 
		write_en_a[2] <= 1'b0; 
		end*/
		
		write_en_b <= 1'b0; 
		end
		end
		
		
		mult_op_1_1 <= $signed(read_data_a[0][31:16]); //Y2
		mult_op_2_1 <= $signed(read_data_a[0][31:16]); //Y2
		mult_op_3_1 <= $signed(read_data_a[0][31:16]); //Y2
		
		if(mode == 1'b0) begin
		mult_op_1_2 <= $signed(read_data_a[1][29:20]);//C2,0 
		mult_op_2_2 <= $signed(read_data_a[1][19:10]);//C2,1 
		mult_op_3_2 <= $signed(read_data_a[1][9:0]);//C2,2
		address_a[1] <= address_a[1] + 8'b1;
	   end 
		else begin 
		mult_op_1_2 <= $signed(read_data_b[1][29:20]);//C2,0 
		mult_op_2_2 <= $signed(read_data_b[1][19:10]);//C2,1 
		mult_op_3_2 <= $signed(read_data_b[1][9:0]);//C2,2
		address_b[1] <= address_b[1] + 8'b1;
		end
		
		address_a[0] <= address_a[0] + 8'b1;
		
		accum_1 <= accum_1 + Mult_result_1;
		accum_2 <= accum_2 + Mult_result_2;
		accum_3 <= accum_3 + Mult_result_3;
		
		M2_state <= S_CT_3;
		
		
		end
		
		S_CT_3: begin 
		
		if(flag_1) begin 
		
		if(mode == 1'b0) begin 
		if(iteration == 1'b0) begin 
		
		if(!(col_counter == 3'd3 || col_counter == 3'd6)) begin
		write_en_a <= 1'b0; 
		address_a[2] <= address_a[2] + 8'd1;
		end 
		end
		else begin 
		
		if(col_counter < 3'd3) begin
		write_en_a <= 1'b0; 
		address_a[2] <= address_a[2] + 8'd1;
		end 
		end
		end
		
		mult_op_1_1 <= $signed(read_data_a[0][15:0]); //Y3
		mult_op_2_1 <= $signed(read_data_a[0][15:0]); //Y3
		mult_op_3_1 <= $signed(read_data_a[0][15:0]); //Y3
		
		if(mode == 1'b0) begin
		mult_op_1_2 <= $signed(read_data_a[1][29:20]);//C3,0 
		mult_op_2_2 <= $signed(read_data_a[1][19:10]);//C3,1 
		mult_op_3_2 <= $signed(read_data_a[1][9:0]);//C3,2 
		address_a[1] <= address_a[1] + 8'b1;
		end
		else begin 
		mult_op_1_2 <= $signed(read_data_b[1][29:20]);//C3,0 
		mult_op_2_2 <= $signed(read_data_b[1][19:10]);//C3,1 
		mult_op_3_2 <= $signed(read_data_b[1][9:0]);//C3,2 
		address_b[1] <= address_b[1] + 8'b1;
		
		end 
		
		accum_1 <= accum_1 + Mult_result_1;
		accum_2 <= accum_2 + Mult_result_2;
		accum_3 <= accum_3 + Mult_result_3;
		
		M2_state <= S_CT_4;

		end 
		
		S_CT_4: begin 
		
		mult_op_1_1 <= $signed(read_data_a[0][31:16]); //Y4
		mult_op_2_1 <= $signed(read_data_a[0][31:16]); //Y4
		mult_op_3_1 <= $signed(read_data_a[0][31:16]); //Y4
		
		if(mode == 1'b0) begin
		mult_op_1_2 <= $signed(read_data_a[1][29:20]);//C4,0 
		mult_op_2_2 <= $signed(read_data_a[1][19:10]);//C4,1 
		mult_op_3_2 <= $signed(read_data_a[1][9:0]);//C4,2 
		address_a[1] <= address_a[1] + 8'b1;
		end 
		else begin 
		mult_op_1_2 <= $signed(read_data_b[1][29:20]);//C4,0 
		mult_op_2_2 <= $signed(read_data_b[1][19:10]);//C4,1 
		mult_op_3_2 <= $signed(read_data_b[1][9:0]);//C4,2 
		address_b[1] <= address_b[1] + 8'b1;
		
		end
		
		address_a[0] <= address_a[0] + 8'b1;

		M2_state <= S_CT_5;
		
		
		end
		
		S_CT_5: begin 
		
		mult_op_1_1 <= $signed(read_data_a[0][15:0]); //Y5
		mult_op_2_1 <= $signed(read_data_a[0][15:0]); //Y5
		mult_op_3_1 <= $signed(read_data_a[0][15:0]); //Y5
		
		
		if(mode == 1'b0) begin
		mult_op_1_2 <= $signed(read_data_a[1][29:20]);//C5,0 
		mult_op_2_2 <= $signed(read_data_a[1][19:10]);//C5,1 
		mult_op_3_2 <= $signed(read_data_a[1][9:0]);//C5,2 
		address_a[1] <= address_a[1] + 8'b1;
		end 
		else begin 
		mult_op_1_2 <= $signed(read_data_b[1][29:20]);//C5,0 
		mult_op_2_2 <= $signed(read_data_b[1][19:10]);//C5,1 
		mult_op_3_2 <= $signed(read_data_b[1][9:0]);//C5,2 
		address_b[1] <= address_b[1] + 8'b1;
		
		end
		
		
		accum_1 <= accum_1 + Mult_result_1;
		accum_2 <= accum_2 + Mult_result_2;
		accum_3 <= accum_3 + Mult_result_3;
		
		M2_state <= S_CT_6;
		
		
		
		end
		
		S_CT_6: begin 
		
		mult_op_1_1 <= $signed(read_data_a[0][31:16]); //Y6
		mult_op_2_1 <= $signed(read_data_a[0][31:16]); //Y6
		mult_op_3_1 <= $signed(read_data_a[0][31:16]); //Y6
		
		
		if(mode == 1'b0) begin
		mult_op_1_2 <= $signed(read_data_a[1][29:20]);//C6,0 
		mult_op_2_2 <= $signed(read_data_a[1][19:10]);//C6,1 
		mult_op_3_2 <= $signed(read_data_a[1][9:0]);//C6,2 
		end 
		else begin 
		mult_op_1_2 <= $signed(read_data_b[1][29:20]);//C6,0 
		mult_op_2_2 <= $signed(read_data_b[1][19:10]);//C6,1 
		mult_op_3_2 <= $signed(read_data_b[1][9:0]);//C6,2 
		end
		
		if(mode == 1'b0) begin 
		if (iteration == 1'b1) begin
			if(col_counter == 3'd6)begin 
			address_a[1] <= 8'b0;
			address_a[0] <= address_a[0] + 8'b1;
			end
			else begin
			address_a[0] <= address_b[0];
			address_a[1] <= address_a[1] + 8'b1;
			end 
		end 
		else begin
			
			address_a[1] <= address_a[1] + 8'b1;
		
		end
		end
		else begin
		
		if(col_counter == 3'd2) begin 
		address_a[0] <= address_a[0] + 8'b1;
		address_b[1] <= 8'd96;
		end
		else begin 
		address_a[0] <= address_b[0];
		address_b[1] <= address_b[1] + 8'b1;
		end
		end
		
		accum_1 <= accum_1 + Mult_result_1;
		accum_2 <= accum_2 + Mult_result_2;
		accum_3 <= accum_3 + Mult_result_3;
		
		
		
		M2_state <= S_CT_7;
		
	
		end
		
		S_CT_7: begin 
		
		mult_op_1_1 <= $signed(read_data_a[0][15:0]); //Y7
		mult_op_2_1 <= $signed(read_data_a[0][15:0]); //Y7
		mult_op_3_1 <= $signed(read_data_a[0][15:0]); //Y7
		
		if(mode == 1'b0) begin
		mult_op_1_2 <= $signed(read_data_a[1][29:20]);//C7,0 
		mult_op_2_2 <= $signed(read_data_a[1][19:10]);//C7,1 
		mult_op_3_2 <= $signed(read_data_a[1][9:0]);//C7,2 
		address_a[1] <= address_a[1] + 8'b1;
		end 
		else begin 
		mult_op_1_2 <= $signed(read_data_b[1][29:20]);//C7,0 
		mult_op_2_2 <= $signed(read_data_b[1][19:10]);//C7,1 
		mult_op_3_2 <= $signed(read_data_b[1][9:0]);//C7,2
		address_b[1] <= address_b[1] + 8'b1;
		end 

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
		
		e_counter <= e_counter + 1'b1;
		
		M2_state <= S_CT_0;
		
		
		
		end 
	
		
		
		
	   
	
	
	end
	
		
		
		
		end
		
		
		endmodule











