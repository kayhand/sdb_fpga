// 16-bit encoding
module p32_1block 
   (
    input  logic clk,
    
    input  logic reset,
    input  logic en,
    
    input  logic [511:0] incoming_cl,
    input  logic [15:0]  predicate,
        
    output logic [31:0] bit_result    
    );
	
	always_ff @(posedge clk)		
	begin		
		if (reset)	
		begin	
			bit_result <= 32'b0;
		end	
		else if (en)	
		begin	
			bit_result[0] <= (incoming_cl[15:0] <= predicate);
			bit_result[1] <= (incoming_cl[31:16] <= predicate);
			bit_result[2] <= (incoming_cl[47:32] <= predicate);
			bit_result[3] <= (incoming_cl[63:48] <= predicate);
			bit_result[4] <= (incoming_cl[79:64] <= predicate);
			bit_result[5] <= (incoming_cl[95:80] <= predicate);
			bit_result[6] <= (incoming_cl[111:96] <= predicate);
			bit_result[7] <= (incoming_cl[127:112] <= predicate);
			bit_result[8] <= (incoming_cl[143:128] <= predicate);
			bit_result[9] <= (incoming_cl[159:144] <= predicate);
			bit_result[10] <= (incoming_cl[175:160] <= predicate);
			bit_result[11] <= (incoming_cl[191:176] <= predicate);
			bit_result[12] <= (incoming_cl[207:192] <= predicate);
			bit_result[13] <= (incoming_cl[223:208] <= predicate);
			bit_result[14] <= (incoming_cl[239:224] <= predicate);
			bit_result[15] <= (incoming_cl[255:240] <= predicate);
			bit_result[16] <= (incoming_cl[271:256] <= predicate);
			bit_result[17] <= (incoming_cl[287:272] <= predicate);
			bit_result[18] <= (incoming_cl[303:288] <= predicate);
			bit_result[19] <= (incoming_cl[319:304] <= predicate);
			bit_result[20] <= (incoming_cl[335:320] <= predicate);
			bit_result[21] <= (incoming_cl[351:336] <= predicate);
			bit_result[22] <= (incoming_cl[367:352] <= predicate);
			bit_result[23] <= (incoming_cl[383:368] <= predicate);
			bit_result[24] <= (incoming_cl[399:384] <= predicate);
			bit_result[25] <= (incoming_cl[415:400] <= predicate);
			bit_result[26] <= (incoming_cl[431:416] <= predicate);
			bit_result[27] <= (incoming_cl[447:432] <= predicate);
			bit_result[28] <= (incoming_cl[463:448] <= predicate);
			bit_result[29] <= (incoming_cl[479:464] <= predicate);
			bit_result[30] <= (incoming_cl[495:480] <= predicate);
			bit_result[31] <= (incoming_cl[511:496] <= predicate);
		end	
	end				
endmodule