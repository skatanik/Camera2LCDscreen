module periphModule(

input clk_sdram,
input clk_lcd,
input clk_cam,
input reset_n,

//lcd
output [7:0] R,
output [7:0] G,
output [7:0] B,
output	HSYNC,
output	VSYNC,
output	LCD_CLK,
output	DE,	 

//camera

output camera_ref_clk,

input camera_vsync,
input camera_hsync,
input camera_pclk,
input [7:0] camera_data,

 
 //sdram 
output	wire [25:0] sdram_mm_slave_address,                //              sdram_mm_slave.address
output	reg [1:0]  sdram_mm_slave_byteenable_n = 0,           //                            .byteenable_n
output	reg        sdram_mm_slave_chipselect = 1,             //                            .chipselect
output	wire [15:0] sdram_mm_slave_writedata,              //                            .writedata
output	wire        sdram_mm_slave_read_n,                 //                            .read_n
output	wire        sdram_mm_slave_write_n,                //                            .write_n
input		wire [15:0] sdram_mm_slave_readdata,               //                            .readdata
input		wire        sdram_mm_slave_readdatavalid,          //                            .readdatavalid
input		wire        sdram_mm_slave_waitrequest            //                            .waitrequest
 
);

wire [15:0] lcd_readdata ;
wire lcd_read;
wire lcd_clock;

wire write_fifo;
wire [15:0] m2f_data;
wire [8:0] lcd_fifo_wrusedw;

fifo_lcd	fifo_lcd_inst (
	.aclr ( ~reset_n ),
	.data ( m2f_data ),
	.rdclk ( clk_lcd ),
	.rdreq ( lcd_read ),
	.wrclk ( clk_sdram ),
	.wrreq ( write_fifo ),
	.q ( lcd_readdata ),
	.wrusedw ( lcd_fifo_wrusedw )
	);

big_lcd lcd0
(
	.clk(clk_lcd),
	.reset(reset_n),
	.lcd_readdata(lcd_readdata),
	.lcd_read(lcd_read),

	.R(R),
	.G(G),
	.B(B),
	.HSYNC(HSYNC),
	.VSYNC(VSYNC),
	.LCD_CLK(LCD_CLK)
);

wire [15:0] cam2fifo_data;
wire cam2fifo_wrreq;
wire cam2fifo_wrclk;
wire [8:0] cam2fifo_rdusedw;
reg sdram_mm_slave_write_n_reg;

cameraReader camera
(
	.clk(clk_cam),
	.reset_n(reset_n),
	
	.refclk(camera_ref_clk),
	
	.pclk(camera_pclk),
	.data(camera_data),
	.vsync(camera_vsync),
	.hsync(camera_hsync),
	
	.data_out(cam2fifo_data),
	.wrreq(cam2fifo_wrreq),
	.wrclk(cam2fifo_wrclk)

);

reg [2:0] cam_vsync_cdc;

always@(posedge clk_sdram)
cam_vsync_cdc <= {cam_vsync_cdc[1:0], camera_vsync};


reg [2:0] fifo_states = 0;	

cam_fifo	cam_fifo_inst (
	.data ( cam2fifo_data ),
	.wrclk ( cam2fifo_wrclk ),
	.wrreq ( cam2fifo_wrreq ),
	
	.q ( sdram_mm_slave_writedata ),
	.rdclk ( clk_sdram ),
	.rdreq ( (sdram_mm_slave_waitrequest == 0) & (fifo_states == 1) ? 1 : 0 ),
	.rdusedw ( cam2fifo_rdusedw )
	);
	
always@(posedge clk_sdram)
sdram_mm_slave_write_n_reg <= (sdram_mm_slave_waitrequest == 0) && (fifo_states == 1) ? 0 : 1;
	
reg [15:0] lcd_pixel_counter = 0;
	
reg [24:0] 	camera_addr_pointer = 0;
reg [24:0] 	lcd_addr_pointer = 0;

reg [15:0] pixel_color;

assign sdram_mm_slave_address = fifo_states == 0 ? lcd_addr_pointer : camera_addr_pointer;
assign m2f_data = sdram_mm_slave_readdata;
assign write_fifo = sdram_mm_slave_readdatavalid & (fifo_states == 0);
assign sdram_mm_slave_read_n = fifo_states == 0 ? 0 : 1;
assign sdram_mm_slave_write_n = (sdram_mm_slave_waitrequest == 0) && (fifo_states == 1) ? 0 : 1;

//assign sdram_mm_slave_writedata = pixel_color;

always@(posedge clk_sdram)
begin
if(reset_n == 0)
begin
	fifo_states <= 0;
	camera_addr_pointer <= 0;
	lcd_addr_pointer <= 0;
end
else 
begin

