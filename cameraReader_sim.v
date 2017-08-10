module cameraReader_sim
(

	input clk,
	input reset_n,
	
	output refclk,
	
	input pclk,
	input [7:0] data,
	input vsync,
	input hsync,
	
	output [15:0] data_out,
	output wire wrreq,
	output wire wrclk

);

reg wrclk1 = 0;

always@(negedge clk)
wrclk1 <= ~wrclk1;

reg [19:0] pixel_counter;
reg [9:0] wait_counter_hs;
reg [19:0] wait_counter_vs;

reg [1:0] state = 0;

assign wrclk = clk;

assign wrreq = state == 2'b01 ? wrclk1 : 1'b0;

assign data_out = pixel_counter % 640;

always@(posedge wrclk1)
begin
if(reset_n == 1'b0)
	begin
	pixel_counter <= 0;
	wait_counter_vs <= 0;
	wait_counter_hs <= 0;
	end
	else
	begin
		case(state)
		2'b00:
		begin
			if(wait_counter_vs == 15679)
			begin
				wait_counter_vs <= 0;
				state <= 2'b01;
				pixel_counter <= pixel_counter + 1;
			end
			else
				wait_counter_vs <= wait_counter_vs + 1;
		end
		
		2'b01:
		begin
			if(pixel_counter % 640 == 0)
			begin
				if(pixel_counter == 640*480)
				begin
					pixel_counter <= 0;
					state <= 2'b11; //vs wait
				end
				else
					state <= 2'b10; // hs wait
			end
			else
				pixel_counter <= pixel_counter + 1;
			
		end
		
		2'b10:
		begin
			if(wait_counter_hs == 144)
			begin
				wait_counter_hs <= 0;
				state <= 2'b01;
				pixel_counter <= pixel_counter + 1;
			end
			else
				wait_counter_hs <= wait_counter_hs + 1;
		end
		
		2'b11:
		begin
			if(wait_counter_vs == 7839)
			begin
				wait_counter_vs <= 0;
				state <= 2'b00;
			end
			else
				wait_counter_vs <= wait_counter_vs + 1;
		end
		
		endcase
		
		
		
		
	
	end
end

endmodule 