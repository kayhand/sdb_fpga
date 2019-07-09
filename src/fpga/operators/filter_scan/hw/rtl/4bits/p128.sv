// 4-bit encoding
module p128
	(
		input  logic clk,
    
		input  logic reset,
    
		input  logic en,
    
		input  logic [3:0] predicate,
		input  logic [511:0] incoming_cl,
           
		output logic [127:0] bit_result,
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
			bit_result[64] <= (incoming_cl[259:256] >= predicate);
			bit_result[65] <= (incoming_cl[263:260] >= predicate);
			bit_result[66] <= (incoming_cl[267:264] >= predicate);
			bit_result[67] <= (incoming_cl[271:268] >= predicate);
			bit_result[68] <= (incoming_cl[275:272] >= predicate);
			bit_result[69] <= (incoming_cl[279:276] >= predicate);
			bit_result[70] <= (incoming_cl[283:280] >= predicate);
			bit_result[71] <= (incoming_cl[287:284] >= predicate);
			bit_result[72] <= (incoming_cl[291:288] >= predicate);
			bit_result[73] <= (incoming_cl[295:292] >= predicate);
			bit_result[74] <= (incoming_cl[299:296] >= predicate);
			bit_result[75] <= (incoming_cl[303:300] >= predicate);
			bit_result[76] <= (incoming_cl[307:304] >= predicate);
			bit_result[77] <= (incoming_cl[311:308] >= predicate);
			bit_result[78] <= (incoming_cl[315:312] >= predicate);
			bit_result[79] <= (incoming_cl[319:316] >= predicate);
			bit_result[80] <= (incoming_cl[323:320] >= predicate);
			bit_result[81] <= (incoming_cl[327:324] >= predicate);
			bit_result[82] <= (incoming_cl[331:328] >= predicate);
			bit_result[83] <= (incoming_cl[335:332] >= predicate);
			bit_result[84] <= (incoming_cl[339:336] >= predicate);
			bit_result[85] <= (incoming_cl[343:340] >= predicate);
			bit_result[86] <= (incoming_cl[347:344] >= predicate);
			bit_result[87] <= (incoming_cl[351:348] >= predicate);
			bit_result[88] <= (incoming_cl[355:352] >= predicate);
			bit_result[89] <= (incoming_cl[359:356] >= predicate);
			bit_result[90] <= (incoming_cl[363:360] >= predicate);
			bit_result[91] <= (incoming_cl[367:364] >= predicate);
			bit_result[92] <= (incoming_cl[371:368] >= predicate);
			bit_result[93] <= (incoming_cl[375:372] >= predicate);
			bit_result[94] <= (incoming_cl[379:376] >= predicate);
			bit_result[95] <= (incoming_cl[383:380] >= predicate);
			bit_result[96] <= (incoming_cl[387:384] >= predicate);
			bit_result[97] <= (incoming_cl[391:388] >= predicate);
			bit_result[98] <= (incoming_cl[395:392] >= predicate);
			bit_result[99] <= (incoming_cl[399:396] >= predicate);
			bit_result[100] <= (incoming_cl[403:400] >= predicate);
			bit_result[101] <= (incoming_cl[407:404] >= predicate);
			bit_result[102] <= (incoming_cl[411:408] >= predicate);
			bit_result[103] <= (incoming_cl[415:412] >= predicate);
			bit_result[104] <= (incoming_cl[419:416] >= predicate);
			bit_result[105] <= (incoming_cl[423:420] >= predicate);
			bit_result[106] <= (incoming_cl[427:424] >= predicate);
			bit_result[107] <= (incoming_cl[431:428] >= predicate);
			bit_result[108] <= (incoming_cl[435:432] >= predicate);
			bit_result[109] <= (incoming_cl[439:436] >= predicate);
			bit_result[110] <= (incoming_cl[443:440] >= predicate);
			bit_result[111] <= (incoming_cl[447:444] >= predicate);
			bit_result[112] <= (incoming_cl[451:448] >= predicate);
			bit_result[113] <= (incoming_cl[455:452] >= predicate);
			bit_result[114] <= (incoming_cl[459:456] >= predicate);
			bit_result[115] <= (incoming_cl[463:460] >= predicate);
			bit_result[116] <= (incoming_cl[467:464] >= predicate);
			bit_result[117] <= (incoming_cl[471:468] >= predicate);
			bit_result[118] <= (incoming_cl[475:472] >= predicate);
			bit_result[119] <= (incoming_cl[479:476] >= predicate);
			bit_result[120] <= (incoming_cl[483:480] >= predicate);
			bit_result[121] <= (incoming_cl[487:484] >= predicate);
			bit_result[122] <= (incoming_cl[491:488] >= predicate);
			bit_result[123] <= (incoming_cl[495:492] >= predicate);
			bit_result[124] <= (incoming_cl[499:496] >= predicate);
			bit_result[125] <= (incoming_cl[503:500] >= predicate);
			bit_result[126] <= (incoming_cl[507:504] >= predicate);
			bit_result[127] <= (incoming_cl[511:508] >= predicate);
			
			processing_done <= 1'b1;
		end		
	end	
	
endmodule