case (fifo_states)
	0:	//fill lcd fifo
	begin
				
		if(lcd_fifo_wrusedw >= 500 && cam2fifo_rdusedw >= 500)
			fifo_states <= 1;
		else
		if(lcd_fifo_wrusedw >= 500 && cam2fifo_rdusedw > 2 && cam2fifo_rdusedw < 500)
			fifo_states <= 1;
		else
		if(lcd_fifo_wrusedw <= 2 && cam2fifo_rdusedw >= 500)
			fifo_states <= 1;
		else
		if(lcd_fifo_wrusedw < 500 && lcd_fifo_wrusedw > 2 && cam2fifo_rdusedw >= 500)
			fifo_states <= 1;
		///////////////////////////////////////////
		if(lcd_fifo_wrusedw <= 2 && cam2fifo_rdusedw <= 2)
			fifo_states <= 0;
		else 
		if(lcd_fifo_wrusedw <= 2 && cam2fifo_rdusedw > 2 && cam2fifo_rdusedw < 500)
			fifo_states <= 0;
		else
		if(lcd_fifo_wrusedw < 500 && lcd_fifo_wrusedw > 2 && cam2fifo_rdusedw <= 2)
			fifo_states <= 0;
		else
		if(lcd_fifo_wrusedw < 500 && lcd_fifo_wrusedw > 2 && cam2fifo_rdusedw > 2 && cam2fifo_rdusedw < 500)
			fifo_states <= 0;
		////////////////////
		else 
		if(lcd_fifo_wrusedw >= 500 && cam2fifo_rdusedw <= 2)
			fifo_states <= 2;		
		

		if(sdram_mm_slave_readdatavalid == 1)
			if(lcd_addr_pointer == 640*480 - 1)
			begin
				lcd_addr_pointer <= 0;
				
			end
			else
				lcd_addr_pointer <= lcd_addr_pointer + 1;
			
	end
	
	1:	//write from camera fifo
	begin
		
		if(sdram_mm_slave_waitrequest == 0)
		if(camera_addr_pointer == 640*480 - 1)
		begin
			camera_addr_pointer <= 0;
			
		end
			else
			begin
				camera_addr_pointer <= camera_addr_pointer + 1;
				
			end
	
		if(lcd_fifo_wrusedw >= 500 && cam2fifo_rdusedw >= 500)
			fifo_states <= 1;
		else
		if(lcd_fifo_wrusedw >= 500 && cam2fifo_rdusedw > 2 && cam2fifo_rdusedw < 500)
			fifo_states <= 1;
		else
		if(lcd_fifo_wrusedw <= 2 && cam2fifo_rdusedw >= 500)
			fifo_states <= 1;
		else
		if(lcd_fifo_wrusedw < 500 && lcd_fifo_wrusedw > 2 && cam2fifo_rdusedw >= 500)
			fifo_states <= 1;
		///////////////////////////////////////////
		if(lcd_fifo_wrusedw <= 2 && cam2fifo_rdusedw <= 2)
			fifo_states <= 0;
		else 
		if(lcd_fifo_wrusedw <= 2 && cam2fifo_rdusedw > 2 && cam2fifo_rdusedw < 500)
			fifo_states <= 0;
		else
		if(lcd_fifo_wrusedw < 500 && lcd_fifo_wrusedw > 2 && cam2fifo_rdusedw <= 2)
			fifo_states <= 0;
		else
		if(lcd_fifo_wrusedw < 500 && lcd_fifo_wrusedw > 2 && cam2fifo_rdusedw > 2 && cam2fifo_rdusedw < 500)
			fifo_states <= 0;
		////////////////////
		else 
		if(lcd_fifo_wrusedw >= 500 && cam2fifo_rdusedw <= 2)
			fifo_states <= 2;	

	end
	
	2:
	begin
	
		if(lcd_fifo_wrusedw >= 500 && cam2fifo_rdusedw >= 500)
			fifo_states <= 1;
		else
		if(lcd_fifo_wrusedw >= 500 && cam2fifo_rdusedw > 2 && cam2fifo_rdusedw < 500)
			fifo_states <= 1;
		else
		if(lcd_fifo_wrusedw <= 2 && cam2fifo_rdusedw >= 500)
			fifo_states <= 1;
		else
		if(lcd_fifo_wrusedw < 500 && lcd_fifo_wrusedw > 2 && cam2fifo_rdusedw >= 500)
			fifo_states <= 1;
		///////////////////////////////////////////
		if(lcd_fifo_wrusedw <= 2 && cam2fifo_rdusedw <= 2)
			fifo_states <= 0;
		else 
		if(lcd_fifo_wrusedw <= 2 && cam2fifo_rdusedw > 2 && cam2fifo_rdusedw < 500)
			fifo_states <= 0;
		else
		if(lcd_fifo_wrusedw < 500 && lcd_fifo_wrusedw > 2 && cam2fifo_rdusedw <= 2)
			fifo_states <= 0;
		else
		if(lcd_fifo_wrusedw < 500 && lcd_fifo_wrusedw > 2 && cam2fifo_rdusedw > 2 && cam2fifo_rdusedw < 500)
			fifo_states <= 0;
		////////////////////
		else 
		if(lcd_fifo_wrusedw >= 500 && cam2fifo_rdusedw <= 2)
			fifo_states <= 2;		
		
	end
	
	default:
	begin
	end
endcase

		if(cam_vsync_cdc == 3'b111)
			if(cam2fifo_rdusedw == 0)
			camera_addr_pointer <= 0;
			else
			camera_addr_pointer <= 640*480 - cam2fifo_rdusedw - 1;

end

end	



endmodule