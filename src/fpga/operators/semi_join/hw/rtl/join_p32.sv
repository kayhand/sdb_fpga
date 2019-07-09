module join_p32
   (
    input  logic clk,
    
    input  logic reset,
    input  logic en,
    
    input  logic [511:0] fk_block,
    input  logic [2555:0]  bit_map,
        
    output logic [31:0] bit_result
    );
	
	always_ff @(posedge clk)		
	begin		
		logic [15:0] fk_index;	
		if (reset)	
		begin			
			bit_result[0] <= 1'b0;
		end	
		else if (en)	
		begin
			fk_index <= fk_block[15:0];
			bit_result[0] <= bit_map[fk_index];
			$display("join unit 1!");
		end	
	end		
		
	always_ff @(posedge clk)		
	begin		
		logic [15:0] fk_index;	
		if (reset)	
		begin	
		
			bit_result[1] <= 1'b0;
		end	
		else if (en)	
		begin	
			fk_index <= fk_block[31:16];
			bit_result[1] <= bit_map[fk_index];
		end	
	end		
		
	always_ff @(posedge clk)		
	begin		
		logic [15:0] fk_index;	
		if (reset)	
		begin	
		
			bit_result[2] <= 1'b0;
		end	
		else if (en)	
		begin	
			fk_index <= fk_block[47:32];
			bit_result[2] <= bit_map[fk_index];
		end	
	end		
		
	always_ff @(posedge clk)		
	begin		
		logic [15:0] fk_index;	
		if (reset)	
		begin	
		
			bit_result[3] <= 1'b0;
		end	
		else if (en)	
		begin	
			fk_index <= fk_block[63:48];
			bit_result[3] <= bit_map[fk_index];
		end	
	end		
		
	always_ff @(posedge clk)		
	begin		
		logic [15:0] fk_index;	
		if (reset)	
		begin	
		
			bit_result[4] <= 1'b0;
		end	
		else if (en)	
		begin	
			fk_index <= fk_block[79:64];
			bit_result[4] <= bit_map[fk_index];
		end	
	end		
		
	always_ff @(posedge clk)		
	begin		
		logic [15:0] fk_index;	
		if (reset)	
		begin	
		
			bit_result[5] <= 1'b0;
		end	
		else if (en)	
		begin	
			fk_index <= fk_block[95:80];
			bit_result[5] <= bit_map[fk_index];
		end	
	end		
		
	always_ff @(posedge clk)		
	begin		
		logic [15:0] fk_index;	
		if (reset)	
		begin	
		
			bit_result[6] <= 1'b0;
		end	
		else if (en)	
		begin	
			fk_index <= fk_block[111:96];
			bit_result[6] <= bit_map[fk_index];
		end	
	end		
		
	always_ff @(posedge clk)		
	begin		
		logic [15:0] fk_index;	
		if (reset)	
		begin	
		
			bit_result[7] <= 1'b0;
		end	
		else if (en)	
		begin	
			fk_index <= fk_block[127:112];
			bit_result[7] <= bit_map[fk_index];
		end	
	end		
		
	always_ff @(posedge clk)		
	begin		
		logic [15:0] fk_index;	
		if (reset)	
		begin	
		
			bit_result[8] <= 1'b0;
		end	
		else if (en)	
		begin	
			fk_index <= fk_block[143:128];
			bit_result[8] <= bit_map[fk_index];
		end	
	end		
		
	always_ff @(posedge clk)		
	begin		
		logic [15:0] fk_index;	
		if (reset)	
		begin	
		
			bit_result[9] <= 1'b0;
		end	
		else if (en)	
		begin	
			fk_index <= fk_block[159:144];
			bit_result[9] <= bit_map[fk_index];
		end	
	end		
		
	always_ff @(posedge clk)		
	begin		
		logic [15:0] fk_index;	
		if (reset)	
		begin	
		
			bit_result[10] <= 1'b0;
		end	
		else if (en)	
		begin	
			fk_index <= fk_block[175:160];
			bit_result[10] <= bit_map[fk_index];
		end	
	end		
		
	always_ff @(posedge clk)		
	begin		
		logic [15:0] fk_index;	
		if (reset)	
		begin	
		
			bit_result[11] <= 1'b0;
		end	
		else if (en)	
		begin	
			fk_index <= fk_block[191:176];
			bit_result[11] <= bit_map[fk_index];
		end	
	end		
		
	always_ff @(posedge clk)		
	begin		
		logic [15:0] fk_index;	
		if (reset)	
		begin	
		
			bit_result[12] <= 1'b0;
		end	
		else if (en)	
		begin	
			fk_index <= fk_block[207:192];
			bit_result[12] <= bit_map[fk_index];
		end	
	end		
		
	always_ff @(posedge clk)		
	begin		
		logic [15:0] fk_index;	
		if (reset)	
		begin	
		
			bit_result[13] <= 1'b0;
		end	
		else if (en)	
		begin	
			fk_index <= fk_block[223:208];
			bit_result[13] <= bit_map[fk_index];
		end	
	end		
		
	always_ff @(posedge clk)		
	begin		
		logic [15:0] fk_index;	
		if (reset)	
		begin	
		
			bit_result[14] <= 1'b0;
		end	
		else if (en)	
		begin	
			fk_index <= fk_block[239:224];
			bit_result[14] <= bit_map[fk_index];
		end	
	end		
		
	always_ff @(posedge clk)		
	begin		
		logic [15:0] fk_index;	
		if (reset)	
		begin	
		
			bit_result[15] <= 1'b0;
		end	
		else if (en)	
		begin	
			fk_index <= fk_block[255:240];
			bit_result[15] <= bit_map[fk_index];
		end	
	end		
		
	always_ff @(posedge clk)		
	begin		
		logic [15:0] fk_index;	
		if (reset)	
		begin	
		
			bit_result[16] <= 1'b0;
		end	
		else if (en)	
		begin	
			fk_index <= fk_block[271:256];
			bit_result[16] <= bit_map[fk_index];
		end	
	end		
		
	always_ff @(posedge clk)		
	begin		
		logic [15:0] fk_index;	
		if (reset)	
		begin	
		
			bit_result[17] <= 1'b0;
		end	
		else if (en)	
		begin	
			fk_index <= fk_block[287:272];
			bit_result[17] <= bit_map[fk_index];
		end	
	end		
		
	always_ff @(posedge clk)		
	begin		
		logic [15:0] fk_index;	
		if (reset)	
		begin	
		
			bit_result[18] <= 1'b0;
		end	
		else if (en)	
		begin	
			fk_index <= fk_block[303:288];
			bit_result[18] <= bit_map[fk_index];
		end	
	end		
		
	always_ff @(posedge clk)		
	begin		
		logic [15:0] fk_index;	
		if (reset)	
		begin	
		
			bit_result[19] <= 1'b0;
		end	
		else if (en)	
		begin	
			fk_index <= fk_block[319:304];
			bit_result[19] <= bit_map[fk_index];
		end	
	end		
		
	always_ff @(posedge clk)		
	begin		
		logic [15:0] fk_index;	
		if (reset)	
		begin	
		
			bit_result[20] <= 1'b0;
		end	
		else if (en)	
		begin	
			fk_index <= fk_block[335:320];
			bit_result[20] <= bit_map[fk_index];
		end	
	end		
		
	always_ff @(posedge clk)		
	begin		
		logic [15:0] fk_index;	
		if (reset)	
		begin	
		
			bit_result[21] <= 1'b0;
		end	
		else if (en)	
		begin	
			fk_index <= fk_block[351:336];
			bit_result[21] <= bit_map[fk_index];
		end	
	end		
		
	always_ff @(posedge clk)		
	begin		
		logic [15:0] fk_index;	
		if (reset)	
		begin	
		
			bit_result[22] <= 1'b0;
		end	
		else if (en)	
		begin	
			fk_index <= fk_block[367:352];
			bit_result[22] <= bit_map[fk_index];
		end	
	end		
		
	always_ff @(posedge clk)		
	begin		
		logic [15:0] fk_index;	
		if (reset)	
		begin	
		
			bit_result[23] <= 1'b0;
		end	
		else if (en)	
		begin	
			fk_index <= fk_block[383:368];
			bit_result[23] <= bit_map[fk_index];
		end	
	end		
		
	always_ff @(posedge clk)		
	begin		
		logic [15:0] fk_index;	
		if (reset)	
		begin	
		
			bit_result[24] <= 1'b0;
		end	
		else if (en)	
		begin	
			fk_index <= fk_block[399:384];
			bit_result[24] <= bit_map[fk_index];
		end	
	end		
		
	always_ff @(posedge clk)		
	begin		
		logic [15:0] fk_index;	
		if (reset)	
		begin	
		
			bit_result[25] <= 1'b0;
		end	
		else if (en)	
		begin	
			fk_index <= fk_block[415:400];
			bit_result[25] <= bit_map[fk_index];
		end	
	end		
		
	always_ff @(posedge clk)		
	begin		
		logic [15:0] fk_index;	
		if (reset)	
		begin	
		
			bit_result[26] <= 1'b0;
		end	
		else if (en)	
		begin	
			fk_index <= fk_block[431:416];
			bit_result[26] <= bit_map[fk_index];
		end	
	end		
		
	always_ff @(posedge clk)		
	begin		
		logic [15:0] fk_index;	
		if (reset)	
		begin	
		
			bit_result[27] <= 1'b0;
		end	
		else if (en)	
		begin	
			fk_index <= fk_block[447:432];
			bit_result[27] <= bit_map[fk_index];
		end	
	end		
		
	always_ff @(posedge clk)		
	begin		
		logic [15:0] fk_index;	
		if (reset)	
		begin	
		
			bit_result[28] <= 1'b0;
		end	
		else if (en)	
		begin	
			fk_index <= fk_block[463:448];
			bit_result[28] <= bit_map[fk_index];
		end	
	end		
		
	always_ff @(posedge clk)		
	begin		
		logic [15:0] fk_index;	
		if (reset)	
		begin	
		
			bit_result[29] <= 1'b0;
		end	
		else if (en)	
		begin	
			fk_index <= fk_block[479:464];
			bit_result[29] <= bit_map[fk_index];
		end	
	end		
		
	always_ff @(posedge clk)		
	begin		
		logic [15:0] fk_index;	
		if (reset)	
		begin	
		
			bit_result[30] <= 1'b0;
		end	
		else if (en)	
		begin	
			fk_index <= fk_block[495:480];
			bit_result[30] <= bit_map[fk_index];
		end	
	end		
		
	always_ff @(posedge clk)		
	begin		
		logic [15:0] fk_index;	
		if (reset)	
		begin	
		
			bit_result[31] <= 1'b0;
		end	
		else if (en)	
		begin	
			fk_index <= fk_block[511:496];
			bit_result[31] <= bit_map[fk_index];
		end	
	end		
	
endmodule
