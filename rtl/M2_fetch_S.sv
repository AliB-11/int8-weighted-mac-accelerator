

//fsm for counter to determine addresses for reading Y blocks 
	
	always_ff @(posedge clock or negedge resetn) begin
	if (~resetn) begin
		M2_state <= S_fetch_IDLE;
		fetch_write_en_a <= 1'b0;
 
		
		fetch_address_a <= 8'd0;
		row_block_F <= 5'd0; 
		col_block_F <= 4'd0;
		row_index_F <= 4'd0;
		col_index_F <= 4'd0;
		fetch_write_data_a <= 32'd0;
		fetch_S_Buffer_F <= 16'd0;
		flag_1_F <= 1'd0;
		flag_2_F <= 1'd0;
	end else begin
 
	
		case (M2_state)
		S_fetch_IDLE: begin
			fetch_write_en_a <= 1'b0; //read
			M2_finish_fetch <= 1'b0;
			fetch_S_Buffer_F <= 16'd0;
			SRAM_w_en_M2_fetch <= 1'b1; //read

			if (M2_start_fetch) begin
					M2_state <= Delay; 
			end
		end

		Delay: begin

			if (M2_start_fetch) begin
					M2_state <= S_fetch_0; 
			end
		end

 
		S_fetch_0: begin
		  SRAM_w_en_M2_fetch <= 1'b1; 			
			col_index_F <= col_index_F + 1'b1; //0 
			M2_state <= S_fetch_1;
		end


		S_fetch_1: begin

			col_index_F <= col_index_F + 1'b1; //1

			M2_state <= S_fetch_2;
		end


		S_fetch_2: begin 

			col_index_F <= col_index_F + 1'b1; //2

			M2_state <= S_fetch_3;

		end

		S_fetch_3: begin
 
			
			col_index_F <= col_index_F + 1'b1; //3,5,7,9,11,13,15
		   fetch_S_Buffer_F <= SRAM_read_data; // store first value
			fetch_write_en_a <= 1'b1; //write to DPRAM in the next state
			if(~flag_1_F) begin
				if (col_index_F == 4'd15) begin //wait for 16 columns for Y 
					M2_state <= S_fetch_5; 
				end
			end else begin 
				if (col_index_F == 4'd7) begin
					M2_state <= S_fetch_5; //wait for 8 columns for U and V 
				end
			end
 
			M2_state <= S_fetch_4;

		end

			S_fetch_4: begin 

				col_index_F <= col_index_F + 1'b1; //4,6,8

 
				fetch_write_data_a = {fetch_S_Buffer_F, SRAM_read_data}; 
				fetch_address_a = fetch_address_a + 1;

				fetch_write_en_a <= 1'b0;
				M2_state <= S_fetch_3;
	   	end

		S_fetch_5: begin

			fetch_write_data_a = {fetch_S_Buffer_F, SRAM_read_data}; 
			fetch_address_a = fetch_address_a + 1;

			fetch_write_en_a <= 1'b0;
 
 
			M2_state <= S_fetch_6;

		end
		S_fetch_6: begin 
		  fetch_S_Buffer_F <= SRAM_read_data;  //buffer 14 or 6 
			fetch_write_en_a <= 1'b1; //write to DPRAM in the next state
			M2_state <= S_fetch_7;	
		end

		S_fetch_7: begin 
			fetch_write_data_a = {fetch_S_Buffer_F, SRAM_read_data}; 
			fetch_address_a = fetch_address_a + 1;

			fetch_write_en_a <= 1'b0;
 
 
			M2_state <= S_fetch_8;
		end



		S_fetch_8: begin 
			fetch_write_data_a = {fetch_S_Buffer_F, SRAM_read_data}; //last two values written to DPRAM
			fetch_address_a = fetch_address_a + 1;

			row_index_F <= row_index_F + 1;
			col_index_F <= 4'd0;
			M2_state <= S_fetch_0;

 
			if (~flag_1_F) begin
				if (row_index_F == 4'd15) begin  //if Y block is fetched
					col_block_F <= col_block_F + 1; 
					row_index_F <= 4'd0; 
					M2_finish_fetch <= 1'b1;
					M2_state <= S_fetch_IDLE;	
					if (col_block_F == 4'd11) begin
						row_block_F <= row_block_F + 1;
						col_block_F <= 4'd0;
						if (row_block_F == 5'd8) begin
							flag_1_F <= 1'b1; // all Y blocks are fetched
							row_block_F <= 5'd0; 
						end
					end	
				end	

			end else begin 
			//U and V 
				if (row_index_F == 4'd7) begin //U and V block is fetched
					col_block_F <= col_block_F + 1;
					row_index_F <= 4'd0; 
					M2_finish_fetch <= 1'b1;
					M2_state <= S_fetch_IDLE;	
					if (col_block_F == 4'd11) begin
							row_block_F <= row_block_F + 1;
							col_block_F <= 4'd0;
							if (row_block_F == 5'd8) begin
								flag_2_F <= 1'b1; // all V/U blocks are fetched
								row_block_F <= 5'd0; 
							end
					end
				end
			end

		end

		default: M2_state  <= S_fetch_IDLE;
 
		endcase
	end

 
	end
	















































///*
//Copyright by Henry Ko and Nicola Nicolici
//Department of Electrical and Computer Engineering
//McMaster University
//Ontario, Canada
//*/
//
//
//`timescale 1ns/100ps
//`ifndef DISABLE_DEFAULT_NET
//`default_nettype none
//`endif
//
//`include "define_state.h"
//
//module M2_fetch_S(
//		input logic Clock,		
//		input logic resetn,
//		input logic M2_start_fetch,	
//		input logic [15:0] SRAM_read_data_M2_fetch,
//	
//		output logic [17:0] SRAM_address_M2_fetch,
//		output logic M2_finish_fetch,
//		output logic SRAM_w_en_M2_fetch,
//		output logic fetch_address_a, 
//		output logic fetch_write_en_a,
//		output logic fetch_write_data_a
//		
//);
//
//
//
//logic [7:0] fetch_address_a;
//
//logic [31:0] fetch_write_data_a;	
//
//logic fetch_write_en_a; 	
//
//	
//
//	
//	//create sample counter to read a block of Y from the SRAM. expand usage to U and V planes later
//	
//	parameter Y_IDCT_OFFSET = 18'd27648;
//	
//	parameter U_IDCT_OFFSET = 18'd55296; 
//	
//	parameter V_IDCT_OFFSET = 18'd82943; 
//	
//	
//	logic[3:0] col_block;
//	
//	logic[4:0] row_block;
//	
//	logic flag_1;
//	
//	logic flag_2;
//	
//	
//   logic[3:0] row_index, col_index;
//	
//	logic[15:0] fetch_S_Buffer;
//	
//	
//	
//	M2_fetch_state_type M2_state;
//	
//	
//	//address for Y, U or V blocks 
//
//
//	always_ff @(posedge Clock or negedge resetn) begin 
//	
//		
//	if (~resetn) begin
//	
//		SRAM_address_M2_fetch <= Y_IDCT_OFFSET;
//		
//	end else begin
//		
//		   //16x16 fetch
//			SRAM_address_M2_fetch <= Y_IDCT_OFFSET + col_index + (col_block << 4) + (row_index << 6) + (row_index << 7) +  ((row_block << 6) + (row_block << 7) << 4);
//		
//		if (flag_1) begin
//		
//	    	//8x8 fetch 
//			SRAM_address_M2_fetch <= U_IDCT_OFFSET + col_index + (col_block << 3) +  (row_index << 6) + (row_index << 5) + ( (row_block << 6) + (row_block << 5) >> 3); 
//			
//			if (flag_2) begin 
//
//				SRAM_address_M2_fetch <= V_IDCT_OFFSET + col_index + (col_block << 3) +  (row_index << 6) + (row_index << 5) + ( (row_block << 6) + (row_block << 5) >> 3);
//		
//			end
//		
//		end
//		
//	
//		
//		end
//	
//	end 
//	
//	
//	
//	
//	
//	//fsm for counter to determine addresses for reading Y blocks 
//	
//	always_ff @(posedge Clock or negedge resetn) begin
//	
//	if (~resetn) begin
//		M2_state <= S_fetch_IDLE;
//	
//		fetch_write_en_a <= 1'b0;
//
//		
//		fetch_address_a <= 8'd0;
//		
//		row_block <= 5'd0; 
//		col_block <= 4'd0;
//		
//		row_index <= 4'd0;
//		col_index <= 4'd0;
//		
//		fetch_write_data_a <= 32'd0;
//		fetch_S_Buffer <= 16'd0;
//		
//		flag_1 <= 1'd0;
//		flag_2 <= 1'd0;
//		
//	end else begin
//
//	
//		case (M2_state)
//		S_fetch_IDLE: begin
//		
//			fetch_write_en_a <= 1'b0; //read
//			M2_finish_fetch <= 1'b0;
//			fetch_S_Buffer <= 16'd0;
//			SRAM_w_en_M2_fetch <= 1'b1; //read
//		
//			
//			
//			if (M2_start_fetch) begin
//					M2_state <= Delay; 
//			end
//			
//		end
//		
//		
//		Delay: begin
//		
//			
//			if (M2_start_fetch) begin
//					M2_state <= S_fetch_0; 
//			end
//		
//		end
//		
//		
//
//		S_fetch_0: begin
//		
//		  SRAM_w_en_M2_fetch <= 1'b1; 			
//			col_index <= col_index + 1'b1; //0 
//			M2_state <= S_fetch_1;
//		
//		end
//		
//		
//		
//		
//		S_fetch_1: begin
//		
//			
//			col_index <= col_index + 1'b1; //1
//			
//		
//			M2_state <= S_fetch_2;
//		end
//		
//		
//		
//		
//		
//		S_fetch_2: begin 
//		
//			
//			
//			col_index <= col_index + 1'b1; //2
//			
//		
//			M2_state <= S_fetch_3;
//		
//	
//		end
//		
//		
//		
//		S_fetch_3: begin 
//
//			
//			col_index <= col_index + 1'b1; //3,5,7,9,11,13,15
//			
//		   fetch_S_Buffer <= SRAM_read_data_M2_fetch; // store first value
//			
//			fetch_write_en_a <= 1'b1; //write to DPRAM in the next state
//			
//			if(~flag_1) begin
//				if (col_index == 4'd15) begin //wait for 16 columns for Y 
//					M2_state <= S_fetch_5; 
//				end
//			end else begin 
//				if (col_index == 4'd7) begin
//					M2_state <= S_fetch_5; //wait for 8 columns for U and V 
//				end
//			end 
//
//			M2_state <= S_fetch_4;
//			
//		
//		end
//		
//		
//			S_fetch_4: begin 
//			
//		
//				col_index <= col_index + 1'b1; //4,6,8
//				
//
//				fetch_write_data_a = {fetch_S_Buffer, SRAM_read_data_M2_fetch}; 
//				fetch_address_a = fetch_address_a + 1;
//				
//				
//				fetch_write_en_a <= 1'b0;
//				M2_state <= S_fetch_3;
//				
//	   	end
//		
//		
//		S_fetch_5: begin
//			
//			
//			fetch_write_data_a = {fetch_S_Buffer, SRAM_read_data_M2_fetch}; 
//			fetch_address_a = fetch_address_a + 1;
//			
//			
//			fetch_write_en_a <= 1'b0;
//
//
//			M2_state <= S_fetch_6;
//			
//		
//		end
//		
//		S_fetch_6: begin 
//			
//		   fetch_S_Buffer <= SRAM_read_data_M2_fetch;  //buffer 14 or 6 
//			
//			fetch_write_en_a <= 1'b1; //write to DPRAM in the next state
//			
//			M2_state <= S_fetch_7;	
//			
//		end
//		
//		
//		S_fetch_7: begin 
//		
//			fetch_write_data_a = {fetch_S_Buffer, SRAM_read_data_M2_fetch}; 
//			fetch_address_a = fetch_address_a + 1;
//			
//			
//			fetch_write_en_a <= 1'b0;
//
//
//			M2_state <= S_fetch_8;
//			
//		end
//		
//		
//		
//		
//		
//		
//		
//		S_fetch_8: begin 
//			
//			fetch_write_data_a = {fetch_S_Buffer, SRAM_read_data_M2_fetch}; //last two values written to DPRAM
//			fetch_address_a = fetch_address_a + 1;
//			
//			
//			row_index <= row_index + 1;
//			col_index <= 4'd0;
//			
//			M2_state <= S_fetch_0;
//			
//
//			if (~flag_1) begin
//			
//				if (row_index == 4'd15) begin  //if Y block is fetched
//					col_block <= col_block + 1; 
//					row_index <= 4'd0; 
//					
//					M2_finish_fetch <= 1'b1;
//					M2_state <= S_fetch_IDLE;	
//					
//					if (col_block == 4'd11) begin
//						row_block <= row_block + 1;
//						col_block <= 4'd0;
//						
//						if (row_block == 5'd8) begin
//							flag_1 <= 1'b1; // all Y blocks are fetched
//							row_block <= 5'd0; 
//						end
//					end	
//				end	
//		
//		
//			end else begin 
//			
//			//U and V 
//				
//				if (row_index == 4'd7) begin //U and V block is fetched
//					col_block <= col_block + 1;
//					row_index <= 4'd0; 
//					
//					M2_finish_fetch <= 1'b1;
//					M2_state <= S_fetch_IDLE;	
//					
//					if (col_block == 4'd11) begin
//							row_block <= row_block + 1;
//							col_block <= 4'd0;
//							
//							if (row_block == 5'd8) begin
//								flag_2 <= 1'b1; // all V/U blocks are fetched
//								row_block <= 5'd0; 
//							end
//							
//					end
//					
//				end
//			
//			end
//			
//			
//			
//				
//		end
//		
//	
//		default: M2_state  <= S_fetch_IDLE;
//
//		endcase
//	end
//	
//
//	end
//	
//	endmodule
//	
//	