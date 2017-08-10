module sev_seg_decoder
(
	input [3:0] number,
	
	output [6:0] digit

);

assign digit = ~(	number == 	4'h0  ? 7'b0111111:
						number ==	4'h1  ? 7'b0000110:
						number ==	4'h2  ? 7'b1011011:
						number ==	4'h3  ? 7'b1001111:
						number ==	4'h4  ? 7'b1100110:
						number ==	4'h5  ? 7'b1101101:
						number ==	4'h6  ? 7'b1111101:
						number ==	4'h7  ? 7'b0000111:
						number ==	4'h8  ? 7'b1111111:
						number ==	4'h9  ? 7'b1101111:
												  7'b0000000
						);


endmodule