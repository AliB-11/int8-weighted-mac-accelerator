`ifndef DEFINE_STATE

// for top state - we have more states than needed
typedef enum logic [2:0] {
	S_IDLE,
	S_UART_RX, //add M1 and M2 here later
	S_M1,
	S_M2, 
	S_M3
} top_state_type;

typedef enum logic [1:0] {
	S_RXC_IDLE,
	S_RXC_SYNC,
	S_RXC_ASSEMBLE_DATA,
	S_RXC_STOP_BIT
} RX_Controller_state_type;

typedef enum logic [2:0] {
	S_US_IDLE,
	S_US_STRIP_FILE_HEADER_1,
	S_US_STRIP_FILE_HEADER_2,
	S_US_START_FIRST_BYTE_RECEIVE,
	S_US_WRITE_FIRST_BYTE,
	S_US_START_SECOND_BYTE_RECEIVE,
	S_US_WRITE_SECOND_BYTE
} UART_SRAM_state_type;

typedef enum logic [3:0] {
	S_VS_WAIT_NEW_PIXEL_ROW,
	S_VS_NEW_PIXEL_ROW_DELAY_1,
	S_VS_NEW_PIXEL_ROW_DELAY_2,
	S_VS_NEW_PIXEL_ROW_DELAY_3,
	S_VS_NEW_PIXEL_ROW_DELAY_4,
	S_VS_NEW_PIXEL_ROW_DELAY_5,
	S_VS_FETCH_PIXEL_DATA_0,
	S_VS_FETCH_PIXEL_DATA_1,
	S_VS_FETCH_PIXEL_DATA_2,
	S_VS_FETCH_PIXEL_DATA_3
} VGA_SRAM_state_type;

typedef enum logic [5:0] {
	S_IDLE_M1,
	S_LI0, 
	S_LI1, 
	S_LI2,
	S_LI3,
	S_LI4,
	S_LI5,
	S_LI6,
	S_LI7,
	S_LI8,
	S_LI9,
	S_LI10,
	S_CC0,
	S_CC1,
	S_CC2, 
	S_CC3, 
	S_CC4, 
	S_CC5, 
	S_CC6, 
	S_CC7 
	
		
} M1_state_type;


typedef enum logic [5:0] {
	S_fetch_IDLE,
	Delay, 
	S_fetch_0, 
	S_fetch_1, 
	S_fetch_2, 
	S_fetch_3, 
	S_fetch_4, 
	S_fetch_5, 
	S_fetch_6, 
	S_fetch_7, 
	S_fetch_8, 
	S_fetch_9, 
	S_fetch_10, 
	S_fetch_11, 
	S_fetch_12, 
	S_fetch_13
	
	
	
} M2_fetch_state_type;


typedef enum logic [3:0] {

	S_write_IDLE,
	S_Delay, 
	S_write_0, 
	S_write_1, 
	S_write_2, 
	S_write_3, 
	S_write_4,
	S_write_5,
	S_write_Delay,
	S_write_Delay2
} M2_write_state_type;


typedef enum logic [4:0] {
	S_CT_DELAY,
	S_CT_IDLE,
	S_LI_T,
	S_CT_0,
	S_CT_1,
	S_CT_2,
	S_CT_3,
	S_CT_4,
	S_CT_5,
	S_CT_6,
	S_CT_7
	
	
} M2_Ct_state_type;



typedef enum logic [4:0] {
	S_CS_DELAY,
	S_CS_IDLE,
	S_LI_S,
	S_CS_0,
	S_CS_1,
	S_CS_2,
	S_CS_3,
	S_CS_4,
	S_CS_5,
	S_CS_6,
	S_CS_7
	
	
} M2_Cs_state_type;


typedef enum logic [4:0] {
	
	S_M2_IDLE, 
	S_M2_fetch_LI,
	S_M2_Ct_LI,
	S_M2_CC1,
	S_M2_CC2,
	S_M2_Cs_LO,
	S_M2_Write_LO
	
	
} M2_driver_state_type;

/*
typedef enum logic [4:0] {
	M3_IDLE,
	S_CS_IDLE,
	S_LI_S,
	S_CS_0,
	S_CS_1,
	S_CS_2,
	S_CS_3,
	S_CS_4,
	S_CS_5,
	S_CS_6,
	S_CS_7
	
	
} M3_state_type;
*/
typedef enum logic [4:0] {
	M3_IDLE,
	M3_IDLE_1,
	S_READ_INITIAL_0,
	S_READ_INITIAL_1,
	S_READ_INITIAL_2,
	S_READ_INITIAL_3,
	S_READ_2BIT,
	S_00,
	S_01,
	S_10,
	S_11,
	S_shift_DETECT,
	S_BLOCK_END_DETECT,
	S_WAIT
} M3_state_type;


//typedef enum logic [3:0] { 
//	
//	S_M3_req_IDLE, 
//	S_M3_req_1, 
//	S_M3_req_2,
//	S_M3_req_3
//	
//} M3_req_state_type; 


parameter 
   VIEW_AREA_LEFT = 224,
   VIEW_AREA_RIGHT = 416,
   VIEW_AREA_TOP = 168,
   VIEW_AREA_BOTTOM = 312;

`define DEFINE_STATE 1
`endif
