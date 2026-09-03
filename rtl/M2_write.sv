/*
Copyright by Henry Ko and Nicola Nicolici
Department of Electrical and Computer Engineering
McMaster University
Ontario, Canada
*/


`timescale 1ns/100ps
`ifndef DISABLE_DEFAULT_NET
`default_nettype none
`endif

`include "define_state.h"

module M2_write(
		input logic Clock,		
		input logic resetn,
		input logic M2_start_write,
		input logic read_data_a,
		
		
		
		output logic [17:0] SRAM_address_M2_write,
		output logic M2_finish_write,
		output logic SRAM_w_en_M2_write, 
		output logic [15:0] SRAM_write_data_M2_write, 
		
		output logic address_a_M2_write
	
);



	logic[7:0] address_a_M2_write;

	
	parameter U_OFFSET = 18'd13824; 
	 
	parameter V_OFFSET = 18'd20736; 
	
	
	
	logic[3:0] col_block;
	
	logic[4:0] row_block;
	
	logic flag_1; //U block
	
	logic flag_2; //V block
	
	logic [4:0] row_block_amount;
	
	logic [3:0] col_amount, row_amount;
	
	assign col_amount = flag_1 ? 4'd3 : 4'd7;
	
	assign row_amount = flag_1 ? 4'd7 : 4'd15;
	
	assign row_block_amount = flag_1 ? 5'd17 : 5'd8; // either 18 or 9 row blocks 
	
   logic[3:0] row_index, col_index;
	
	logic[31:0] fetch_S_Buffer;
	
	logic[7:0] clip_1; 
	
	logic[7:0] clip_2;
	
	logic[5:0] offset;
	
	
	
	M2_fetch_state_type M2_state;
	
	
	//address for Y, U or V blocks 


	always_ff @(posedge Clock or negedge resetn) begin 
	
		
	if (~resetn) begin
	
		SRAM_address_M2_write <= 18'd0;
		
	end else begin
		
		   //16x16 fetch
			SRAM_address_M2_write <= col_index + (col_block << 3) + (row_index << 6) + (row_index << 5) +  ((row_block << 6) + (row_block << 5) << 4);
		
		if (flag_1) begin
		
	    	//8x8 fetch 
			SRAM_address_M2_write <= U_OFFSET + col_index + (col_block << 2) +  (row_index << 5) + (row_index << 4) + ( (row_block << 4) + (row_block << 5) >> 3); 
			
			if (flag_2) begin 

				SRAM_address_M2_write <= V_OFFSET + col_index + (col_block << 2) +  (row_index << 5) + (row_index << 4) + ( (row_block << 4) + (row_block << 5) >> 3);
		
			end
		
		end
		
	
		
		end
	
	end 
	
	
	//fsm for counter to determine addresses for reading Y blocks 
	
	always_ff @(posedge Clock or negedge resetn) begin
	
	if (~resetn) begin
		M2_state <= S_write_IDLE;
		
		SRAM_w_en_M2_write <= 1'b1; //active low so set to read first
//		write_en_a <= 1'b0; 
	
		address_a <= 8'd0;

		row_block <= 5'd0; 
		col_block <= 4'd0;
		
		row_index <= 4'd0;
		col_index <= 4'd0;
		
		read_data_a <= 32'd0;
		fetch_S_Buffer1 <= 32'd0;
		
		offset <= 6'd0;
		
		flag_1 <= 1'd0;
		flag_2 <= 1'd0;
		
	end else begin

	
		case (M2_state)
		S_write_IDLE: begin
		
			M2_finish_fetch <= 1'b0;
			fetch_S_Buffer <= 32'd0;
			SRAM_w_en_M2_write <= 1'b1; //read
			row_index <= 4'd0;
		   col_index <= 4'd0;
	
			
			if (M2_start_fetch) begin
					M2_state <= S_Delay; 
			end
			
		end
		
		
		S_Delay: begin
		
			
			if (M2_start_fetch) begin
					M2_state <= S_write_0; 
			end
		
		end
		
		

		S_write_0: begin
		
		   SRAM_w_en_M2_write <= 1'b1; 	//sram read	
			write_en_a <= 1'b0; //reading from DPRAM
			M2_state <= S_write_1;
		
		
		end
		
		
		
		
		S_write_1: begin
		
			fetch_S_buffer <= read_data_a; //buffer Y0
			
			address_a <= address_a + 4'd8 + offset; //address Y1
			
		
			M2_state <= S_write_2;
		end
		
		
		S_write_2: begin
			address_a <= address_a + 4'd8 + offset; //address Y2
			M2_state <= S_write_3;
		end
		
		
		
		
		
		S_write_3: begin 
		
			//write values to SRAM
			
			SRAM_w_en_M2_write <= 1'b0; 	//sram write
			
			SRAM_write_data_M2_write <= {clip_2, clip_1}; 
			
			col_index <= col_index + 1; //increment sram address //0,2
			
			M2_state <= S_write_3;
			
			address_a <= address_a + 4d'8 + offset; //address Y3
			
		
	
		end
		
		
		
		S_write_3: begin 
		
		
			SRAM_w_en_M2_write <= 1'b1; 
			
			fetch_S_buffer <= read_data_a; //buffer Y2 
			
			
			M2_state <= S_write_4;
			
		
		end
		
		
		S_write_4: begin 
		
	
			SRAM_w_en_M2_write <= 1'b0; 	//sram write
			
			SRAM_write_data_M2_write <= {clip_2, clip_1};  
			
			col_index <= col_index + 1; //increment sram address //1,3
			
			address_a <= address_a + 4'd8 + offset; //address Y4
			
			M2_state <= S_write_0;
			
			//check depending on Y or U/V block to determine how many times to repeat 
			
			if (col_index == col_amount) begin //if 3
				col_index <= 4'd0; //set 0
				row_index <= row_index + 1; 
				offset <= offset + 1;
				
				if (row_index == row_amount) begin //if all rows are done
				   M2_finish_write <= 1'b1;
					offset <= 5'd0;
					address_a <= 8'd0;
					M2_state <= S_write_IDLE;
					col_block <= col_block + 1;
					row_index <= 4'd0;
					
					if (col_block == 4'd11) begin
					row_block <= row_block + 1;
					col_block <= 4'd0;
					
					if (row_block == row_block_amount) begin
						row_block <= 5'd0; 
						flag_1 <= 1'b1; // U block
						if (flag_1) begin
							flag_2 <= 1'b1; // V block
						end
					end	
					end

				end
				
			end
			
			
			
		end
	
	
				
		end
		
	
		default: M2_state  <= S_write_IDLE;

		endcase
		
	end
	

	end
	
	
	//clipping and scaling 
	
	
	always_comb begin
		if (read_data_a[31] == 1'b1) clip_1 = 0;
		else if(|read_data_a[30:21] == 1'b1) clip_1 = 8'd255;
		else clip_1 = read_data_a[20:13];
	end
	
	
	always_comb begin
		if (fetch_S_buffer[31] == 1'b1) clip_2 = 0;
		else if(|fetch_S_buffer[30:21] == 1'b1) clip_2 = 8'd255;
		else clip_2 = fetch_S_buffer[20:13];
	end
	
	
	

endmodule 