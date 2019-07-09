module filter_scan_p32_s2
   (
    input  logic clk,
    
    input  logic reset,
    input  logic en,
    
    input  logic [511:0] incoming_cl,
    input  logic [7:0]  predicate,
        
    output logic [63:0] bit_result
    );
	
	always_ff @(posedge clk)		
	begin		
		if (reset)	
		begin	
			bit_result[0] <= 1'b0;
			bit_result[1] <= 1'b0;
		end	
		else if (en)	
		begin	
			bit_result[0] <= (incoming_cl[7:0] <= predicate);
			bit_result[1] <= (incoming_cl[15:8] <= predicate);
		end	
	end	
		
		
	always_ff @(posedge clk)		
	begin		
		if (reset)	
		begin	
			bit_result[2] <= 1'b0;
			bit_result[3] <= 1'b0;
		end	
		else if (en)	
		begin	
			bit_result[2] <= (incoming_cl[23:16] <= predicate);
			bit_result[3] <= (incoming_cl[31:24] <= predicate);
		end	
	end		
		
		
	always_ff @(posedge clk)		
	begin		
		if (reset)	
		begin	
			bit_result[4] <= 1'b0;
			bit_result[5] <= 1'b0;
		end	
		else if (en)	
		begin	
			bit_result[4] <= (incoming_cl[39:32] <= predicate);
			bit_result[5] <= (incoming_cl[47:40] <= predicate);
		end	
	end		
		
		
	always_ff @(posedge clk)		
	begin		
		if (reset)	
		begin	
			bit_result[6] <= 1'b0;
			bit_result[7] <= 1'b0;
		end	
		else if (en)	
		begin	
			bit_result[6] <= (incoming_cl[55:48] <= predicate);
			bit_result[7] <= (incoming_cl[63:56] <= predicate);
		end	
	end		
		
		
		
		
	always_ff @(posedge clk)		
	begin		
		if (reset)	
		begin	
			bit_result[8] <= 1'b0;
			bit_result[9] <= 1'b0;
		end	
		else if (en)	
		begin	
			bit_result[8] <= (incoming_cl[71:64] <= predicate);
			bit_result[9] <= (incoming_cl[79:72] <= predicate);
		end	
	end		
		
		
	always_ff @(posedge clk)		
	begin		
		if (reset)	
		begin	
			bit_result[10] <= 1'b0;
			bit_result[11] <= 1'b0;
		end	
		else if (en)	
		begin	
			bit_result[10] <= (incoming_cl[87:80] <= predicate);
			bit_result[11] <= (incoming_cl[95:88] <= predicate);
		end	
	end		
		
		
		
		
	always_ff @(posedge clk)		
	begin		
		if (reset)	
		begin	
			bit_result[12] <= 1'b0;
			bit_result[13] <= 1'b0;
		end	
		else if (en)	
		begin	
			bit_result[12] <= (incoming_cl[103:96] <= predicate);
			bit_result[13] <= (incoming_cl[111:104] <= predicate);
		end	
	end		
		
		
	always_ff @(posedge clk)		
	begin		
		if (reset)	
		begin	
			bit_result[14] <= 1'b0;
			bit_result[15] <= 1'b0;
		end	
		else if (en)	
		begin	
			bit_result[14] <= (incoming_cl[119:112] <= predicate);
			bit_result[15] <= (incoming_cl[127:120] <= predicate);
		end	
	end		
		
		
		
		
	always_ff @(posedge clk)		
	begin		
		if (reset)	
		begin	
			bit_result[16] <= 1'b0;
			bit_result[17] <= 1'b0;
		end	
		else if (en)	
		begin	
			bit_result[16] <= (incoming_cl[135:128] <= predicate);
			bit_result[17] <= (incoming_cl[143:136] <= predicate);
		end	
	end		
		
		
	always_ff @(posedge clk)		
	begin		
		if (reset)	
		begin	
			bit_result[18] <= 1'b0;
			bit_result[19] <= 1'b0;
		end	
		else if (en)	
		begin	
			bit_result[18] <= (incoming_cl[151:144] <= predicate);
			bit_result[19] <= (incoming_cl[159:152] <= predicate);
		end	
	end		
		
		
		
		
	always_ff @(posedge clk)		
	begin		
		if (reset)	
		begin	
			bit_result[20] <= 1'b0;
			bit_result[21] <= 1'b0;
		end	
		else if (en)	
		begin	
			bit_result[20] <= (incoming_cl[167:160] <= predicate);
			bit_result[21] <= (incoming_cl[175:168] <= predicate);
		end	
	end		
		
		
	always_ff @(posedge clk)		
	begin		
		if (reset)	
		begin	
			bit_result[22] <= 1'b0;
			bit_result[23] <= 1'b0;
		end	
		else if (en)	
		begin	
			bit_result[22] <= (incoming_cl[183:176] <= predicate);
			bit_result[23] <= (incoming_cl[191:184] <= predicate);
		end	
	end		
		
		
		
		
	always_ff @(posedge clk)		
	begin		
		if (reset)	
		begin	
			bit_result[24] <= 1'b0;
			bit_result[25] <= 1'b0;
		end	
		else if (en)	
		begin	
			bit_result[24] <= (incoming_cl[199:192] <= predicate);
			bit_result[25] <= (incoming_cl[207:200] <= predicate);
		end	
	end		
		
		
	always_ff @(posedge clk)		
	begin		
		if (reset)	
		begin	
			bit_result[26] <= 1'b0;
			bit_result[27] <= 1'b0;
		end	
		else if (en)	
		begin	
			bit_result[26] <= (incoming_cl[215:208] <= predicate);
			bit_result[27] <= (incoming_cl[223:216] <= predicate);
		end	
	end		
		
		
	always_ff @(posedge clk)		
	begin		
		if (reset)	
		begin	
			bit_result[28] <= 1'b0;
			bit_result[29] <= 1'b0;
		end	
		else if (en)	
		begin	
			bit_result[28] <= (incoming_cl[231:224] <= predicate);
			bit_result[29] <= (incoming_cl[239:232] <= predicate);
		end	
	end		
		
		
	always_ff @(posedge clk)		
	begin		
		if (reset)	
		begin	
			bit_result[30] <= 1'b0;
			bit_result[31] <= 1'b0;
		end	
		else if (en)	
		begin	
			bit_result[30] <= (incoming_cl[247:240] <= predicate);
			bit_result[31] <= (incoming_cl[255:248] <= predicate);
		end	
	end		
		
		
	always_ff @(posedge clk)		
	begin		
		if (reset)	
		begin	
			bit_result[32] <= 1'b0;
			bit_result[33] <= 1'b0;
		end	
		else if (en)	
		begin	
			bit_result[32] <= (incoming_cl[263:256] <= predicate);
			bit_result[33] <= (incoming_cl[271:264] <= predicate);
		end	
	end		
		
		
	always_ff @(posedge clk)		
	begin		
		if (reset)	
		begin	
			bit_result[34] <= 1'b0;
			bit_result[35] <= 1'b0;
		end	
		else if (en)	
		begin	
			bit_result[34] <= (incoming_cl[279:272] <= predicate);
			bit_result[35] <= (incoming_cl[287:280] <= predicate);
		end	
	end		
		
		
	always_ff @(posedge clk)		
	begin		
		if (reset)	
		begin	
			bit_result[36] <= 1'b0;
			bit_result[37] <= 1'b0;
		end	
		else if (en)	
		begin	
			bit_result[36] <= (incoming_cl[295:288] <= predicate);
			bit_result[37] <= (incoming_cl[303:296] <= predicate);
		end	
	end		
		
		
	always_ff @(posedge clk)		
	begin		
		if (reset)	
		begin	
			bit_result[38] <= 1'b0;
			bit_result[39] <= 1'b0;
		end	
		else if (en)	
		begin	
			bit_result[38] <= (incoming_cl[311:304] <= predicate);
			bit_result[39] <= (incoming_cl[319:312] <= predicate);
		end	
	end		
		
		
	always_ff @(posedge clk)		
	begin		
		if (reset)	
		begin	
			bit_result[40] <= 1'b0;
			bit_result[41] <= 1'b0;
		end	
		else if (en)	
		begin	
			bit_result[40] <= (incoming_cl[327:320] <= predicate);
			bit_result[41] <= (incoming_cl[335:328] <= predicate);
		end	
	end		
		
		
	always_ff @(posedge clk)		
	begin		
		if (reset)	
		begin	
			bit_result[42] <= 1'b0;
			bit_result[43] <= 1'b0;
		end	
		else if (en)	
		begin	
			bit_result[42] <= (incoming_cl[343:336] <= predicate);
			bit_result[43] <= (incoming_cl[351:344] <= predicate);
		end	
	end		
		
		
	always_ff @(posedge clk)		
	begin		
		if (reset)	
		begin	
			bit_result[44] <= 1'b0;
			bit_result[45] <= 1'b0;
		end	
		else if (en)	
		begin	
			bit_result[44] <= (incoming_cl[359:352] <= predicate);
			bit_result[45] <= (incoming_cl[367:360] <= predicate);
		end	
	end		
		
		
	always_ff @(posedge clk)		
	begin		
		if (reset)	
		begin	
			bit_result[46] <= 1'b0;
			bit_result[47] <= 1'b0;
		end	
		else if (en)	
		begin	
			bit_result[46] <= (incoming_cl[375:368] <= predicate);
			bit_result[47] <= (incoming_cl[383:376] <= predicate);
		end	
	end		
		
		
	always_ff @(posedge clk)		
	begin		
		if (reset)	
		begin	
			bit_result[48] <= 1'b0;
			bit_result[49] <= 1'b0;
		end	
		else if (en)	
		begin	
			bit_result[48] <= (incoming_cl[391:384] <= predicate);
			bit_result[49] <= (incoming_cl[399:392] <= predicate);
		end	
	end		
		
		
	always_ff @(posedge clk)		
	begin		
		if (reset)	
		begin	
			bit_result[50] <= 1'b0;
			bit_result[51] <= 1'b0;
		end	
		else if (en)	
		begin	
			bit_result[50] <= (incoming_cl[407:400] <= predicate);
			bit_result[51] <= (incoming_cl[415:408] <= predicate);
		end	
	end		
		
		
	always_ff @(posedge clk)		
	begin		
		if (reset)	
		begin	
			bit_result[52] <= 1'b0;
			bit_result[53] <= 1'b0;
		end	
		else if (en)	
		begin	
			bit_result[52] <= (incoming_cl[423:416] <= predicate);
			bit_result[53] <= (incoming_cl[431:424] <= predicate);
		end	
	end		
		
		
	always_ff @(posedge clk)		
	begin		
		if (reset)	
		begin	
			bit_result[54] <= 1'b0;
			bit_result[55] <= 1'b0;
		end	
		else if (en)	
		begin	
			bit_result[54] <= (incoming_cl[439:432] <= predicate);
			bit_result[55] <= (incoming_cl[447:440] <= predicate);
		end	
	end		
		
		
	always_ff @(posedge clk)		
	begin		
		if (reset)	
		begin	
			bit_result[56] <= 1'b0;
			bit_result[57] <= 1'b0;
		end	
		else if (en)	
		begin	
			bit_result[56] <= (incoming_cl[455:448] <= predicate);
			bit_result[57] <= (incoming_cl[463:456] <= predicate);
		end	
	end		
		
		
	always_ff @(posedge clk)		
	begin		
		if (reset)	
		begin	
			bit_result[58] <= 1'b0;
			bit_result[59] <= 1'b0;
		end	
		else if (en)	
		begin	
			bit_result[58] <= (incoming_cl[471:464] <= predicate);
			bit_result[59] <= (incoming_cl[479:472] <= predicate);
		end	
	end		
		
		
	always_ff @(posedge clk)		
	begin		
		if (reset)	
		begin	
			bit_result[60] <= 1'b0;
			bit_result[61] <= 1'b0;
		end	
		else if (en)	
		begin	
			bit_result[60] <= (incoming_cl[487:480] <= predicate);
			bit_result[61] <= (incoming_cl[495:488] <= predicate);
		end	
	end		
		
		
	always_ff @(posedge clk)		
	begin		
		if (reset)	
		begin	
			bit_result[62] <= 1'b0;
			bit_result[63] <= 1'b0;
		end	
		else if (en)	
		begin	
			bit_result[62] <= (incoming_cl[503:496] <= predicate);
			bit_result[63] <= (incoming_cl[511:504] <= predicate);
		end	
	end		
	
endmodule
