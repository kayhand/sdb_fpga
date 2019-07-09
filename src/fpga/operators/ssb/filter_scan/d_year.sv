// 4-bit encoding
// 128-way parallelism
module d_year
   (
    input  logic clk,
    
    input  logic reset,
    
    input  logic en,
    
    input  logic [3:0] predicate,
    input  logic [511:0] d_year_cl, 
    
    input   int  total_cls_processed,
           
    output logic [511:0] bit_result,
    output logic processing_done
    );
	
	/* Testing input */
	always_ff @(posedge clk)
	begin
		if (en)
		begin
			/*
			$display("++++ CL%0d ++++", total_cls_processed);
			$display("date_id, d_year");
			for(int d_id = 0; d_id < 128; d_id++)
			begin
				$write("%0d, %0d) -- ", total_cls_processed * 128 + d_id, d_year_cl[d_id * 4 +: 4]); 
			end
			$display("\n");
			 */	 
		end			
	end
		
	always_ff @(posedge clk)		
	begin
		if (reset)	
		begin				
			bit_result <= 0;
			processing_done <= 1'b0;
		end
		else if (en)
		begin
			bit_result[0] <= (d_year_cl[3:0] == predicate);
			bit_result[1] <= (d_year_cl[7:4] == predicate);
			bit_result[2] <= (d_year_cl[11:8] == predicate);
			bit_result[3] <= (d_year_cl[15:12] == predicate);
			bit_result[4] <= (d_year_cl[19:16] == predicate);
			bit_result[5] <= (d_year_cl[23:20] == predicate);
			bit_result[6] <= (d_year_cl[27:24] == predicate);
			bit_result[7] <= (d_year_cl[31:28] == predicate);
			bit_result[8] <= (d_year_cl[35:32] == predicate);
			bit_result[9] <= (d_year_cl[39:36] == predicate);
			bit_result[10] <= (d_year_cl[43:40] == predicate);
			bit_result[11] <= (d_year_cl[47:44] == predicate);
			bit_result[12] <= (d_year_cl[51:48] == predicate);
			bit_result[13] <= (d_year_cl[55:52] == predicate);
			bit_result[14] <= (d_year_cl[59:56] == predicate);
			bit_result[15] <= (d_year_cl[63:60] == predicate);
			bit_result[16] <= (d_year_cl[67:64] == predicate);
			bit_result[17] <= (d_year_cl[71:68] == predicate);
			bit_result[18] <= (d_year_cl[75:72] == predicate);
			bit_result[19] <= (d_year_cl[79:76] == predicate);
			bit_result[20] <= (d_year_cl[83:80] == predicate);
			bit_result[21] <= (d_year_cl[87:84] == predicate);
			bit_result[22] <= (d_year_cl[91:88] == predicate);
			bit_result[23] <= (d_year_cl[95:92] == predicate);
			bit_result[24] <= (d_year_cl[99:96] == predicate);
			bit_result[25] <= (d_year_cl[103:100] == predicate);
			bit_result[26] <= (d_year_cl[107:104] == predicate);
			bit_result[27] <= (d_year_cl[111:108] == predicate);
			bit_result[28] <= (d_year_cl[115:112] == predicate);
			bit_result[29] <= (d_year_cl[119:116] == predicate);
			bit_result[30] <= (d_year_cl[123:120] == predicate);
			bit_result[31] <= (d_year_cl[127:124] == predicate);
			bit_result[32] <= (d_year_cl[131:128] == predicate);
			bit_result[33] <= (d_year_cl[135:132] == predicate);
			bit_result[34] <= (d_year_cl[139:136] == predicate);
			bit_result[35] <= (d_year_cl[143:140] == predicate);
			bit_result[36] <= (d_year_cl[147:144] == predicate);
			bit_result[37] <= (d_year_cl[151:148] == predicate);
			bit_result[38] <= (d_year_cl[155:152] == predicate);
			bit_result[39] <= (d_year_cl[159:156] == predicate);
			bit_result[40] <= (d_year_cl[163:160] == predicate);
			bit_result[41] <= (d_year_cl[167:164] == predicate);
			bit_result[42] <= (d_year_cl[171:168] == predicate);
			bit_result[43] <= (d_year_cl[175:172] == predicate);
			bit_result[44] <= (d_year_cl[179:176] == predicate);
			bit_result[45] <= (d_year_cl[183:180] == predicate);
			bit_result[46] <= (d_year_cl[187:184] == predicate);
			bit_result[47] <= (d_year_cl[191:188] == predicate);
			bit_result[48] <= (d_year_cl[195:192] == predicate);
			bit_result[49] <= (d_year_cl[199:196] == predicate);
			bit_result[50] <= (d_year_cl[203:200] == predicate);
			bit_result[51] <= (d_year_cl[207:204] == predicate);
			bit_result[52] <= (d_year_cl[211:208] == predicate);
			bit_result[53] <= (d_year_cl[215:212] == predicate);
			bit_result[54] <= (d_year_cl[219:216] == predicate);
			bit_result[55] <= (d_year_cl[223:220] == predicate);
			bit_result[56] <= (d_year_cl[227:224] == predicate);
			bit_result[57] <= (d_year_cl[231:228] == predicate);
			bit_result[58] <= (d_year_cl[235:232] == predicate);
			bit_result[59] <= (d_year_cl[239:236] == predicate);
			bit_result[60] <= (d_year_cl[243:240] == predicate);
			bit_result[61] <= (d_year_cl[247:244] == predicate);
			bit_result[62] <= (d_year_cl[251:248] == predicate);
			bit_result[63] <= (d_year_cl[255:252] == predicate);
			bit_result[64] <= (d_year_cl[259:256] == predicate);
			bit_result[65] <= (d_year_cl[263:260] == predicate);
			bit_result[66] <= (d_year_cl[267:264] == predicate);
			bit_result[67] <= (d_year_cl[271:268] == predicate);
			bit_result[68] <= (d_year_cl[275:272] == predicate);
			bit_result[69] <= (d_year_cl[279:276] == predicate);
			bit_result[70] <= (d_year_cl[283:280] == predicate);
			bit_result[71] <= (d_year_cl[287:284] == predicate);
			bit_result[72] <= (d_year_cl[291:288] == predicate);
			bit_result[73] <= (d_year_cl[295:292] == predicate);
			bit_result[74] <= (d_year_cl[299:296] == predicate);
			bit_result[75] <= (d_year_cl[303:300] == predicate);
			bit_result[76] <= (d_year_cl[307:304] == predicate);
			bit_result[77] <= (d_year_cl[311:308] == predicate);
			bit_result[78] <= (d_year_cl[315:312] == predicate);
			bit_result[79] <= (d_year_cl[319:316] == predicate);
			bit_result[80] <= (d_year_cl[323:320] == predicate);
			bit_result[81] <= (d_year_cl[327:324] == predicate);
			bit_result[82] <= (d_year_cl[331:328] == predicate);
			bit_result[83] <= (d_year_cl[335:332] == predicate);
			bit_result[84] <= (d_year_cl[339:336] == predicate);
			bit_result[85] <= (d_year_cl[343:340] == predicate);
			bit_result[86] <= (d_year_cl[347:344] == predicate);
			bit_result[87] <= (d_year_cl[351:348] == predicate);
			bit_result[88] <= (d_year_cl[355:352] == predicate);
			bit_result[89] <= (d_year_cl[359:356] == predicate);
			bit_result[90] <= (d_year_cl[363:360] == predicate);
			bit_result[91] <= (d_year_cl[367:364] == predicate);
			bit_result[92] <= (d_year_cl[371:368] == predicate);
			bit_result[93] <= (d_year_cl[375:372] == predicate);
			bit_result[94] <= (d_year_cl[379:376] == predicate);
			bit_result[95] <= (d_year_cl[383:380] == predicate);
			bit_result[96] <= (d_year_cl[387:384] == predicate);
			bit_result[97] <= (d_year_cl[391:388] == predicate);
			bit_result[98] <= (d_year_cl[395:392] == predicate);
			bit_result[99] <= (d_year_cl[399:396] == predicate);
			bit_result[100] <= (d_year_cl[403:400] == predicate);
			bit_result[101] <= (d_year_cl[407:404] == predicate);
			bit_result[102] <= (d_year_cl[411:408] == predicate);
			bit_result[103] <= (d_year_cl[415:412] == predicate);
			bit_result[104] <= (d_year_cl[419:416] == predicate);
			bit_result[105] <= (d_year_cl[423:420] == predicate);
			bit_result[106] <= (d_year_cl[427:424] == predicate);
			bit_result[107] <= (d_year_cl[431:428] == predicate);
			bit_result[108] <= (d_year_cl[435:432] == predicate);
			bit_result[109] <= (d_year_cl[439:436] == predicate);
			bit_result[110] <= (d_year_cl[443:440] == predicate);
			bit_result[111] <= (d_year_cl[447:444] == predicate);
			bit_result[112] <= (d_year_cl[451:448] == predicate);
			bit_result[113] <= (d_year_cl[455:452] == predicate);
			bit_result[114] <= (d_year_cl[459:456] == predicate);
			bit_result[115] <= (d_year_cl[463:460] == predicate);
			bit_result[116] <= (d_year_cl[467:464] == predicate);
			bit_result[117] <= (d_year_cl[471:468] == predicate);
			bit_result[118] <= (d_year_cl[475:472] == predicate);
			bit_result[119] <= (d_year_cl[479:476] == predicate);
			bit_result[120] <= (d_year_cl[483:480] == predicate);
			bit_result[121] <= (d_year_cl[487:484] == predicate);
			bit_result[122] <= (d_year_cl[491:488] == predicate);
			bit_result[123] <= (d_year_cl[495:492] == predicate);
			bit_result[124] <= (d_year_cl[499:496] == predicate);
			bit_result[125] <= (d_year_cl[503:500] == predicate);
			bit_result[126] <= (d_year_cl[507:504] == predicate);
			bit_result[127] <= (d_year_cl[511:508] == predicate);
			
			processing_done <= 1'b1;
		end		
	end	
	
endmodule
