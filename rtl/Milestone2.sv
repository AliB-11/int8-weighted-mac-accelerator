



`timescale 1ns/100ps
`ifndef DISABLE_DEFAULT_NET
`default_nettype none
`endif

`include "define_state.h"


// add wires needed from project file 
//module instantiation 

module Milestone2 ( 
   input  logic            clock,
   input  logic            resetn,
	input  logic            start_signal, //input logic to start milestone 2 code
	input  logic   [15:0]   SRAM_read_data,
	
	
   output logic   [17:0]   SRAM_address,
	output logic   [15:0]   SRAM_write_data,
	output logic            SRAM_w_en,
	output logic            end_signal 	//output logic to declare milestone 2 is complete 
   
);


logic M2_start_fetch, M2_finish_fetch;
logic M2_start_Ct, M2_finish_Ct;
logic M2_start_Cs, M2_finish_Cs; 
logic M2_start_write, M2_finish_write;

//SRAM intializations

logic[17:0] SRAM_address_M2_fetch;
logic[17:0] SRAM_address_M2_write;

logic[15:0] SRAM_write_data_M2_write;

logic SRAM_w_en_M2_fetch;
logic SRAM_w_en_M2_write;



logic [9:0] block_counter;


logic mode; //flag used to determine whether computing Y or U/V blocks

logic start;



//DPRAM intializations

logic [7:0] address_a [3:0];  //256 locations so 8 bits required for address a and b 
logic [7:0] address_b [3:0];
	
logic [31:0] write_data_a [3:0]; 
logic [31:0] write_data_b [3:0];  //32 bits of data 
	
logic [31:0] read_data_a [3:0]; 
logic [31:0] read_data_b [3:0];

logic write_enable_a [3:0];
logic write_enable_b [3:0]; 	





	//Ram_S
	
	dual_port_s RAM_inst0 (
		.address_a ( address_a[0] ),
		.address_b ( address_b[0] ),
		.clock ( clock ),
		.data_a ( write_data_a[0] ),
		.data_b ( write_data_b[0] ),
		.wren_a (write_enable_a[0]),
		.wren_b ( write_enable_b[0]),
		.q_a ( read_data_a[0] ),
		.q_b ( read_data_b[0] )
		);
		

	// instantiate RAM_C

	dual_port_C RAM_inst1 (
		.address_a ( address_a[1] ),
		.address_b ( address_b[1] ),
		.clock ( clock ),
		.data_a ( write_data_a[1] ),
		.data_b ( write_data_b[1] ),
		.wren_a ( write_enable_a[1] ),
		.wren_b ( write_enable_b[1] ),
		.q_a ( read_data_a[1] ),
		.q_b ( read_data_b[1] )
		);
		
		// instantiate RAM_T
		
	dual_port_T RAM_inst2 (
		.address_a ( address_a[2] ),
		.address_b ( address_b[2] ),
		.clock ( clock ),
		.data_a ( write_data_a[2] ),
		.data_b ( write_data_b[2] ),
		.wren_a ( write_enable_a[2] ),
		.wren_b ( write_enable_b[2] ),
		.q_a ( read_data_a[2] ),
		.q_b ( read_data_b[2] )
		);
		
		
		
			// instantiate RAM_Cs
		
	dual_port_Cs RAM_inst3 (
		.address_a ( address_a[3] ),
		.address_b ( address_b[3] ),
		.clock ( clock ),
		.data_a ( write_data_a[3] ),
		.data_b ( write_data_b[3] ),
		.wren_a ( write_enable_a[3] ),
		.wren_b ( write_enable_b[3] ),
		.q_a ( read_data_a[3] ),
		.q_b ( read_data_b[3] )
		);
		

//DPRAM registers for fetch 

logic [7:0] fetch_address_a;  //DPRAM_S
logic fetch_write_en_a;
logic [31:0] fetch_write_data_a;


//DPRAM regisers for write 




//DPRAM regisers for Ct 

logic [7:0] Ct_address_a[2:0];  //DPRAM for addresses C,S and T
logic [7:0] Ct_address_b[2:0];
 
logic Ct_w_en_a;
logic Ct_w_en_b;

logic [31:0] Ct_write_data_a; //DPRAM for writing to T
logic [31:0] Ct_write_data_b;




//DPRAM registers for Cs

logic [7:0] Cs_address_a[2:0];  //DPRAM for addresses C,S and T
logic [7:0] Cs_address_b[2:0];


logic Cs_w_en_a;
logic Cs_w_en_b;

logic [31:0] Cs_write_data_a; //DPRAM for writing to Cs
logic [31:0] Cs_write_data_b; 



	logic [31:0] mult_op_1_1, mult_op_1_2, mult_op_2_1, mult_op_2_2, mult_op_3_1 , mult_op_3_2;

	logic [63:0] Mult_result_long_1, Mult_result_long_2, Mult_result_long_3; //do we need this again?
	
	logic [31:0] Mult_result_1, Mult_result_2, Mult_result_3;
	
	
	assign Mult_result_long_1 = mult_op_1_1 * mult_op_1_2; 

	assign Mult_result_long_2 = mult_op_2_1 * mult_op_2_2;

	assign Mult_result_long_3 = mult_op_3_1 * mult_op_3_2; 
	
	
	assign Mult_result_1 = Mult_result_long_1[31:0];

	assign Mult_result_2 = Mult_result_long_2[31:0];

	assign Mult_result_3 = Mult_result_long_3[31:0];
	
	
	
	logic [31:0] mult_op_1_1_Cs, mult_op_1_2_Cs, mult_op_2_1_Cs, mult_op_2_2_Cs, mult_op_3_1_Cs , mult_op_3_2_Cs;
	
	
	logic [31:0] mult_op_1_1_Ct, mult_op_1_2_Ct, mult_op_2_1_Ct, mult_op_2_2_Ct, mult_op_3_1_Ct , mult_op_3_2_Ct;
	
	
	logic [31:0] accum_1_Cs, accum_2_Cs, accum_3_Cs, accum_3_buf_Cs;
	
	
	//CS
	logic flag_1_Cs;
	
	logic  [2:0] col_counter_Cs;
	
	logic  iteration_Cs; 
	
	logic  [7:0] e_counter_Cs;
	
	
	//CT
	
	logic [31:0] accum_1, accum_2, accum_3, accum_3_buf; 
	
	logic Ct_flag_1;
	
	logic  [2:0] col_counter;
	
	logic  iteration;  //mode
	
	logic  [7:0] e_counter;
	
	
	
	//write
	
	logic[7:0] address_a_M2_write;

	
	parameter U_OFFSET = 18'd13824; //4
	 
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
	
	logic[31:0] fetch_S_buffer;
	
	logic[7:0] clip_1; 
	
	logic[7:0] clip_2;
	
	logic[5:0] offset;
	
	
	
	
	
	//fetch
	
	parameter Y_IDCT_OFFSET = 18'd27648;
	
	parameter U_IDCT_OFFSET = 18'd55296; 
	
	parameter V_IDCT_OFFSET = 18'd69120; 
	
	
	logic[3:0] col_block_F;
	
	logic[4:0] row_block_F;
	
	logic flag_1_F;
	
	logic flag_2_F;
	
	
   logic[3:0] row_index_F, col_index_F;
	
	logic[15:0] fetch_S_Buffer_F;
	
	
	
		M2_driver_state_type state;
	
	
		
	//choosing which signals drive the DPRAM Ports
	
	always_comb begin
			
			//default
			address_a[0] = 8'd0;
			address_a[1] = 8'd0;
			address_a[2] = 8'd0;
			address_a[3] = 8'd0;
			address_b[0] = 8'd0;
			address_b[1] = 8'd0;
			address_b[2] = 8'd0;
			address_b[3] = 8'd0;
			
			write_enable_a[0] = 1'b0;
			write_enable_b[0] = 1'b0;
			write_enable_a[1] = 1'b0;
			write_enable_b[1] = 1'b0;
			write_enable_a[2] = 1'b0;
			write_enable_b[2] = 1'b0;
			write_enable_a[3] = 1'b0;
			write_enable_b[3] = 1'b0;
			
			write_data_a[0] = 32'd0;
			write_data_b[0] = 32'd0;
			write_data_a[1] = 32'd0;
			write_data_b[1] = 32'd0;
			write_data_a[2] = 32'd0;
			write_data_b[2] = 32'd0;
			write_data_a[3] = 32'd0;
			write_data_b[3] = 32'd0;
			
			
			mult_op_1_1 = 32'd0;
			mult_op_1_2 = 32'd0;
			mult_op_2_1 = 32'd0;
			mult_op_2_2 = 32'd0;
			mult_op_3_1 = 32'd0;
			mult_op_3_2 = 32'd0;
			
		if (state == S_M2_fetch_LI) begin
			address_a[0] = fetch_address_a;
			write_enable_a[0] = fetch_write_en_a;
			write_data_a[0] = fetch_write_data_a;
		
		end
		
		if (state == S_M2_Ct_LI) begin 
		
			address_a[0] = Ct_address_a[0];
			address_a[1] = Ct_address_a[1];
			address_a[2] = Ct_address_a[2];
			
			address_b[0] = Ct_address_b[0];
			address_b[1] = Ct_address_b[1];
			address_b[2] = Ct_address_b[2];
			
			write_enable_a[2] = Ct_w_en_a;
			write_enable_b[2] = Ct_w_en_b;
	
			write_data_a[2] = Ct_write_data_a;
			write_data_b[2] = Ct_write_data_b;
			
					
			mult_op_1_1 = mult_op_1_1_Ct;
			mult_op_1_2 = mult_op_1_2_Ct;
			mult_op_2_1 = mult_op_2_1_Ct;
			mult_op_2_2 = mult_op_2_2_Ct;
			mult_op_3_1 = mult_op_3_1_Ct;
			mult_op_3_2 = mult_op_3_2_Ct;
		end
			
		
		
		if ((state == S_M2_CC1)) begin
			
			address_a[0] = fetch_address_a;
			write_enable_a[0] = fetch_write_en_a;
			write_data_a[0] = fetch_write_data_a;
				
			address_a[1] = Cs_address_a[0];
			address_a[2] = Cs_address_a[1];
			address_a[3] = Cs_address_a[2];
			
			address_b[1] = Cs_address_b[0];
			address_b[2] = Cs_address_b[1];
			address_b[3] = Cs_address_b[2];
//			
//			Cs_read_data_a[0] = read_data_a[1]; //input
//			Cs_read_data_a[1] = read_data_a[2];

			write_enable_a[3] = Cs_w_en_a;
			write_enable_b[3] = Cs_w_en_b;
			
			write_data_a[3] = Cs_write_data_a;
			write_data_b[3] = Cs_write_data_b;
			
			mult_op_1_1 = mult_op_1_1_Cs;
			mult_op_1_2 = mult_op_1_2_Cs;
			mult_op_2_1 = mult_op_2_1_Cs;
			mult_op_2_2 = mult_op_2_2_Cs;
			mult_op_3_1 = mult_op_3_1_Cs;
			mult_op_3_2 = mult_op_3_2_Cs;
			
			
		end
		
		
		if ((state == S_M2_CC2)) begin
		
			address_a[0] = Ct_address_a[0];
			address_a[1] = Ct_address_a[1];
			address_a[2] = Ct_address_a[2];
			
			address_b[0] = Ct_address_b[0];
			address_b[1] = Ct_address_b[1];
			address_b[2] = Ct_address_b[2];
			
//			Ct_read_data_a[0] = read_data_a[0]; //input
//			Ct_read_data_a[1] = read_data_a[1];
//			
//			Ct_read_data_b[0] = read_data_b[0];
//			Ct_read_data_b[1] = read_data_b[1];
			
			write_enable_a[2] = Ct_w_en_a;
			write_enable_b[2] = Ct_w_en_b;
	
			write_data_a[2] = Ct_write_data_a;
			write_data_b[2] = Ct_write_data_b;
		
			address_a[3] = address_a_M2_write;
		

			
			mult_op_1_1 = mult_op_1_1_Ct;
			mult_op_1_2 = mult_op_1_2_Ct;
			mult_op_2_1 = mult_op_2_1_Ct;
			mult_op_2_2 = mult_op_2_2_Ct;
			mult_op_3_1 = mult_op_3_1_Ct;
			mult_op_3_2 = mult_op_3_2_Ct;
		
		end
		
		
		if (state == S_M2_Cs_LO) begin 
			mult_op_1_1 = mult_op_1_1_Cs;
			mult_op_1_2 = mult_op_1_2_Cs;
			mult_op_2_1 = mult_op_2_1_Cs;
			mult_op_2_2 = mult_op_2_2_Cs;
			mult_op_3_1 = mult_op_3_1_Cs;
			mult_op_3_2 = mult_op_3_2_Cs;
			
			address_a[1] = Cs_address_a[0];
			address_a[2] = Cs_address_a[1];
			address_a[3] = Cs_address_a[2];
			
			address_b[1] = Cs_address_b[0];
			address_b[2] = Cs_address_b[1];
			address_b[3] = Cs_address_b[2];
//			
//			Cs_read_data_a[0] = read_data_a[1]; //input
//			Cs_read_data_a[1] = read_data_a[2];

			write_enable_a[3] = Cs_w_en_a;
			write_enable_b[3] = Cs_w_en_b;
			
			write_data_a[3] = Cs_write_data_a;
			write_data_b[3] = Cs_write_data_b;	
		end
		
		if (state == S_M2_Write_LO) begin 
			address_a[3] = address_a_M2_write;
		end	
					
	end
	
	

	
	
	//M2_driver_state_type state;

	
	always_ff @ (posedge clock or negedge resetn) begin
	if (resetn == 1'b0) begin	
		
		M2_start_fetch <= 1'b0; 
		M2_start_Ct <= 1'b0; 
		M2_start_Cs <= 1'b0; 
		M2_start_write <= 1'b0; 
		end_signal <= 1'b0;
		
		
		mode <= 1'b0;
  
      state <= S_M2_IDLE;


      block_counter <= 10'd0;
	
      start  <= 1'b0;


	
		
	end else begin
		case (state)

		S_M2_IDLE: begin
			M2_start_fetch <= 1'b0; 
			M2_start_Ct <= 1'b0; 
			M2_start_Cs <= 1'b0; 
			M2_start_write <= 1'b0; 
			start <= 1'b0;
			mode <= 1'b0;
			block_counter <= 10'd0;
			end_signal <= 1'b0;
			
			
			
			if (start_signal && (end_signal == 1'b0)) begin
				state <= S_M2_fetch_LI;
			end
		end
		
		

		S_M2_fetch_LI: begin
		
			M2_start_fetch <= 1'b1; 
			
			if (M2_finish_fetch) begin
				
				M2_start_fetch <= 1'b0;
				
				//M2_finish_fetch <= 1'b0;

				block_counter <= block_counter + 1;
				
				
				
				M2_start_Ct <= 1'b1;
				
				state <= S_M2_Ct_LI;
				
			end	
		end	
		
		

		S_M2_Ct_LI: begin
		
		M2_start_Ct <= 1'b1; 
			
			if (M2_finish_Ct) begin
				M2_start_Ct <= 1'b0;
				//M2_finish_Ct <= 1'b0;
			
			state <= S_M2_CC1;   //CHANGE LATER WE WILL GO TO lead out states to test 1 block instead 
			//state <= S_M2_Cs_LO;
			
			
			end	
		end
		
		
		

		S_M2_CC1: begin   //we fetch 2nd block we compute S
			
			if(!start) begin
				M2_start_Cs <= 1'b1;
				M2_start_fetch <= 1'b1;
				start <= 1'b1;
			end
			
			if(M2_finish_fetch) begin
				M2_start_fetch <= 1'b0;
				
			end

			if(M2_finish_Cs) begin
				M2_start_Cs <= 1'b0;
//				end_signal <= 1'b1;
			end

			if (M2_finish_Cs) begin //M2_finish_fetch && M2_finish_Cs
				
				if (~mode) begin
				
					if (block_counter == 10'd108) begin //fetched first U block (block #109)
						mode <= 1'b1;
					end
					
				end
				
//				M2_finish_fetch <= 1'b0;
//				M2_finish_Cs <= 1'b0;

				block_counter <= block_counter + 1;
				start <= 1'b0;
				state <= S_M2_CC2;
				
			end
		end
		
		

		S_M2_CC2: begin //we write 1st block and we compute T for the second block
			if(!start) begin
				M2_start_Ct <= 1'b1;
				M2_start_write <= 1'b1;
				start <= 1'b1;
			end

			if(M2_finish_Ct) begin
				M2_start_Ct <= 1'b0;
				
			end

			if(M2_finish_write) begin
				M2_start_write <= 1'b0;
				if (block_counter == 10'd109) begin 
					start <= 1'b0;
					state <= S_M2_CC1;
				end
				
			end 
			
			if (M2_finish_Ct) begin //M2_finish_Ct && M2_finish_write
//				M2_finish_write <= 1'b0;
//				M2_finish_Ct <= 1'b0;
				if(block_counter == 10'd540) begin //finished fetching all blocks, do final compute and write
					state <= S_M2_Cs_LO;
				end else begin
					if (block_counter != 10'd109) begin 
						start <= 1'b0;
						state <= S_M2_CC1;		
					end
					
				end
				
			end
		end
		
		
		

		S_M2_Cs_LO: begin
			M2_start_Cs <= 1'b1;
			if (M2_finish_Cs) begin
				M2_start_Cs <= 1'b0;
				state <= S_M2_Write_LO;
			end	
		end

		
		
		
		S_M2_Write_LO: begin
			M2_start_write <= 1'b1;
			if (M2_finish_write) begin
				end_signal <= 1'b1; 
				state <= S_M2_IDLE;
			end	
		end		

		endcase
   end
end



M2_fetch_state_type M2_state;


//fetching


always_comb  begin 
	
		
		if (flag_1_F) begin
		
	    	//8x8 fetch 
			SRAM_address_M2_fetch = U_IDCT_OFFSET + col_index_F + (col_block_F << 3) +  (row_index_F << 6) + (row_index_F << 5) + ( (row_block_F << 6) + (row_block_F << 5) << 3); 
			
			if (flag_2_F) begin 

				SRAM_address_M2_fetch = V_IDCT_OFFSET + col_index_F + (col_block_F << 3) +  (row_index_F << 6) + (row_index_F << 5) + ( (row_block_F << 6) + (row_block_F << 5) << 3);
		
			end
		
		end else begin 
		 //16x16 fetch
			SRAM_address_M2_fetch = Y_IDCT_OFFSET + col_index_F + (col_block_F << 4) + (row_index_F << 6) + (row_index_F << 7) +  ((row_block_F << 6) + (row_block_F << 7) << 4);
		
		end
		
		end
		
logic first_run; 
	
	
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
		first_run <= 1'd0;
		
	end else begin
 
	
		case (M2_state)
		S_fetch_IDLE: begin
			fetch_write_en_a <= 1'b0; //read
			fetch_S_Buffer_F <= 16'd0;
			SRAM_w_en_M2_fetch <= 1'b1; //read
			fetch_address_a <= 8'd0;
			first_run <= 1'd0;
			M2_finish_fetch <= 1'b0;

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
			fetch_write_en_a <= 1'b0; 
 		  
			col_index_F <= col_index_F; 
			M2_state <= S_fetch_1;
		end


		S_fetch_1: begin

			col_index_F <= col_index_F + 1'b1; //0

			M2_state <= S_fetch_2;
		end


		S_fetch_2: begin 

			col_index_F <= col_index_F + 1'b1; //1

			M2_state <= S_fetch_3;

		end

		S_fetch_3: begin
 
			
			col_index_F <= col_index_F + 1'b1; //2,4,8
		   fetch_S_Buffer_F <= SRAM_read_data; // store first value
			fetch_write_en_a <= 1'b0; //read DPRAM
			M2_state <= S_fetch_4;	
			
			end

			S_fetch_4: begin 

				col_index_F <= col_index_F + 1'b1; //3,5,7,9,11,13,15

 
				fetch_write_data_a <= {fetch_S_Buffer_F, SRAM_read_data}; 
				
				if (~first_run) begin
					fetch_address_a <= 8'd0;
					first_run <= 1'b1;
				end else begin
				fetch_address_a <= fetch_address_a + 1;
				end
				
				fetch_write_en_a <= 1'b1; //write to DPRAM
				
					if(~flag_1_F) begin
					if (col_index_F == 4'd15) begin //wait for 16 columns for Y 
						M2_state <= S_fetch_5; 
					end else begin
						M2_state <= S_fetch_3;
					end
				end else begin 
					if (col_index_F == 4'd7) begin
						M2_state <= S_fetch_5; //w		M2_state <= S_fetch_0;ait for 8 columns for U and V 
					end else begin
						M2_state <= S_fetch_3;
					end

				end
			
				
	   	end

		S_fetch_5: begin


			
			fetch_S_Buffer_F <= SRAM_read_data;  //buffer 14 or 6 
			fetch_write_en_a <= 1'b0; //write to DPRAM in the next state

 
			M2_state <= S_fetch_6;

		end
		
		
		S_fetch_6: begin 
		  	fetch_write_data_a <= {fetch_S_Buffer_F, SRAM_read_data}; 
			fetch_address_a <= fetch_address_a + 1;
			fetch_write_en_a <= 1'b1;
			M2_state <= S_fetch_7;	
		end
		
		

		S_fetch_7: begin 
			
	
			row_index_F <= row_index_F + 1;
			col_index_F <= 4'd0;
			fetch_write_en_a <= 1'b0;
 
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
				end else begin 
						M2_state <= S_fetch_0;
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
							if (row_block_F == 5'd17) begin
								flag_2_F <= 1'b1; // all V/U blocks are fetched
								row_block_F <= 5'd0; 
							end
					end
				end else begin
					M2_state <= S_fetch_0;
				end
			end

		end

		default: M2_state  <= S_fetch_IDLE;
 
		endcase
	end

 
	end
	
	
M2_Ct_state_type M2_state_1;


always_ff @(posedge clock or negedge resetn) begin
	
		if(!resetn) begin 
		
		Ct_flag_1 <= 1'b0; //flag 1 is set to zero when we are doing the very first block of Y/U/V
		col_counter <= 3'b0; //checks whether we are computing for 3 T values or 2 T values
		iteration <= 1'b0; //only matters for Y blocks as it needs to go through the state structure twice per value 
		e_counter <= 8'b0;
		Ct_address_a[1] <= 8'b0;
		Ct_address_b[1] <= 8'd96;
		Ct_address_a[0] <= 8'b0;
		Ct_address_b[0] <= 8'b0;
		Ct_address_a[2] <= 8'b0;
		Ct_address_b[2] <= 8'b1;
		Ct_w_en_a <= 1'b0;
		Ct_w_en_b <= 1'b0; 
		M2_finish_Ct <= 1'b0;
		mult_op_1_1_Ct <=  32'd0;
		mult_op_2_1_Ct <= 32'd0;
		mult_op_3_1_Ct <= 32'd0;
		mult_op_1_2_Ct <=  32'd0;
		mult_op_2_2_Ct <= 32'd0;
		mult_op_3_2_Ct <= 32'd0;
		
		Ct_write_data_a <= 32'd0;
		Ct_write_data_b <= 32'd0;
		
		M2_state_1 <= S_CT_IDLE;
		
		end else begin
		//F,T,SF,TW,SF,TW,SF,TW,......TW,S,W
		//States for Fetching and storing whatever (Y,U/V) 
		
		//Last state in fetching: Set address_a and address_b for inst_a = to specific values (0 and 1)
		
		//Fetching Completed 
		//Move to Computing T 
		
		case(M2_state_1)
		S_CT_IDLE: begin 
		
		
		iteration <= 1'b0;
		e_counter <= 8'b0;
		Ct_flag_1 <= 1'b0;
		col_counter <= 3'b0;
		Ct_address_a[1] <= 8'b0;
		Ct_address_b[1] <= 8'd96;
		Ct_address_a[0] <= 8'b0;
		Ct_address_b[0] <= 8'b0;
		Ct_address_a[2] <= 8'b0;
		Ct_address_b[2] <= 8'b1;
		Ct_w_en_a <= 1'b0;
		Ct_w_en_b <= 1'b0; 
		M2_finish_Ct <= 1'b0;
		accum_1 <= 32'd0;
		accum_2 <= 32'd0;
		accum_3 <= 32'd0;
		accum_3_buf <= 32'd0;
		
		
		if(M2_start_Ct == 1'b1)begin
		M2_state_1 <= S_CT_DELAY;
		end 
		
		end
		
		S_CT_DELAY: begin
		
		if(M2_start_Ct == 1'b1)begin
		M2_state_1 <= S_LI_T;
		end 
		
		end
		
		S_LI_T: begin //Delay State 
		
		Ct_address_a[1] <= 8'b1;
		Ct_address_b[1] <= 8'd97;
		
		M2_state_1 <= S_CT_0;
		
		
		end
		
		
		S_CT_0: begin 
	
		//C00C01,C02C03,C04C05,C06C07,C08C09,C10C11,C12C13,C14C15,
		//C16C17,C18C19
		
		//We receive data from address 0 (inst_0) here 
		//We receive data from address 0 and address 1 (inst_1 RAM_C) from here 
		mult_op_1_1_Ct <= $signed(read_data_a[0][31:16]); //Y0, Y16
		mult_op_2_1_Ct <= $signed(read_data_a[0][31:16]); //Y0 
		mult_op_3_1_Ct <= $signed(read_data_a[0][31:16]); //Y0 
		
		if(mode == 1'b0) begin
		mult_op_1_2_Ct <= $signed(read_data_a[1][29:20]);//C0,0 
		mult_op_2_2_Ct <= $signed(read_data_a[1][19:10]);//C0,1 
		mult_op_3_2_Ct <= $signed(read_data_a[1][9:0]);//C0,2 
		Ct_address_a[1] <= Ct_address_a[1] + 8'b1;
		if(col_counter == 3'd6) begin 
		Ct_address_b[0] <= Ct_address_a[0];
		end 
		end
		else begin 
		mult_op_1_2_Ct <= $signed(read_data_b[1][29:20]);//C0,0 
		mult_op_2_2_Ct <= $signed(read_data_b[1][19:10]);//C0,1 
		mult_op_3_2_Ct <= $signed(read_data_b[1][9:0]);//C0,2 
		Ct_address_b[1] <= Ct_address_b[1] + 8'b1; 
		if(col_counter == 3'd3)begin
		Ct_address_b[0] <= Ct_address_a[0];
		end
		end
		
		//In one cc u set address, in the next u get read_add, in the next u use it
		Ct_address_a[0] <= Ct_address_a[0] + 8'b1;

		if(Ct_flag_1) begin //address_a[0] != 8'b0
		if(iteration == 1'b0) begin
		accum_1 <= $signed((accum_1 + Mult_result_1))>>>5;
		accum_2 <= $signed((accum_2 + Mult_result_2))>>>5;
		accum_3 <= $signed((accum_3 + Mult_result_3))>>>5;
		end 
		else begin 
		accum_1 <= (accum_1 + Mult_result_1);
		accum_2 <= (accum_2 + Mult_result_2);
		accum_3 <= (accum_3 + Mult_result_3);
		
		end 
		end
		
		M2_state_1 <= S_CT_1;
		
		end
		
		S_CT_1: begin 
		
		if(Ct_flag_1)begin
		
		if(mode == 1'b0)begin 
		
		if(iteration == 1'b0) begin
		
		Ct_write_data_a <= accum_1;
		Ct_write_data_b <= accum_2;
	
		Ct_w_en_a <= 1'b1;
		Ct_w_en_b <= 1'b1; 
		
		if(e_counter == 8'd192) begin
		M2_state_1 <= S_CT_IDLE;
		M2_finish_Ct <= 1'b1;
		
		end
		else begin 
		M2_state_1 <= S_CT_2;
		end
		
		end else begin
				
		M2_state_1 <= S_CT_2;
		end
		end 
		
		else begin
		Ct_write_data_a <= accum_1;
		Ct_write_data_b <= accum_2;
	
		Ct_w_en_a <= 1'b1;
		Ct_w_en_b <= 1'b1; 
		
		if(e_counter == 8'd24) begin //CHANGE THIS TOO IF ABOVE CORRECT E_COUNTER == 192
		M2_state_1 <= S_CT_IDLE;
		//$stop;
		
		M2_finish_Ct <= 1'b1;
		end
		else begin 
		M2_state_1 <= S_CT_2;
		end
		end
		end
		else begin 
		M2_state_1 <= S_CT_2;
		
		end
		
		
		mult_op_1_1_Ct <= $signed(read_data_a[0][15:0]); //Y1
		mult_op_2_1_Ct <= $signed(read_data_a[0][15:0]); //Y1
		mult_op_3_1_Ct <= $signed(read_data_a[0][15:0]); //Y1 
		
		if(mode == 1'b0) begin
		mult_op_1_2_Ct <= $signed(read_data_a[1][29:20]);//C0,0 
		mult_op_2_2_Ct <= $signed(read_data_a[1][19:10]);//C0,1 
		mult_op_3_2_Ct <= $signed(read_data_a[1][9:0]);//C0,2 
		Ct_address_a[1] <= Ct_address_a[1] + 8'b1; 
		end 
		else begin 
		mult_op_1_2_Ct <= $signed(read_data_b[1][29:20]);//C0,0 
		mult_op_2_2_Ct <= $signed(read_data_b[1][19:10]);//C0,1 
		mult_op_3_2_Ct <= $signed(read_data_b[1][9:0]);//C0,2 
		Ct_address_b[1] <= Ct_address_b[1] + 8'b1; 
		end
		

		Ct_address_a[1] <= Ct_address_a[1] + 8'b1; 
	
		if(mode == 1'b0)begin
		if(iteration == 1'b0) begin
		accum_1 <= Mult_result_1;
		accum_2 <= Mult_result_2; 
		accum_3 <= Mult_result_3;
		end 
		else begin 
		accum_1 <= (accum_1 + Mult_result_1);
		accum_2 <= (accum_2 + Mult_result_2);
		accum_3 <= (accum_3 + Mult_result_3);
		
		end
		end
		else begin 
		accum_1 <= Mult_result_1;
		accum_2 <= Mult_result_2; 
		accum_3 <= Mult_result_3;
		
		end
		
		accum_3_buf <= accum_3;
		

		end
		
		S_CT_2: begin 
		
		if(Ct_flag_1) begin
		
		if(mode == 1'b0) begin 
		if(iteration == 1'b0) begin
		
		Ct_address_a[2] <= Ct_address_a[2] + 8'd2;
		if(col_counter == 3'd3 || col_counter == 3'd6) begin
		Ct_address_b[2] <= Ct_address_b[2] + 8'd2;
		Ct_w_en_a <= 1'b0;
		end 
		else begin 
		Ct_address_b[2] <= Ct_address_b[2] + 8'd3;
		Ct_write_data_a <= accum_3_buf;
		
		end
	
		Ct_w_en_b <= 1'b0; 
		end
		end 
		else begin 
		
		Ct_address_a[2] <= Ct_address_a[2] + 8'd2;
		if(col_counter < 3'd3) begin
		Ct_write_data_a <= accum_3_buf;
		Ct_address_b[2] <= Ct_address_b[2] + 8'd3;
		end 
		else begin 
		Ct_address_b[2] <= Ct_address_b[2] + 8'd2;
		Ct_w_en_a <= 1'b0;
		end
		
		Ct_w_en_b <= 1'b0; 
		end
		end
		
		
		mult_op_1_1_Ct <= $signed(read_data_a[0][31:16]); //Y2
		mult_op_2_1_Ct <= $signed(read_data_a[0][31:16]); //Y2
		mult_op_3_1_Ct <= $signed(read_data_a[0][31:16]); //Y2
		
		if(mode == 1'b0) begin
		mult_op_1_2_Ct <= $signed(read_data_a[1][29:20]);//C2,0 
		mult_op_2_2_Ct <= $signed(read_data_a[1][19:10]);//C2,1 
		mult_op_3_2_Ct <= $signed(read_data_a[1][9:0]);//C2,2
		Ct_address_a[1] <= Ct_address_a[1] + 8'b1;
	   end 
		else begin 
		mult_op_1_2_Ct <= $signed(read_data_b[1][29:20]);//C2,0 
		mult_op_2_2_Ct <= $signed(read_data_b[1][19:10]);//C2,1 
		mult_op_3_2_Ct <= $signed(read_data_b[1][9:0]);//C2,2
		Ct_address_b[1] <= Ct_address_b[1] + 8'b1;
		end
		
		Ct_address_a[0] <= Ct_address_a[0] + 8'b1;
		
		accum_1 <= accum_1 + Mult_result_1;
		accum_2 <= accum_2 + Mult_result_2;
		accum_3 <= accum_3 + Mult_result_3;
		
		M2_state_1 <= S_CT_3;
		
		
		end
		
		S_CT_3: begin 
		
		if(Ct_flag_1) begin 
		
		if(mode == 1'b0) begin 
		if(iteration == 1'b0) begin 
		
		if(!(col_counter == 3'd3 || col_counter == 3'd6)) begin
		Ct_w_en_a <= 1'b0; 
		Ct_address_a[2] <= Ct_address_a[2] + 8'd1;
		end 
		end
		end
		else begin 
		
		if(col_counter < 3'd3) begin
		Ct_w_en_a <= 1'b0; 
		Ct_address_a[2] <= Ct_address_a[2] + 8'd1;
		end 
		end
		end
		
		mult_op_1_1_Ct <= $signed(read_data_a[0][15:0]); //Y3
		mult_op_2_1_Ct <= $signed(read_data_a[0][15:0]); //Y3
		mult_op_3_1_Ct <= $signed(read_data_a[0][15:0]); //Y3
		
		if(mode == 1'b0) begin
		mult_op_1_2_Ct <= $signed(read_data_a[1][29:20]);//C3,0 
		mult_op_2_2_Ct <= $signed(read_data_a[1][19:10]);//C3,1 
		mult_op_3_2_Ct <= $signed(read_data_a[1][9:0]);//C3,2 
		Ct_address_a[1] <= Ct_address_a[1] + 8'b1;
		end
		else begin 
		mult_op_1_2_Ct <= $signed(read_data_b[1][29:20]);//C3,0 
		mult_op_2_2_Ct <= $signed(read_data_b[1][19:10]);//C3,1 
		mult_op_3_2_Ct <= $signed(read_data_b[1][9:0]);//C3,2 
		Ct_address_b[1] <= Ct_address_b[1] + 8'b1;
		
		end 
		
		accum_1 <= accum_1 + Mult_result_1;
		accum_2 <= accum_2 + Mult_result_2;
		accum_3 <= accum_3 + Mult_result_3;
		
		M2_state_1 <= S_CT_4;

		end 
		
		S_CT_4: begin 
		
		mult_op_1_1_Ct <= $signed(read_data_a[0][31:16]); //Y4
		mult_op_2_1_Ct <= $signed(read_data_a[0][31:16]); //Y4
		mult_op_3_1_Ct <= $signed(read_data_a[0][31:16]); //Y4
		
		if(mode == 1'b0) begin
		mult_op_1_2_Ct <= $signed(read_data_a[1][29:20]);//C4,0 
		mult_op_2_2_Ct <= $signed(read_data_a[1][19:10]);//C4,1 
		mult_op_3_2_Ct <= $signed(read_data_a[1][9:0]);//C4,2 
		Ct_address_a[1] <= Ct_address_a[1] + 8'b1;
		end 
		else begin 
		mult_op_1_2_Ct <= $signed(read_data_b[1][29:20]);//C4,0 
		mult_op_2_2_Ct <= $signed(read_data_b[1][19:10]);//C4,1 
		mult_op_3_2_Ct <= $signed(read_data_b[1][9:0]);//C4,2 
		Ct_address_b[1] <= Ct_address_b[1] + 8'b1;
		
		end
		
		Ct_address_a[0] <= Ct_address_a[0] + 8'b1;
		
		accum_1 <= accum_1 + Mult_result_1;
		accum_2 <= accum_2 + Mult_result_2;
		accum_3 <= accum_3 + Mult_result_3;

		M2_state_1 <= S_CT_5;
		
		
		end
		
		S_CT_5: begin 
		
		mult_op_1_1_Ct <= $signed(read_data_a[0][15:0]); //Y5
		mult_op_2_1_Ct <= $signed(read_data_a[0][15:0]); //Y5
		mult_op_3_1_Ct <= $signed(read_data_a[0][15:0]); //Y5
		
		
		if(mode == 1'b0) begin
		mult_op_1_2_Ct <= $signed(read_data_a[1][29:20]);//C5,0 
		mult_op_2_2_Ct <= $signed(read_data_a[1][19:10]);//C5,1 
		mult_op_3_2_Ct <= $signed(read_data_a[1][9:0]);//C5,2 
		Ct_address_a[1] <= Ct_address_a[1] + 8'b1;
		end 
		else begin 
		mult_op_1_2_Ct <= $signed(read_data_b[1][29:20]);//C5,0 
		mult_op_2_2_Ct <= $signed(read_data_b[1][19:10]);//C5,1 
		mult_op_3_2_Ct <= $signed(read_data_b[1][9:0]);//C5,2 
		Ct_address_b[1] <= Ct_address_b[1] + 8'b1;
		
		end
		
		
		accum_1 <= accum_1 + Mult_result_1;
		accum_2 <= accum_2 + Mult_result_2;
		accum_3 <= accum_3 + Mult_result_3;
		
		M2_state_1 <= S_CT_6;
		
		
		
		end
		
		S_CT_6: begin 
		
		mult_op_1_1_Ct <= $signed(read_data_a[0][31:16]); //Y6
		mult_op_2_1_Ct <= $signed(read_data_a[0][31:16]); //Y6
		mult_op_3_1_Ct <= $signed(read_data_a[0][31:16]); //Y6
		
		
		if(mode == 1'b0) begin
		mult_op_1_2_Ct <= $signed(read_data_a[1][29:20]);//C6,0 
		mult_op_2_2_Ct <= $signed(read_data_a[1][19:10]);//C6,1 
		mult_op_3_2_Ct <= $signed(read_data_a[1][9:0]);//C6,2 
		end 
		else begin 
		mult_op_1_2_Ct <= $signed(read_data_b[1][29:20]);//C6,0 
		mult_op_2_2_Ct <= $signed(read_data_b[1][19:10]);//C6,1 
		mult_op_3_2_Ct <= $signed(read_data_b[1][9:0]);//C6,2 
		end
		
		if(mode == 1'b0) begin 
		if (iteration == 1'b1) begin
			if(col_counter == 3'd6)begin 
			Ct_address_a[1] <= 8'b0;
			Ct_address_a[0] <= Ct_address_a[0] + 8'b1;
			end
			else begin
			Ct_address_a[0] <= Ct_address_b[0];
			Ct_address_a[1] <= Ct_address_a[1] + 8'b1;
			end 
		end 
		else begin
			
			Ct_address_a[1] <= Ct_address_a[1] + 8'b1;
			Ct_address_a[0] <= Ct_address_a[0] + 8'b1;
		
		end
		end
		else begin
		
		if(col_counter == 3'd2) begin 
		Ct_address_a[0] <= Ct_address_a[0] + 8'b1;
		Ct_address_b[1] <= 8'd96;
		end
		else begin 
		Ct_address_a[0] <= Ct_address_b[0];
		Ct_address_b[1] <= Ct_address_b[1] + 8'b1;
		end
		end
		
		accum_1 <= accum_1 + Mult_result_1;
		accum_2 <= accum_2 + Mult_result_2;
		accum_3 <= accum_3 + Mult_result_3;
		
		
		
		M2_state_1 <= S_CT_7;
		
	
		end
		
		S_CT_7: begin 
		
		mult_op_1_1_Ct <= $signed(read_data_a[0][15:0]); //Y7
		mult_op_2_1_Ct <= $signed(read_data_a[0][15:0]); //Y7
		mult_op_3_1_Ct <= $signed(read_data_a[0][15:0]); //Y7
		
		if(mode == 1'b0) begin
		mult_op_1_2_Ct <= $signed(read_data_a[1][29:20]);//C7,0 
		mult_op_2_2_Ct <= $signed(read_data_a[1][19:10]);//C7,1 
		mult_op_3_2_Ct <= $signed(read_data_a[1][9:0]);//C7,2 
		Ct_address_a[1] <= Ct_address_a[1] + 8'b1;
		end 
		else begin 
		mult_op_1_2_Ct <= $signed(read_data_b[1][29:20]);//C7,0 
		mult_op_2_2_Ct <= $signed(read_data_b[1][19:10]);//C7,1 
		mult_op_3_2_Ct <= $signed(read_data_b[1][9:0]);//C7,2
		Ct_address_b[1] <= Ct_address_b[1] + 8'b1;
		end 

		accum_1 <= accum_1 + Mult_result_1;
		accum_2 <= accum_2 + Mult_result_2;
		accum_3 <= accum_3 + Mult_result_3;
		
		Ct_flag_1 <= 1'b1;
		
		
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
		
		if(mode == 1'b0) iteration <= ~iteration;
		
		e_counter <= e_counter + 1'b1;
		
		M2_state_1 <= S_CT_0;
		
		
		end 
		
		default: M2_state_1  <= S_CT_IDLE;

		endcase
	
		end
		
		end
	
		
    M2_Cs_state_type M2_state_2;

	// S' has already been saved into a DP_RAM (inst_0), we write S values to (inst_3)
	//Each Y location in the DP-RAM contains two y-values 
	
	always_ff @(posedge clock or negedge resetn) begin
	
		if(!resetn) begin 
		
		flag_1_Cs <= 1'b0; //flag 1 is set to zero when we are doing the very first block of Y/U/V
		col_counter_Cs <= 3'b0; //checks whether we are computing for 3 T values or 2 T values
//		mode <= 1'b0; //starts with the Y blocks 
		iteration_Cs <= 1'b0; //only matters for Y blocks as it needs to go through the state structure twice per value 
		e_counter_Cs <= 8'b0;
		accum_1_Cs <= 32'b0;
		accum_2_Cs <= 32'b0;
		accum_3_Cs <= 32'b0;
		accum_3_buf_Cs <= 32'b0;
		
	
		Cs_address_a[1] <= 8'b0;
		Cs_address_b[1] <= 8'b0;
		Cs_address_a[0] <= 8'b0;
		Cs_address_b[0] <= 8'd96;
		Cs_address_a[2] <= 8'b0;
		Cs_address_b[2] <= 8'b1;
		
		Cs_w_en_a <= 1'b0;
		Cs_w_en_b <= 1'b0; 
		M2_finish_Cs <= 1'b0;
		
		mult_op_1_1_Cs <= 32'd0;
		mult_op_2_1_Cs <= 32'd0;
		mult_op_3_1_Cs <= 32'd0;
		
		mult_op_1_2_Cs <= 32'd0;
		mult_op_2_2_Cs <= 32'd0;
		mult_op_3_2_Cs <= 32'd0;
		
		Cs_write_data_a <= 32'd0;
		Cs_write_data_b <= 32'd0;
		
		
		end
		
		else begin
		
		case(M2_state_2)
		
		S_CS_IDLE: begin 
		
		M2_finish_Cs <= 1'b0;
		iteration_Cs <= 1'b0;
		e_counter_Cs <= 8'b0;
		flag_1_Cs <= 1'b0;
		col_counter_Cs <= 3'b0;
		Cs_address_a[1] <= 8'b0;
		Cs_address_b[1] <= 8'b0;
		Cs_address_a[0] <= 8'b0;
		Cs_address_b[0] <= 8'd96;
		Cs_address_a[2] <= 8'b0;
		Cs_address_b[2] <= 8'b1;
		accum_1_Cs <= 32'b0;
		accum_2_Cs <= 32'b0;
		accum_3_Cs <= 32'b0;
		accum_3_buf_Cs <= 32'b0;
		Cs_w_en_a <= 1'b0;
		Cs_w_en_b <= 1'b0;
		
		if(M2_start_Cs == 1'b1)begin
		M2_state_2 <= S_CS_DELAY;
		end 
		
		end
		
		S_CS_DELAY: begin
		
		if(M2_start_Cs == 1'b1)begin
		M2_state_2 <= S_LI_S;
		end 
		
		end
	
		
		S_LI_S: begin 
		
		Cs_address_a[0] <= 8'b1;
		if(mode == 1'b1) begin
		Cs_address_a[1] <= 8'd8;
		end
		else begin 
		Cs_address_a[1] <= 8'd16;
		end
		Cs_address_b[0] <= 8'd97;
		
		M2_state_2 <= S_CS_0;
		
		end
		
		//In one cc u set address, in the next u get read_add, in the next u use it
		//0 for c, 1 is for t and 2 for s
		
		S_CS_0: begin
		
		mult_op_1_1_Cs <= $signed(read_data_a[2][31:0]); //T0, Y16     
		mult_op_2_1_Cs <= $signed(read_data_a[2][31:0]); //T0 
		mult_op_3_1_Cs <= $signed(read_data_a[2][31:0]); //T0
		 
		if(mode == 1'b0) begin
		mult_op_1_2_Cs <= $signed(read_data_a[1][29:20]);//C0,0 
		mult_op_2_2_Cs <= $signed(read_data_a[1][19:10]);//C0,1 
		mult_op_3_2_Cs <= $signed(read_data_a[1][9:0]);//C0,2 
		Cs_address_a[0] <= Cs_address_a[0] + 8'b1; 
		Cs_address_a[1] <= Cs_address_a[1] + 8'd16;
		end 
		else begin 
		mult_op_1_2_Cs <= $signed(read_data_b[1][29:20]);//C0,0 
		mult_op_2_2_Cs <= $signed(read_data_b[1][19:10]);//C0,1 
		mult_op_3_2_Cs <= $signed(read_data_b[1][9:0]);//C0,2 
		Cs_address_b[0] <= Cs_address_b[0] + 8'b1; 
		Cs_address_a[1] <= Cs_address_a[1] + 8'd8;
		end 

		if(flag_1_Cs) begin //address_a[0] != 8'b0
		if(mode == 1'b0) begin
		if(iteration_Cs == 1'b0) begin
		accum_1_Cs <=  $signed(13'd4096 + ((accum_1_Cs + Mult_result_1)))>>>13;
		accum_2_Cs <=  $signed(13'd4096 + ((accum_2_Cs + Mult_result_2)))>>>13;
		accum_3_Cs <=  $signed(13'd4096 + ((accum_3_Cs + Mult_result_3)))>>>13;
		end 
		else begin 
		accum_1_Cs <= accum_1_Cs + Mult_result_1;
		accum_2_Cs <= accum_2_Cs + Mult_result_2; 
		accum_3_Cs <= accum_3_Cs + Mult_result_3;
		end
		end 
		else begin 
		accum_1_Cs <=  $signed(13'd4096 + ((accum_1_Cs + Mult_result_1)))>>>13;
		accum_2_Cs <=  $signed(13'd4096 + ((accum_2_Cs + Mult_result_2)))>>>13;
		accum_3_Cs <=  $signed(13'd4096 + ((accum_3_Cs + Mult_result_3)))>>>13;
		end
		end
		
		M2_state_2 <= S_CS_1;
		
		end
		
		S_CS_1: begin 
		
		if(flag_1_Cs)begin
		
		if(mode == 1'b0)begin 
		
		if(iteration_Cs == 1'b0) begin
		
		Cs_write_data_a <= accum_1_Cs;
		Cs_write_data_b <= accum_2_Cs;
		
		Cs_w_en_a <= 1'b1;
		Cs_w_en_b <= 1'b1; 
		
		if(e_counter_Cs == 8'd192) begin
		M2_state_2 <= S_CS_IDLE;
		M2_finish_Cs <= 1'b1;
		end
		else begin
		M2_state_2 <= S_CS_2;
		end 
		end 
		else begin 
		M2_state_2 <= S_CS_2;
		end
		end 
		
		else begin
		Cs_write_data_a <= accum_1_Cs;
		Cs_write_data_b <= accum_2_Cs;
		
		Cs_w_en_a  <= 1'b1;
		Cs_w_en_b  <= 1'b1; 
		
		if(e_counter_Cs == 8'd24) begin
		M2_state_2 <= S_CS_IDLE;
		M2_finish_Cs <= 1'b1;
		end
		else begin 
		M2_state_2 <= S_CS_2;
		end
		end
		end
		else begin 
		M2_state_2 <= S_CS_2;
		end
		
		
		mult_op_1_1_Cs <= $signed(read_data_a[2][31:0]); //T1
		mult_op_2_1_Cs <= $signed(read_data_a[2][31:0]); //T1
		mult_op_3_1_Cs <= $signed(read_data_a[2][31:0]); //T1
		
		if(mode == 1'b0) begin
		mult_op_1_2_Cs <= $signed(read_data_a[1][29:20]);//C0,0 
		mult_op_2_2_Cs <= $signed(read_data_a[1][19:10]);//C0,1 
		mult_op_3_2_Cs <= $signed(read_data_a[1][9:0]);//C0,2 
		Cs_address_a[0] <= Cs_address_a[0] + 8'b1; 
		Cs_address_a[1] <= Cs_address_a[1] + 8'd16;
		end 
		else begin 
		mult_op_1_2_Cs <= $signed(read_data_b[1][29:20]);//C0,0 
		mult_op_2_2_Cs <= $signed(read_data_b[1][19:10]);//C0,1 
		mult_op_3_2_Cs <= $signed(read_data_b[1][9:0]);//C0,2 
		Cs_address_b[0] <= Cs_address_b[0] + 8'b1; 
		Cs_address_a[1] <= Cs_address_a[1] + 8'd8;
		end
		
		if(mode == 1'b0)begin
		if(iteration_Cs == 1'b0) begin
		accum_1_Cs <= Mult_result_1;
		accum_2_Cs <= Mult_result_2; 
		accum_3_Cs <= Mult_result_3;
		end 
		else begin 
		accum_1_Cs <= (accum_1_Cs + Mult_result_1);
		accum_2_Cs <= (accum_2_Cs + Mult_result_2);
		accum_3_Cs <= (accum_3_Cs + Mult_result_3);
		
		end
		end
		else begin 
		accum_1_Cs <= Mult_result_1;
		accum_2_Cs <= Mult_result_2; 
		accum_3_Cs <= Mult_result_3;
		
		end
		
		accum_3_buf_Cs <= accum_3_Cs;
		

		end
		
		S_CS_2: begin 
		
		if(flag_1_Cs) begin
		
		if(mode == 1'b0) begin 
		if(iteration_Cs == 1'b0) begin
		Cs_address_a[2] <= Cs_address_a[2] + 8'd2;
		if(col_counter_Cs == 3'd3 || col_counter_Cs == 3'd6) begin
		Cs_address_b[2] <= Cs_address_b[2] + 8'd2;
		Cs_w_en_a  <= 1'b0;
		end 
		else begin 
		Cs_address_b[2] <= Cs_address_b[2] + 8'd3;
		Cs_write_data_a <= accum_3_buf_Cs;
		end
		Cs_w_en_b <= 1'b0; 
		end
		end
		
		else begin 
		Cs_address_a[2] <= Cs_address_a[2] + 8'd2;
		if(col_counter_Cs < 3'd3) begin
		Cs_write_data_a <= accum_3_buf_Cs;
		Cs_address_b[2] <= Cs_address_b[2] + 8'd3;
		end 
		else begin 
		Cs_address_b[2] <= Cs_address_b[2] + 8'd2;
		Cs_w_en_a  <= 1'b0;
		end
		Cs_w_en_b  <= 1'b0; 
		end
		end
		
		mult_op_1_1_Cs <= $signed(read_data_a[2][31:0]); //T2
		mult_op_2_1_Cs <= $signed(read_data_a[2][31:0]); //T2
		mult_op_3_1_Cs <= $signed(read_data_a[2][31:0]); //T2
		
		if(mode == 1'b0) begin
		mult_op_1_2_Cs <= $signed(read_data_a[1][29:20]);//C0,0 
		mult_op_2_2_Cs <= $signed(read_data_a[1][19:10]);//C0,1 
		mult_op_3_2_Cs <= $signed(read_data_a[1][9:0]);//C0,2 
		Cs_address_a[0] <= Cs_address_a[0] + 8'b1; 
		Cs_address_a[1] <= Cs_address_a[1] + 8'd16;
		end 
		else begin 
		mult_op_1_2_Cs <= $signed(read_data_b[1][29:20]);//C0,0 
		mult_op_2_2_Cs <= $signed(read_data_b[1][19:10]);//C0,1 
		mult_op_3_2_Cs <= $signed(read_data_b[1][9:0]);//C0,2 
		Cs_address_b[0] <= Cs_address_b[0] + 8'b1; 
		Cs_address_a[1] <= Cs_address_a[1] + 8'd8;
		end
		
		accum_1_Cs <= accum_1_Cs + Mult_result_1;
		accum_2_Cs <= accum_2_Cs + Mult_result_2; 
		accum_3_Cs <= accum_3_Cs + Mult_result_3;
		
		
		M2_state_2 <= S_CS_3;
		
		
		end
		
		S_CS_3: begin 
		if(flag_1_Cs) begin 
		
		if(mode == 1'b0) begin 
		if(iteration_Cs == 1'b0) begin 
		
		if(!(col_counter_Cs == 3'd3 || col_counter_Cs == 3'd6)) begin
		Cs_w_en_a  <= 1'b0; 
		Cs_address_a[2] <= Cs_address_a[2] + 8'd1;
		end 
		end
		end
		else begin 
		
		if(col_counter_Cs < 3'd3) begin
		Cs_w_en_a  <= 1'b0; 
		Cs_address_a[2] <= Cs_address_a[2] + 8'd1;
		end 
		end
		end
		
		mult_op_1_1_Cs <= $signed(read_data_a[2][31:0]); //T3
		mult_op_2_1_Cs <= $signed(read_data_a[2][31:0]); //T3
		mult_op_3_1_Cs <= $signed(read_data_a[2][31:0]); //T3
		
		if(mode == 1'b0) begin
		mult_op_1_2_Cs <= $signed(read_data_a[1][29:20]);//C0,0 
		mult_op_2_2_Cs <= $signed(read_data_a[1][19:10]);//C0,1 
		mult_op_3_2_Cs <= $signed(read_data_a[1][9:0]);//C0,2 
		Cs_address_a[0] <= Cs_address_a[0] + 8'b1; 
		Cs_address_a[1] <= Cs_address_a[1] + 8'd16;
		end 
		else begin 
		mult_op_1_2_Cs <= $signed(read_data_b[1][29:20]);//C0,0 
		mult_op_2_2_Cs <= $signed(read_data_b[1][19:10]);//C0,1 
		mult_op_3_2_Cs <= $signed(read_data_b[1][9:0]);//C0,2 
		Cs_address_b[0] <= Cs_address_b[0] + 8'b1; 
		Cs_address_a[1] <= Cs_address_a[1] + 8'd8;
		end

		
		accum_1_Cs <= accum_1_Cs + Mult_result_1;
		accum_2_Cs <= accum_2_Cs + Mult_result_2; 
		accum_3_Cs <= accum_3_Cs + Mult_result_3;
		
		M2_state_2 <= S_CS_4;

		end 
		
		S_CS_4: begin 
		
		mult_op_1_1_Cs <= $signed(read_data_a[2][31:0]); //T4
		mult_op_2_1_Cs <= $signed(read_data_a[2][31:0]); //T4
		mult_op_3_1_Cs <= $signed(read_data_a[2][31:0]); //T4
		
		if(mode == 1'b0) begin
		mult_op_1_2_Cs <= $signed(read_data_a[1][29:20]);//C0,0 
		mult_op_2_2_Cs <= $signed(read_data_a[1][19:10]);//C0,1 
		mult_op_3_2_Cs <= $signed(read_data_a[1][9:0]);//C0,2 
		Cs_address_a[0] <= Cs_address_a[0] + 8'b1; 
		Cs_address_a[1] <= Cs_address_a[1] + 8'd16;
		end 
		else begin 
		mult_op_1_2_Cs <= $signed(read_data_b[1][29:20]);//C0,0 
		mult_op_2_2_Cs <= $signed(read_data_b[1][19:10]);//C0,1 
		mult_op_3_2_Cs <= $signed(read_data_b[1][9:0]);//C0,2 
		Cs_address_b[0] <= Cs_address_b[0] + 8'b1; 
		Cs_address_a[1] <= Cs_address_a[1] + 8'd8;
		end

		
		accum_1_Cs <= accum_1_Cs + Mult_result_1;
		accum_2_Cs <= accum_2_Cs + Mult_result_2; 
		accum_3_Cs <= accum_3_Cs + Mult_result_3;
	
		
		
		M2_state_2 <= S_CS_5;
		
		
		end
		
		S_CS_5: begin 
		
		mult_op_1_1_Cs <= $signed(read_data_a[2][31:0]); //T5
		mult_op_2_1_Cs <= $signed(read_data_a[2][31:0]); //T5
		mult_op_3_1_Cs <= $signed(read_data_a[2][31:0]); //T5
		
		if(mode == 1'b0) begin
		mult_op_1_2_Cs <= $signed(read_data_a[1][29:20]);//C0,0 
		mult_op_2_2_Cs <= $signed(read_data_a[1][19:10]);//C0,1 
		mult_op_3_2_Cs <= $signed(read_data_a[1][9:0]);//C0,2 
		Cs_address_a[0] <= Cs_address_a[0] + 8'b1; 
		Cs_address_a[1] <= Cs_address_a[1] + 8'd16;
		end 
		else begin 
		mult_op_1_2_Cs <= $signed(read_data_b[1][29:20]);//C0,0 
		mult_op_2_2_Cs <= $signed(read_data_b[1][19:10]);//C0,1 
		mult_op_3_2_Cs <= $signed(read_data_b[1][9:0]);//C0,2 
		Cs_address_b[0] <= Cs_address_b[0] + 8'b1; 
		Cs_address_a[1] <= Cs_address_a[1] + 8'd8;
		end
		
		
		accum_1_Cs <= accum_1_Cs + Mult_result_1;
		accum_2_Cs <= accum_2_Cs + Mult_result_2; 
		accum_3_Cs <= accum_3_Cs + Mult_result_3;
		
		M2_state_2 <= S_CS_6;
		
		end
		
		S_CS_6: begin 
		
		mult_op_1_1_Cs <= $signed(read_data_a[2][31:0]); //T6
		mult_op_2_1_Cs <= $signed(read_data_a[2][31:0]); //T6
		mult_op_3_1_Cs <= $signed(read_data_a[2][31:0]); //T6
		
		if(mode == 1'b0) begin
		mult_op_1_2_Cs <= $signed(read_data_a[1][29:20]);//C0,0 
		mult_op_2_2_Cs <= $signed(read_data_a[1][19:10]);//C0,1 
		mult_op_3_2_Cs <= $signed(read_data_a[1][9:0]);//C0,2 
		
		end 
		else begin 
		mult_op_1_2_Cs <= $signed(read_data_b[1][29:20]);//C0,0 
		mult_op_2_2_Cs <= $signed(read_data_b[1][19:10]);//C0,1 
		mult_op_3_2_Cs <= $signed(read_data_b[1][9:0]);//C0,2 
		
		end
		
		if(mode == 1'b0) begin 
		if (iteration_Cs == 1'b1) begin
			if(col_counter_Cs == 3'd6)begin 
			Cs_address_a[0] <= 8'b0;
			Cs_address_a[1] <= Cs_address_b[1] + 8'b1;
			end
			else begin
			Cs_address_a[1] <= Cs_address_b[1];
			Cs_address_a[0] <= Cs_address_a[0] + 8'b1;
			end 
		end 
		else begin
		
			if(mode == 1'b1)begin 
			Cs_address_a[1] <= Cs_address_a[1] + 8'd8;
			end 
			else begin 
			Cs_address_a[1] <= Cs_address_a[1] + 8'd16;
			end
			Cs_address_a[0] <= Cs_address_a[0] + 8'b1;
		
		end
		end
		else begin
		
		if(col_counter_Cs == 3'd2) begin 
		Cs_address_a[1] <= Cs_address_b[1] + 8'b1;
		Cs_address_b[0] <= 8'd96;
		end
		else begin 
		Cs_address_a[1] <= Cs_address_b[1];
		Cs_address_b[0] <= Cs_address_b[0] + 8'b1;
		end
		end
		
		accum_1_Cs <= accum_1_Cs + Mult_result_1;
		accum_2_Cs <= accum_2_Cs + Mult_result_2; 
		accum_3_Cs <= accum_3_Cs + Mult_result_3;
		
		
		
		
		M2_state_2 <= S_CS_7;
		
	
		end
		
		S_CS_7: begin 
		
		mult_op_1_1_Cs <= $signed(read_data_a[2][31:0]); //Y7
		mult_op_2_1_Cs <= $signed(read_data_a[2][31:0]); //Y7
		mult_op_3_1_Cs <= $signed(read_data_a[2][31:0]); //Y7
		
		if(mode == 1'b0) begin
		mult_op_1_2_Cs <= $signed(read_data_a[1][29:20]);//C0,0 
		mult_op_2_2_Cs <= $signed(read_data_a[1][19:10]);//C0,1 
		mult_op_3_2_Cs <= $signed(read_data_a[1][9:0]);//C0,2 
		Cs_address_a[0] <= Cs_address_a[0] + 8'b1; 
		Cs_address_a[1] <= Cs_address_a[1] + 8'd16;
		end 
		else begin 
		mult_op_1_2_Cs <= $signed(read_data_b[1][29:20]);//C0,0 
		mult_op_2_2_Cs <= $signed(read_data_b[1][19:10]);//C0,1 
		mult_op_3_2_Cs <= $signed(read_data_b[1][9:0]);//C0,2 
		Cs_address_b[0] <= Cs_address_b[0] + 8'b1; 
		Cs_address_a[1] <= Cs_address_a[1] + 8'd8;
		end

		
		accum_1_Cs <= accum_1_Cs + Mult_result_1;
		accum_2_Cs <= accum_2_Cs + Mult_result_2;
		accum_3_Cs <= accum_3_Cs + Mult_result_3;
		
		flag_1_Cs <= 1'b1;
		
		
		if(mode == 1'b0) begin 
		
		if(iteration_Cs == 1'b0) begin 
		
		if(col_counter_Cs < 3'd6) begin
		col_counter_Cs <= col_counter_Cs + 3'b1;
		end 
		else begin
		col_counter_Cs <= 3'd1;
		end 
		end
		
		end 
		
		else begin
		if(col_counter_Cs < 3'd3) begin 
		col_counter_Cs <= col_counter_Cs + 3'b1;
		end 
		else begin
		col_counter_Cs <= 3'd1;
		end 
		end
		
		if(mode == 1'b0)
		iteration_Cs <= ~iteration_Cs;
		
		
		if(mode == 1'b1) begin
		if(col_counter_Cs == 3'd2)begin
		Cs_address_b[1] <= Cs_address_a[1];
		end
		end
		else begin 
		if(col_counter_Cs == 3'd6) begin 
		if(iteration_Cs == 1'b1)begin
		Cs_address_b[1] <= Cs_address_a[1];
		end
		end
		end
		
		e_counter_Cs <= e_counter_Cs + 1'b1;
		
		M2_state_2 <= S_CS_0;
		
		
		
		end 
		
		default: M2_state_2  <= S_CS_IDLE;
		
		endcase 
	
	end
	
	end
	
	
	
	//writing

		
	M2_write_state_type M2_state_3;
	
	
	//address for Y, U or V blocks 


	always_comb begin 
	
		
		if (flag_1) begin
		
	    	//8x8 fetch 
			SRAM_address_M2_write = U_OFFSET + col_index + (col_block << 2) +  (row_index << 5) + (row_index << 4) + ( (row_block << 4) + (row_block << 5) << 3); 
			
			if (flag_2) begin 

				SRAM_address_M2_write = V_OFFSET + col_index + (col_block << 2) +  (row_index << 5) + (row_index << 4) + ( (row_block << 4) + (row_block << 5) << 3);
				end
				
			end else begin 
			
		   //16x16 fetch
			SRAM_address_M2_write = col_index + (col_block << 3) + (row_index << 6) + (row_index << 5) +  ((row_block << 6) + (row_block << 5) << 4);
		
		end
		
	end
	
	//use flag_1
	
	logic[4:0] increment; 
	
	assign increment = flag_1 ? 5'd8 : 5'd16;
	
	logic start_flag_1;
	
	logic start_flag_2;
	

	


always_ff @(posedge clock or negedge resetn) begin
	
	if (~resetn) begin 
		M2_state_3 <= S_write_IDLE;
		
		SRAM_w_en_M2_write <= 1'b1; //active low so set to read first
		M2_finish_write <= 1'b0;
	
		address_a_M2_write <= 8'd0;

		row_block <= 5'd0; 
		col_block <= 4'd0;
		
		row_index <= 4'd0;
		col_index <= 4'd0;
		
		fetch_S_buffer <= 32'd0;
		
		offset <= 6'd1;
		
		flag_1 <= 1'd0;
		flag_2 <= 1'd0;
		M2_finish_write <= 1'b0;
		
		start_flag_2 <= 1'b1;
		start_flag_1 <= 1'b1;
		
	end else begin

	
		case (M2_state_3)
		S_write_IDLE: begin
		
			fetch_S_buffer <= 32'd0;
			SRAM_w_en_M2_write <= 1'b1;  
			row_index <= 4'd0;
		   col_index <= 4'd0;
			address_a_M2_write <= 8'd0;
			offset <= 6'd1;
			start_flag_1 <= 1'b1;
			SRAM_write_data_M2_write <= 16'd0;
			M2_finish_write <= 1'b0;

			
	
			
			if (M2_start_write) begin 
					M2_state_3 <= S_Delay; 
			end
			
		end
		
		
		S_Delay: begin
		
			
			if (M2_start_write) begin
					M2_state_3 <= S_write_1; 
			end
		
		end
		
		
		
		S_write_1: begin
			fetch_S_buffer <= read_data_a[3]; //0
		   SRAM_w_en_M2_write <= 1'b1; 	//sram read	
			address_a_M2_write <= address_a_M2_write + increment; //8
			
			if (start_flag_1) begin
				start_flag_1 <= 1'b0;
			end else begin
				col_index <= col_index + 1; //increment sram address //0,2
			end

			M2_state_3 <= S_write_2;
		end
		
		
		S_write_2: begin
			SRAM_w_en_M2_write <= 1'b1; 
			M2_state_3 <= S_write_3; 
			address_a_M2_write <= address_a_M2_write + increment; //16
		end
		
		
		

		S_write_3: begin 
			
			SRAM_w_en_M2_write <= 1'b0; 
			
			M2_state_3 <= S_write_4;
			
			address_a_M2_write <= address_a_M2_write + increment; //32
			
			SRAM_write_data_M2_write <= {clip_2, clip_1}; //[0,8]
	
		end
		
		
		
		S_write_4: begin 
		
			SRAM_w_en_M2_write <= 1'b1; //read from sram
			
			fetch_S_buffer <= read_data_a[3]; //buffer 2, buffer 6 
			
			col_index <= col_index + 1; //increment sram address //1,3 
			
			M2_state_3 <= S_write_5;
			
		
		end
		
		
		S_write_5: begin 
		
	
			SRAM_w_en_M2_write <= 1'b0; 	//sram write
			
			SRAM_write_data_M2_write <= {clip_2, clip_1}; //[16,32]
			
			address_a_M2_write <= address_a_M2_write + increment; //4,8
			
			M2_state_3 <= S_write_Delay2;
				
		end
		
		S_write_Delay2: begin
		
				//check depending on Y or U/V block to determine how many times to repeat 
			SRAM_w_en_M2_write <= 1'b1; 	//sram
				
			if (col_index == col_amount) begin //if 3
				col_index <= 4'd0; //set 0
				SRAM_w_en_M2_write <= 1'b1;
				row_index <= row_index + 1; 
				start_flag_1 <= 1'b1;
				offset <= offset + 1;
				address_a_M2_write <= offset; //on first run the offset is 1
				
				if (row_index == row_amount) begin //if all rows are done
				   M2_finish_write <= 1'b1;

					M2_state_3 <= S_write_IDLE;
					col_block <= col_block + 1;

					
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
				
			end else begin 
				
				
				M2_state_3 <= S_write_1;
				
			end
		
		
		end

		
	
		default: M2_state_3  <= S_write_IDLE;

		endcase
		
	end
	

	end


	
	
	
	
	//clipping and scaling 
	
	
	always_comb begin
		if (read_data_a[3][31] == 1'b1) clip_1 = 0;
		else if(|read_data_a[3][30:8] == 1'b1) clip_1 = 8'd255;
		else clip_1 = read_data_a[3][7:0];
	end
	
	
	always_comb begin
		if (fetch_S_buffer[31] == 1'b1) clip_2 = 0;
		else if(|fetch_S_buffer[30:8] == 1'b1) clip_2 = 8'd255;
		else clip_2 = fetch_S_buffer[7:0];
	end

	
	
	//choosing which signal drives the SRAM 
	
	always_comb begin
		
		if ((state == S_M2_CC1) || (state == S_M2_fetch_LI)) begin
			SRAM_address = SRAM_address_M2_fetch;
			SRAM_w_en = 1'b1;
			SRAM_write_data = 16'd0;
//			SRAM_read_data_M2_fetch = SRAM_read_data; //check
		end else begin
		
		
		if ((state == S_M2_Write_LO) || (state == S_M2_CC2)) begin
			SRAM_address = SRAM_address_M2_write;
			SRAM_w_en = SRAM_w_en_M2_write;
			SRAM_write_data = SRAM_write_data_M2_write;
		end  
		
		else begin //Haseeb changed as SRAM_add was staying constant, this works only under non-blocking assignments??
		SRAM_address = 18'd27648;
		SRAM_w_en = 1'b1;
		SRAM_write_data = 16'd0;
		end
		
		end 
		
	end

	

	endmodule
	
	
	
	
	

	
	


