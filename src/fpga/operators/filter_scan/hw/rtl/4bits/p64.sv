// 4-bit encoding
module p64
   (
    input  logic clk,
    
    input  logic reset,
    input  logic en,
    
    input  logic [3:0]  predicate,    
    input  logic [255:0] incoming_cl,
        
    output logic [63:0] bit_result,    
    output logic processing_done
    );

	always_ff @(posedge clk)		
	begin
		if (reset)	
		begin				
			bit_result <= 0;
			processing_done <= 1'b0;
		end
		else if (en)
		begin
			bit_result[0] <= (incoming_cl[3:0] >= predicate);
			bit_result[1] <= (incoming_cl[7:4] >= predicate);
			bit_result[2] <= (incoming_cl[11:8] >= predicate);
			bit_result[3] <= (incoming_cl[15:12] >= predicate);
			bit_result[4] <= (incoming_cl[19:16] >= predicate);
			bit_result[5] <= (incoming_cl[23:20] >= predicate);
			bit_result[6] <= (incoming_cl[27:24] >= predicate);
			bit_result[7] <= (incoming_cl[31:28] >= predicate);
			bit_result[8] <= (incoming_cl[35:32] >= predicate);
			bit_result[9] <= (incoming_cl[39:36] >= predicate);
			bit_result[10] <= (incoming_cl[43:40] >= predicate);
			bit_result[11] <= (incoming_cl[47:44] >= predicate);
			bit_result[12] <= (incoming_cl[51:48] >= predicate);
			bit_result[13] <= (incoming_cl[55:52] >= predicate);
			bit_result[14] <= (incoming_cl[59:56] >= predicate);
			bit_result[15] <= (incoming_cl[63:60] >= predicate);
			bit_result[16] <= (incoming_cl[67:64] >= predicate);
			bit_result[17] <= (incoming_cl[71:68] >= predicate);
			bit_result[18] <= (incoming_cl[75:72] >= predicate);
			bit_result[19] <= (incoming_cl[79:76] >= predicate);
			bit_result[20] <= (incoming_cl[83:80] >= predicate);
			bit_result[21] <= (incoming_cl[87:84] >= predicate);
			bit_result[22] <= (incoming_cl[91:88] >= predicate);
			bit_result[23] <= (incoming_cl[95:92] >= predicate);
			bit_result[24] <= (incoming_cl[99:96] >= predicate);
			bit_result[25] <= (incoming_cl[103:100] >= predicate);
			bit_result[26] <= (incoming_cl[107:104] >= predicate);
			bit_result[27] <= (incoming_cl[111:108] >= predicate);
			bit_result[28] <= (incoming_cl[115:112] >= predicate);
			bit_result[29] <= (incoming_cl[119:116] >= predicate);
			bit_result[30] <= (incoming_cl[123:120] >= predicate);
			bit_result[31] <= (incoming_cl[127:124] >= predicate);
			bit_result[32] <= (incoming_cl[131:128] >= predicate);
			bit_result[33] <= (incoming_cl[135:132] >= predicate);
			bit_result[34] <= (incoming_cl[139:136] >= predicate);
			bit_result[35] <= (incoming_cl[143:140] >= predicate);
			bit_result[36] <= (incoming_cl[147:144] >= predicate);
			bit_result[37] <= (incoming_cl[151:148] >= predicate);
			bit_result[38] <= (incoming_cl[155:152] >= predicate);
			bit_result[39] <= (incoming_cl[159:156] >= predicate);
			bit_result[40] <= (incoming_cl[163:160] >= predicate);
			bit_result[41] <= (incoming_cl[167:164] >= predicate);
			bit_result[42] <= (incoming_cl[171:168] >= predicate);
			bit_result[43] <= (incoming_cl[175:172] >= predicate);
			bit_result[44] <= (incoming_cl[179:176] >= predicate);
			bit_result[45] <= (incoming_cl[183:180] >= predicate);
			bit_result[46] <= (incoming_cl[187:184] >= predicate);
			bit_result[47] <= (incoming_cl[191:188] >= predicate);
			bit_result[48] <= (incoming_cl[195:192] >= predicate);
			bit_result[49] <= (incoming_cl[199:196] >= predicate);
			bit_result[50] <= (incoming_cl[203:200] >= predicate);
			bit_result[51] <= (incoming_cl[207:204] >= predicate);
			bit_result[52] <= (incoming_cl[211:208] >= predicate);
			bit_result[53] <= (incoming_cl[215:212] >= predicate);
			bit_result[54] <= (incoming_cl[219:216] >= predicate);
			bit_result[55] <= (incoming_cl[223:220] >= predicate);
			bit_result[56] <= (incoming_cl[227:224] >= predicate);
			bit_result[57] <= (incoming_cl[231:228] >= predicate);
			bit_result[58] <= (incoming_cl[235:232] >= predicate);
			bit_result[59] <= (incoming_cl[239:236] >= predicate);
			bit_result[60] <= (incoming_cl[243:240] >= predicate);
			bit_result[61] <= (incoming_cl[247:244] >= predicate);
			bit_result[62] <= (incoming_cl[251:248] >= predicate);
			bit_result[63] <= (incoming_cl[255:252] >= predicate);
					
			processing_done <= 1'b1;
		end		
	end	

endmodule