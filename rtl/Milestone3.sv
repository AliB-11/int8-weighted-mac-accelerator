`timescale 1ns/100ps

`ifndef DISABLE_DEFAULT_NET
`default_nettype none
`endif
`include "define_state.h"

module Milestone3 (
		input logic Clock,
		input logic resetn,
		input logic M3_start,
		input logic [15:0] SRAM_read_data,
		output logic [15:0] SRAM_write_data,
		output logic SRAM_we_n,
		output logic M3_done,
		output logic [17:0] SRAM_address			
);


//DPRAM intializations

logic [7:0] address_a;  //256 locations so 8 bits required for address a and b 
logic [7:0] address_b;
	
logic [31:0] write_data_a; 
logic [31:0] write_data_b;  //32 bits of data 
	
logic [31:0] read_data_a; 
logic [31:0] read_data_b;

logic flag_3;
logic flag_4;
logic flag_6;
logic flag_7;
logic [7:0] flag_5;
logic [2:0] flag_8;
logic write_enable_a;
logic write_enable_b; 	

logic [15:0] value_1, value_2;

logic [2:0] variable_shift;  

assign value_1 =  $signed(shift_reg[45:44]) << variable_shift;
assign value_2 = $signed(shift_reg[45:37]) << variable_shift;

 //16 bit output of program 

logic [7:0] address;

M3_state_type M3_state;


logic [47:0] shift_reg;  
logic [15:0] memory_data;
logic mode; 

logic [4:0] shift_counter; // number of bits that has already shifted
logic [4:0] bit_shift_unit,bits_left, remaining_bits, store_shift;
logic [7:0] counter,z_counter,flag,flag_2; //counter: number of data that has written in the DPRAM

logic [5:0] block_col_index, block_row_index;

logic [3:0] row_index;  
logic [3:0] col_index; 

assign row_index = (mode) ? address[5:3] : address[7:4];
assign col_index = (mode) ? address[2:0] : address[3:0]; 


logic [1:0] memory_type;
logic [47:0] SHIFT;
logic [15:0] mem_offset; 
logic [16:0] write_address;
integer i;
logic [5:0] header_count;


	parameter Y_OFFSET = 18'd27648;
	
	parameter U_OFFSET = 18'd55296; 
	
	parameter V_OFFSET = 18'd69120;


//read addressing
			 
			 
always_comb begin

//16x16  
	if (memory_type == 2'd0) begin 
		write_address = Y_OFFSET + col_index + (row_index << 7) + (row_index << 6) + (block_col_index << 4) +  ((block_row_index << 6) + (block_row_index << 7) << 4);
	end 
	
	else if (memory_type == 2'd1) begin 
		write_address = U_OFFSET + col_index + (row_index << 6) + (row_index << 5) + (block_col_index << 3) +  ((block_row_index << 6) + (block_row_index << 5) << 3);
	
	
	end else begin 
	
		write_address = V_OFFSET + col_index + (row_index << 6) + (row_index << 5) + (block_col_index << 3) +  ((block_row_index << 6) + (block_row_index << 5) << 3);
	
	end
	
	
end
		  

 
always_ff @ (posedge Clock or negedge resetn) begin
			if(resetn == 1'b0) begin
			shift_reg <= 48'd0;
			shift_counter <= 5'd0;
			block_row_index <= 6'd0;
			block_col_index <= 6'd0;
			memory_type <= 2'd0;
			remaining_bits <= 5'd0;
			SRAM_we_n <= 1'd1;
			bit_shift_unit <= 5'd0;
			counter  <= 8'd0;
			z_counter<= 8'd0;
			M3_state <= M3_IDLE;
			M3_done <= 1'b0;
			memory_data <= 16'd0;
			bits_left <= 5'd0; 
			SRAM_write_data <= 16'b0; 
			SRAM_address <= 18'b0;  
			SRAM_we_n <= 1'b1;
			mode <= 1'b0;
			mem_offset <= 16'd0;
			flag <= 1'b0;
			flag_2 <= 1'b0;
			flag_3 <= 1'b0;
			flag_4 <= 1'b0;
			flag_5 <= 8'b0;
			flag_6 <= 1'b0;
			flag_7 <= 1'b0;
			flag_8 <= 2'b0;
			store_shift <= 4'b0;
			
			
			end else begin
			case (M3_state)
			M3_IDLE: begin
			header_count <= 5'd0;
			shift_reg <= 48'd0;
			shift_counter <= 5'd0;
			block_row_index <= 6'd0;
			block_col_index <= 6'd0;
			memory_type <= 2'd0;
			remaining_bits <= 5'd0;
			bit_shift_unit <= 5'd0;
			counter  <= 8'd0;
			z_counter<= 8'd0;
			M3_done <= 1'b0;
			flag <= 8'd0;
			memory_data <= 16'd0;
			bits_left <= 5'd16; 
			mem_offset <= 16'd10;
			flag <= 1'b0;
			flag_2 <= 1'b0;
			flag_3 <= 1'b0;
			flag_4 <= 1'b0;
			flag_5 <= 8'b0;
			flag_6 <= 1'b0;
			flag_7 <= 1'b0;
			flag_8 <= 2'b0;
			store_shift <= 4'b0;
			M3_state <= M3_IDLE_1;
			end
			
			M3_IDLE_1: begin
			if(M3_start) begin
			//Read DE AND AD
			if(header_count == 5'd0) begin
			SRAM_address <= mem_offset;
			mem_offset <= mem_offset + 1'b1;//11
			header_count <= header_count + 5'd1;  
			end                                   
			else if(header_count == 5'd1) begin  
			SRAM_address <= mem_offset;
			mem_offset <= mem_offset + 1'b1;//12
			header_count <= header_count + 5'd1;
			end 
			else 
			if(header_count == 5'd2) begin
			SRAM_address <= mem_offset;
			mem_offset <= mem_offset + 1'b1; //13
			header_count <= header_count + 5'd1;
			end 
			else begin
			M3_state <= S_READ_INITIAL_0;
			SRAM_address <= mem_offset; //store 13
			mem_offset <= mem_offset + 1'b1; //14
			shift_reg <= {SRAM_read_data, 32'd0}; //first read last 16 bits 47-32
			header_count <= 5'd0;
			end
			end
			end
			S_READ_INITIAL_0: begin
			//Read the second value
			shift_reg <= {shift_reg[47:32],SRAM_read_data, 16'd0}; //second read bits 32-16
			M3_state <= S_READ_INITIAL_1;
			end
			S_READ_INITIAL_1: begin
			shift_reg <= {shift_reg[47:16],SRAM_read_data}; //last read bits 15 - 0 (this is good) 
			M3_state <= S_READ_INITIAL_2;
			end
			S_READ_INITIAL_2: begin
			//Read the second value
			memory_data <= SRAM_read_data; //atp sram read data is actually the 4th address???  so we store it here?? why? 
			M3_state <= S_READ_2BIT;
			end
			/*S_READ_INITIAL_3: begin
			memory_data <= SRAM_read_data;
			M3_state <= S_READ_2BIT;
			end*/
			S_READ_2BIT: begin
			//check 2 bits value
			if(shift_reg [47:46] == 2'b00) // ok good no issues
			M3_state <= S_00;
			if(shift_reg [47:46] == 2'b01)
			M3_state <= S_01;
			if(shift_reg [47:46] == 2'b10)
			M3_state <= S_10;
			if(shift_reg [47:46] == 2'b11)
			M3_state <= S_11;
			end
			//case 1
			S_00: begin 
			if(shift_reg[45:44] == 2'b00) begin 
				if (z_counter < 8'd4 && flag_4 == 1'b0) begin 
					SRAM_write_data <= 16'd0; 
					SRAM_address <= write_address;
					SRAM_we_n <= 1'b0; 
					z_counter <= z_counter + 8'd1; 
					
					if (flag_8 != 2'b1) begin 
						counter <= counter + 8'd1;
					end
					
					flag_4 <= 1'b1;
					
				end else if (z_counter < 8'd4 && flag_4 == 1'b1) begin 
					flag_4 <= 1'b0;
					SRAM_we_n <= 1'b1;
				end else begin  
				
					if (flag_8 == 2'b1) begin 
						flag_7 <= 1'b1;
						flag_8 <= 2'b0;
					end
					
					M3_state <= S_shift_DETECT; 
					z_counter <= 8'd0; 
					flag_4 <= 1'b0;
					shift_counter <= shift_counter + 5'd4;
					bit_shift_unit <= 5'd4;
					SRAM_we_n <= 1'b1; 
				end
			
			
			end else begin 
				if (z_counter < shift_reg[45:44] && flag_4 == 1'b0) begin 
					SRAM_address <= write_address;
					SRAM_we_n <= 1'b0; 
					SRAM_write_data <= 16'd0; 
					z_counter <= z_counter + 8'd1; 
					
					if (flag_8 != 2'b1) begin 
						counter <= counter + 8'd1;
					end
					
					flag_4 <= 1'b1;	
				end else if (z_counter < 8'd4 && flag_4 == 1'b1) begin 
					flag_4 <= 1'b0;
					SRAM_we_n <= 1'b1; 
				end else begin 
				
					if (flag_8 == 2'b1) begin 
						flag_7 <= 1'b1;
						flag_8 <= 2'b0;
					end
					
					z_counter <= 8'd0;
					shift_counter <= shift_counter + 5'd4;
					bit_shift_unit <= 5'd4;
					SRAM_we_n <= 1'b1; 
					flag_4 <= 1'b0;
					M3_state <= S_shift_DETECT; 
				end
			end
			end
			//case 2
			S_01: begin
			if(z_counter < 8'b1) begin
			SRAM_write_data <= value_1; //done so this has been implemented already (good) 
			SRAM_address <= write_address;
			SRAM_we_n <= 1'b0;
			z_counter <= z_counter + 8'd1;
			end else begin
			shift_counter <= shift_counter + 5'd4; 
			bit_shift_unit <= 5'd4; //ok so thats fine we want to shift 4 bits ok
			z_counter <= 8'd0;
			SRAM_we_n <= 1'b1; 
				if (flag_8 != 2'b1) begin 
						counter <= counter + 8'd1;
				end else begin 
					flag_7 <= 1'b1;
					flag_8 <= 2'b0;
				
				end
			M3_state <= S_shift_DETECT;
			end
			end
			//case 3
			S_10: begin
			if(z_counter < 8'b1) begin
				SRAM_write_data <= value_2; //implemented good
				SRAM_address <= write_address; 
				SRAM_we_n <= 1'b0; 
				z_counter <= z_counter + 8'd1;
			end else begin
				shift_counter <= shift_counter + 5'd11; //good
				bit_shift_unit <= 5'd11; //good
				z_counter <= 8'd0; //good
				SRAM_we_n <= 1'b1; 
				if (flag_8 != 2'b1) begin 
						counter <= counter + 8'd1;
				end else begin 
					flag_7 <= 1'b1;
					flag_8 <= 2'b0;
				
				end
				M3_state <= S_shift_DETECT;
			end
			end
			//case 4
			S_11: begin
			if(mode == 1'b1) begin
				if (flag_5 == 8'd1) begin 
					SRAM_we_n <= 1'b1;
					flag_5 <= flag_5 + 8'd1;
					flag_6 <= 1'b1;
				end
				else if (counter < 8'd63) begin
					SRAM_address <= write_address;
					SRAM_write_data <= 16'd0;
					SRAM_we_n <= 1'b0;
					counter <= counter + 8'd1; //# of value written into the DPRAM	
					flag_5 <= flag_5 + 8'd1;
					flag_6 <= 1'b0;
				end  
				else if (counter == 8'd63 && flag_3 == 1'b0) begin 	
					SRAM_address <= write_address; 
					SRAM_write_data <= 16'd0;      
					SRAM_we_n <= 1'b0; 
					flag_3 <= 1'b1;
					flag_6 <= 1'b0;
				end else begin
					M3_state <= S_shift_DETECT;
					z_counter <= 8'd0;
					shift_counter <= shift_counter + 5'd2;
					bit_shift_unit <= 5'd2;
					SRAM_we_n <= 1'b1; //good
					flag_3  <= 1'b0;
					flag_5 <= 8'd0;
					flag_6 <= 1'b0;
					flag_7<= 1'b1;
				end
			end else begin //mode for Y 
				if (flag_5 == 8'd1) begin 
					SRAM_we_n <= 1'b1;
					flag_5 <= flag_5 + 8'd1;
					flag_6 <= 1'b1;
				end 
				else if (counter < 8'd255) begin
					SRAM_address <= write_address;
					SRAM_write_data <= 16'd0;
					SRAM_we_n <= 1'b0;
					counter <= counter + 8'd1; //# of value written into the DPRAM
					flag_5 <= flag_5 + 8'd1;
					flag_6 <= 1'b0;
				end 	
				else if (counter == 8'd255 && flag_3 == 1'b0) begin 
					SRAM_address <= write_address; 
					SRAM_write_data <= 16'd0;      
					SRAM_we_n <= 1'b0;  
					flag_3 <= 1'b1;
					flag_6 <= 1'b0;
				end else begin 
					M3_state <= S_shift_DETECT; 
					z_counter <= 8'd0;
					shift_counter <= shift_counter + 5'd2; //need this?
					bit_shift_unit <= 5'd2; //need this? or update?
					SRAM_we_n <= 1'b1;
					flag_3  <= 1'b0;
					flag_5 <= 8'd0;
					flag_6 <= 1'b0;
					flag_7 <= 1'b1;
				end
			end
			end
		
		
			
			S_shift_DETECT: begin
			
			if (bit_shift_unit > bits_left) begin //check if we are able to actually shift based on the valid bits in mem data
				store_shift <= bit_shift_unit - bits_left; //store remainder of bits to be shifted by 
				bit_shift_unit <= bits_left; //change so we only shift whats available to be shifted in memory data
				//on the next cycle bit_shift_unit will equal bits_left so itll go to the else block instead	(this part wont re run)
				flag <= 1'b1; //so we can use the sram to find the mem_data value
				flag_2 <= 1'b1;
			end else begin 
				
				if (flag == 1'b1) begin 
					//fill mem data 
					SRAM_address <= mem_offset;
					mem_offset <= mem_offset + 1; //15
					flag <= 1'b0;
				end else begin
				
					if (flag_7 == 1'b1) begin
						flag_6 <= 1'b1;
						flag_7 <= 1'b1;
					end

						//shift register here
					shift_reg <= SHIFT;
					memory_data <= memory_data << bit_shift_unit; 
					bits_left <= bits_left - bit_shift_unit; //problem is this is wrong IF u shifted out all the memory data bits (fix in later state)
					M3_state <= S_BLOCK_END_DETECT;
				
				end
			end
			
			
			
			end
			
			S_BLOCK_END_DETECT: begin
			
			if (flag_7 == 1'b1) begin
				flag_6 <= 1'b0;
				flag_7 <= 1'b0;
			end
			
			//some code here that chekcs if counter == 255 and the flag7 is 0 likewise with counter == 63 
			//if this is the case what happens is we are writing the last value and we havent reached an EOB 
			//the idea now is we ensure we are using a flag_8 (so u can set it here and say) 
			//we are now going to write to 255 and we need to let the address go to 0 by using flag_7
			
			if ((counter == 8'd255 && mode == 1'b0 && flag_7 == 1'b0) || (counter == 8'd63 && mode == 1'b1 && flag_7 == 1'b0))begin 
					flag_8 <= 2'b1;	
			end

			//detect the end of the block
			SRAM_we_n <= 1'b1;
			if(mode == 1'b0) begin //y mode
				if (counter == 8'd255 && flag_7 == 1'b1) begin
					/////////////////update block index//////////////////	
						if(block_col_index == 4'd11) begin
								if (block_row_index == 4'd8) begin
									memory_type <= memory_type + 2'd1;
									mode <= 1'b1;
									block_row_index <= 6'd0;
									block_col_index <= 6'd0;
								end else begin
									block_row_index <= block_row_index + 6'd1; 
									block_col_index <= 6'd0;
										if (flag_2 == 1'b1) begin
											M3_state <= S_WAIT; //to read SRAM_READ_data
										end else begin
											M3_state <= S_READ_2BIT;
										end
								end
								
						end else begin
							block_col_index <= block_col_index + 6'd1;
							
							if (flag_2 == 1'b1) begin
								M3_state <= S_WAIT; //to read SRAM_READ_data
							end else begin
								M3_state <= S_READ_2BIT;
							end
						end
					counter <= 8'd0;
					
				end else begin
						if (flag_2 == 1'b1) begin
							M3_state <= S_WAIT; //to read SRAM_READ_data
						end else begin
							M3_state <= S_READ_2BIT;
						end
				end
					
					
					
			end else begin
				if (counter == 8'd63 && flag_7 == 1'b1) begin
					/////////////////update block index//////////////////
					if(block_col_index == 5'd11) begin
						if (block_row_index == 5'd17) begin
							memory_type <= memory_type + 2'd1;
							block_row_index <= 6'd0;
							block_col_index <= 6'd0;
							if (memory_type == 2'd2) begin
								M3_state <= M3_IDLE;
								M3_done <= 1'b1;
							end
							
						end else begin
							block_row_index <= block_row_index + 6'd1;
							block_col_index <= 6'd0;
							if (flag_2 == 1'b1) begin
								M3_state <= S_WAIT; //to read SRAM_READ_data
							end else begin
								M3_state <= S_READ_2BIT;
							end
						end	
					end else begin
					
						block_col_index <= block_col_index + 6'd1;
						if (flag_2 == 1'b1) begin
							M3_state <= S_WAIT; //to read SRAM_READ_data
						end else begin
							M3_state <= S_READ_2BIT;
						end	
					end
					counter <= 8'd0;
				end else begin
				
					if (flag_2 == 1'b1) begin
						M3_state <= S_WAIT; //to read SRAM_READ_data
					end else begin
						M3_state <= S_READ_2BIT;
					end
				end
			end
		end
		
			S_WAIT: begin
			
			memory_data <= SRAM_read_data;
			bits_left <= 5'd16; //because mem_data is filled
			bit_shift_unit <= store_shift; //set bits_shift_unit to remaining bits to be shifted by 
			flag_2 <= 1'b0;
			
				if (flag_2 == 1'b0) begin 
					//now memoryt_data has the right value and bits_shift unit is shifting the remainder 
					shift_reg <= SHIFT;
					memory_data <= memory_data << bit_shift_unit; 
					bits_left <= bits_left - bit_shift_unit;
					M3_state <= S_READ_2BIT; //read next value
				
				end
			
			end
			
			default: M3_state <= M3_IDLE;
			endcase
			end 
			end
			
always_comb begin
SHIFT = shift_reg;
if (bit_shift_unit == 5'd1) begin
SHIFT = {shift_reg[46:0],memory_data[15]};
end else if (bit_shift_unit == 5'd2) begin
SHIFT = {shift_reg[45:0],memory_data[15:14]};
end else if (bit_shift_unit == 5'd3) begin
SHIFT = {shift_reg[44:0],memory_data[15:13]};
end else if (bit_shift_unit == 5'd4) begin
SHIFT = {shift_reg[43:0],memory_data[15:12]};
end else if (bit_shift_unit == 5'd5) begin
SHIFT = {shift_reg[42:0],memory_data[15:11]};
end else if (bit_shift_unit == 5'd6) begin
SHIFT = {shift_reg[41:0],memory_data[15:10]};
end else if (bit_shift_unit == 5'd7) begin
SHIFT = {shift_reg[40:0],memory_data[15:9]};
end else if (bit_shift_unit == 5'd8) begin
SHIFT = {shift_reg[39:0],memory_data[15:8]};
end else if (bit_shift_unit == 5'd9) begin
SHIFT = {shift_reg[38:0],memory_data[15:7]};
end else if (bit_shift_unit == 5'd10) begin
SHIFT = {shift_reg[37:0],memory_data[15:6]};
end else if (bit_shift_unit == 5'd11) begin
SHIFT = {shift_reg[36:0],memory_data[15:5]};
end 
end




//varaible shifter 


always_comb begin  


	if (mode) begin 

	//U and V block 
	
		if ((row_index + col_index) <= 5'd10) begin 
			
	
			variable_shift = 3'd4;
			
			if ((row_index + col_index) <= 5'd6) begin 
				
				variable_shift = 3'd3;
				
			end
		
			
		end else begin 
		
			variable_shift = 3'd5;
			
		end


	end else begin 

		//Y block
		if ((row_index + col_index) <= 5'd18) begin 

			variable_shift = 3'd4;

			end else begin

			variable_shift = 3'd5;

		end

	end


end



//zig zag and zag zig counters 

logic dir;

always_ff @ (posedge Clock or negedge resetn) begin 


	if (resetn == 1'b0) begin

	address <= 8'd0;
	dir <= 1'b0;
	 
	 end else begin 
	 
	 if(M3_start) begin
	 if(~SRAM_we_n || flag_6)begin //if write enable is 0 or flag_6 is 1
		if (mode) begin
		
			if (address == 8'd63) begin  //reset to 0 after counter finishes (see if this can be optimized and placed elsewhere 
				if (flag_7 == 1'b1) begin
					address <= 8'd0; 
				end

			
			
			end 
	
			else if ((row_index == 4'd0) && (col_index == 4'd7)) begin  //special case (0,7)
				
				address <= address + 8'd8; 
				dir <= ~dir;
			
			end 
		
		
			
			else if ((row_index == 4'd0 || row_index == 4'd7) && (col_index[0] == 1'b1)) begin 
					
					address <= address + 1'b1;
					dir <= ~dir;	
				
			end 
			
			else if ((col_index == 4'd0 || col_index == 4'd7) && (row_index[0] == 1'b0)) begin 
						
					address <= address + 8'd8;
					dir <= ~dir;
						
			end 
			
			
			
			else begin 
			
			
				if (dir) begin 
					address <= address - 8'd7;
				
				end else begin 
				
					address <= address + 8'd7;
				end
				
			
			end
		
			
		
		end else begin 
		
			if (address == 8'd255) begin 
				
				if (flag_7 == 1'b1) begin
					address <= 8'd0; 
				end
	
			
			end
		
		
		
			else if ((row_index == 4'd15) && (col_index == 4'd0)) begin //special case (15,0)
				
					address <= address + 8'b1;
					dir <= ~dir;	
					
			end
		
		
			else if ((row_index == 4'd0 || row_index == 4'd15) && (col_index[0] == 1'b0)) begin 
		
					
					address <= address + 8'b1;
					dir <= ~dir;	
				
			end 
			
			else if ((col_index == 4'd0 || col_index == 4'd15) && (row_index[0] == 1'b1)) begin 
					
					address <= address + 8'd16;
					dir <= ~dir;
						
			end 
			
			
			else begin 
			
			
				if (dir) begin 
					address <= address + 8'd15;
				
				end else begin 
				
					address <= address - 8'd15;
				end
				

			end

		end
	end
	
	end
	
	end

end













endmodule
