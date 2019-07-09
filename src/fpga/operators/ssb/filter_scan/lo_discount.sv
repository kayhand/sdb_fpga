// 4-bit encoding
// 128-way parallelism

module lo_discount
   (
    input  logic clk,
    
    input  logic reset,
    
    input  logic en,
    
    input  logic [3:0] lower_pred, 
    input  logic [3:0] higher_pred,
    
    input  logic [511:0] incoming_cl,
    
    input  int total_cls_processed,
           
    output logic [511:0] bit_result,
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
			bit_result[0] <= ((lower_pred <= incoming_cl[3:0]) && (incoming_cl[3:0] <= higher_pred));
			bit_result[1] <= ((lower_pred <= incoming_cl[7:4]) && (incoming_cl[7:4] <= higher_pred));
			bit_result[2] <= ((lower_pred <= incoming_cl[11:8]) && (incoming_cl[11:8] <= higher_pred));
			bit_result[3] <= ((lower_pred <= incoming_cl[15:12]) && (incoming_cl[15:12] <= higher_pred));
			bit_result[4] <= ((lower_pred <= incoming_cl[19:16]) && (incoming_cl[19:16] <= higher_pred));
			bit_result[5] <= ((lower_pred <= incoming_cl[23:20]) && (incoming_cl[23:20] <= higher_pred));
			bit_result[6] <= ((lower_pred <= incoming_cl[27:24]) && (incoming_cl[27:24] <= higher_pred));
			bit_result[7] <= ((lower_pred <= incoming_cl[31:28]) && (incoming_cl[31:28] <= higher_pred));
			bit_result[8] <= ((lower_pred <= incoming_cl[35:32]) && (incoming_cl[35:32] <= higher_pred));
			bit_result[9] <= ((lower_pred <= incoming_cl[39:36]) && (incoming_cl[39:36] <= higher_pred));
			bit_result[10] <= ((lower_pred <= incoming_cl[43:40]) && (incoming_cl[43:40] <= higher_pred));
			bit_result[11] <= ((lower_pred <= incoming_cl[47:44]) && (incoming_cl[47:44] <= higher_pred));
			bit_result[12] <= ((lower_pred <= incoming_cl[51:48]) && (incoming_cl[51:48] <= higher_pred));
			bit_result[13] <= ((lower_pred <= incoming_cl[55:52]) && (incoming_cl[55:52] <= higher_pred));
			bit_result[14] <= ((lower_pred <= incoming_cl[59:56]) && (incoming_cl[59:56] <= higher_pred));
			bit_result[15] <= ((lower_pred <= incoming_cl[63:60]) && (incoming_cl[63:60] <= higher_pred));
			bit_result[16] <= ((lower_pred <= incoming_cl[67:64]) && (incoming_cl[67:64] <= higher_pred));
			bit_result[17] <= ((lower_pred <= incoming_cl[71:68]) && (incoming_cl[71:68] <= higher_pred));
			bit_result[18] <= ((lower_pred <= incoming_cl[75:72]) && (incoming_cl[75:72] <= higher_pred));
			bit_result[19] <= ((lower_pred <= incoming_cl[79:76]) && (incoming_cl[79:76] <= higher_pred));
			bit_result[20] <= ((lower_pred <= incoming_cl[83:80]) && (incoming_cl[83:80] <= higher_pred));
			bit_result[21] <= ((lower_pred <= incoming_cl[87:84]) && (incoming_cl[87:84] <= higher_pred));
			bit_result[22] <= ((lower_pred <= incoming_cl[91:88]) && (incoming_cl[91:88] <= higher_pred));
			bit_result[23] <= ((lower_pred <= incoming_cl[95:92]) && (incoming_cl[95:92] <= higher_pred));
			bit_result[24] <= ((lower_pred <= incoming_cl[99:96]) && (incoming_cl[99:96] <= higher_pred));
			bit_result[25] <= ((lower_pred <= incoming_cl[103:100]) && (incoming_cl[103:100] <= higher_pred));
			bit_result[26] <= ((lower_pred <= incoming_cl[107:104]) && (incoming_cl[107:104] <= higher_pred));
			bit_result[27] <= ((lower_pred <= incoming_cl[111:108]) && (incoming_cl[111:108] <= higher_pred));
			bit_result[28] <= ((lower_pred <= incoming_cl[115:112]) && (incoming_cl[115:112] <= higher_pred));
			bit_result[29] <= ((lower_pred <= incoming_cl[119:116]) && (incoming_cl[119:116] <= higher_pred));
			bit_result[30] <= ((lower_pred <= incoming_cl[123:120]) && (incoming_cl[123:120] <= higher_pred));
			bit_result[31] <= ((lower_pred <= incoming_cl[127:124]) && (incoming_cl[127:124] <= higher_pred));
			bit_result[32] <= ((lower_pred <= incoming_cl[131:128]) && (incoming_cl[131:128] <= higher_pred));
			bit_result[33] <= ((lower_pred <= incoming_cl[135:132]) && (incoming_cl[135:132] <= higher_pred));
			bit_result[34] <= ((lower_pred <= incoming_cl[139:136]) && (incoming_cl[139:136] <= higher_pred));
			bit_result[35] <= ((lower_pred <= incoming_cl[143:140]) && (incoming_cl[143:140] <= higher_pred));
			bit_result[36] <= ((lower_pred <= incoming_cl[147:144]) && (incoming_cl[147:144] <= higher_pred));
			bit_result[37] <= ((lower_pred <= incoming_cl[151:148]) && (incoming_cl[151:148] <= higher_pred));
			bit_result[38] <= ((lower_pred <= incoming_cl[155:152]) && (incoming_cl[155:152] <= higher_pred));
			bit_result[39] <= ((lower_pred <= incoming_cl[159:156]) && (incoming_cl[159:156] <= higher_pred));
			bit_result[40] <= ((lower_pred <= incoming_cl[163:160]) && (incoming_cl[163:160] <= higher_pred));
			bit_result[41] <= ((lower_pred <= incoming_cl[167:164]) && (incoming_cl[167:164] <= higher_pred));
			bit_result[42] <= ((lower_pred <= incoming_cl[171:168]) && (incoming_cl[171:168] <= higher_pred));
			bit_result[43] <= ((lower_pred <= incoming_cl[175:172]) && (incoming_cl[175:172] <= higher_pred));
			bit_result[44] <= ((lower_pred <= incoming_cl[179:176]) && (incoming_cl[179:176] <= higher_pred));
			bit_result[45] <= ((lower_pred <= incoming_cl[183:180]) && (incoming_cl[183:180] <= higher_pred));
			bit_result[46] <= ((lower_pred <= incoming_cl[187:184]) && (incoming_cl[187:184] <= higher_pred));
			bit_result[47] <= ((lower_pred <= incoming_cl[191:188]) && (incoming_cl[191:188] <= higher_pred));
			bit_result[48] <= ((lower_pred <= incoming_cl[195:192]) && (incoming_cl[195:192] <= higher_pred));
			bit_result[49] <= ((lower_pred <= incoming_cl[199:196]) && (incoming_cl[199:196] <= higher_pred));
			bit_result[50] <= ((lower_pred <= incoming_cl[203:200]) && (incoming_cl[203:200] <= higher_pred));
			bit_result[51] <= ((lower_pred <= incoming_cl[207:204]) && (incoming_cl[207:204] <= higher_pred));
			bit_result[52] <= ((lower_pred <= incoming_cl[211:208]) && (incoming_cl[211:208] <= higher_pred));
			bit_result[53] <= ((lower_pred <= incoming_cl[215:212]) && (incoming_cl[215:212] <= higher_pred));
			bit_result[54] <= ((lower_pred <= incoming_cl[219:216]) && (incoming_cl[219:216] <= higher_pred));
			bit_result[55] <= ((lower_pred <= incoming_cl[223:220]) && (incoming_cl[223:220] <= higher_pred));
			bit_result[56] <= ((lower_pred <= incoming_cl[227:224]) && (incoming_cl[227:224] <= higher_pred));
			bit_result[57] <= ((lower_pred <= incoming_cl[231:228]) && (incoming_cl[231:228] <= higher_pred));
			bit_result[58] <= ((lower_pred <= incoming_cl[235:232]) && (incoming_cl[235:232] <= higher_pred));
			bit_result[59] <= ((lower_pred <= incoming_cl[239:236]) && (incoming_cl[239:236] <= higher_pred));
			bit_result[60] <= ((lower_pred <= incoming_cl[243:240]) && (incoming_cl[243:240] <= higher_pred));
			bit_result[61] <= ((lower_pred <= incoming_cl[247:244]) && (incoming_cl[247:244] <= higher_pred));
			bit_result[62] <= ((lower_pred <= incoming_cl[251:248]) && (incoming_cl[251:248] <= higher_pred));
			bit_result[63] <= ((lower_pred <= incoming_cl[255:252]) && (incoming_cl[255:252] <= higher_pred));
			bit_result[64] <= ((lower_pred <= incoming_cl[259:256]) && (incoming_cl[259:256] <= higher_pred));
			bit_result[65] <= ((lower_pred <= incoming_cl[263:260]) && (incoming_cl[263:260] <= higher_pred));
			bit_result[66] <= ((lower_pred <= incoming_cl[267:264]) && (incoming_cl[267:264] <= higher_pred));
			bit_result[67] <= ((lower_pred <= incoming_cl[271:268]) && (incoming_cl[271:268] <= higher_pred));
			bit_result[68] <= ((lower_pred <= incoming_cl[275:272]) && (incoming_cl[275:272] <= higher_pred));
			bit_result[69] <= ((lower_pred <= incoming_cl[279:276]) && (incoming_cl[279:276] <= higher_pred));
			bit_result[70] <= ((lower_pred <= incoming_cl[283:280]) && (incoming_cl[283:280] <= higher_pred));
			bit_result[71] <= ((lower_pred <= incoming_cl[287:284]) && (incoming_cl[287:284] <= higher_pred));
			bit_result[72] <= ((lower_pred <= incoming_cl[291:288]) && (incoming_cl[291:288] <= higher_pred));
			bit_result[73] <= ((lower_pred <= incoming_cl[295:292]) && (incoming_cl[295:292] <= higher_pred));
			bit_result[74] <= ((lower_pred <= incoming_cl[299:296]) && (incoming_cl[299:296] <= higher_pred));
			bit_result[75] <= ((lower_pred <= incoming_cl[303:300]) && (incoming_cl[303:300] <= higher_pred));
			bit_result[76] <= ((lower_pred <= incoming_cl[307:304]) && (incoming_cl[307:304] <= higher_pred));
			bit_result[77] <= ((lower_pred <= incoming_cl[311:308]) && (incoming_cl[311:308] <= higher_pred));
			bit_result[78] <= ((lower_pred <= incoming_cl[315:312]) && (incoming_cl[315:312] <= higher_pred));
			bit_result[79] <= ((lower_pred <= incoming_cl[319:316]) && (incoming_cl[319:316] <= higher_pred));
			bit_result[80] <= ((lower_pred <= incoming_cl[323:320]) && (incoming_cl[323:320] <= higher_pred));
			bit_result[81] <= ((lower_pred <= incoming_cl[327:324]) && (incoming_cl[327:324] <= higher_pred));
			bit_result[82] <= ((lower_pred <= incoming_cl[331:328]) && (incoming_cl[331:328] <= higher_pred));
			bit_result[83] <= ((lower_pred <= incoming_cl[335:332]) && (incoming_cl[335:332] <= higher_pred));
			bit_result[84] <= ((lower_pred <= incoming_cl[339:336]) && (incoming_cl[339:336] <= higher_pred));
			bit_result[85] <= ((lower_pred <= incoming_cl[343:340]) && (incoming_cl[343:340] <= higher_pred));
			bit_result[86] <= ((lower_pred <= incoming_cl[347:344]) && (incoming_cl[347:344] <= higher_pred));
			bit_result[87] <= ((lower_pred <= incoming_cl[351:348]) && (incoming_cl[351:348] <= higher_pred));
			bit_result[88] <= ((lower_pred <= incoming_cl[355:352]) && (incoming_cl[355:352] <= higher_pred));
			bit_result[89] <= ((lower_pred <= incoming_cl[359:356]) && (incoming_cl[359:356] <= higher_pred));
			bit_result[90] <= ((lower_pred <= incoming_cl[363:360]) && (incoming_cl[363:360] <= higher_pred));
			bit_result[91] <= ((lower_pred <= incoming_cl[367:364]) && (incoming_cl[367:364] <= higher_pred));
			bit_result[92] <= ((lower_pred <= incoming_cl[371:368]) && (incoming_cl[371:368] <= higher_pred));
			bit_result[93] <= ((lower_pred <= incoming_cl[375:372]) && (incoming_cl[375:372] <= higher_pred));
			bit_result[94] <= ((lower_pred <= incoming_cl[379:376]) && (incoming_cl[379:376] <= higher_pred));
			bit_result[95] <= ((lower_pred <= incoming_cl[383:380]) && (incoming_cl[383:380] <= higher_pred));
			bit_result[96] <= ((lower_pred <= incoming_cl[387:384]) && (incoming_cl[387:384] <= higher_pred));
			bit_result[97] <= ((lower_pred <= incoming_cl[391:388]) && (incoming_cl[391:388] <= higher_pred));
			bit_result[98] <= ((lower_pred <= incoming_cl[395:392]) && (incoming_cl[395:392] <= higher_pred));
			bit_result[99] <= ((lower_pred <= incoming_cl[399:396]) && (incoming_cl[399:396] <= higher_pred));
			bit_result[100] <= ((lower_pred <= incoming_cl[403:400]) && (incoming_cl[403:400] <= higher_pred));
			bit_result[101] <= ((lower_pred <= incoming_cl[407:404]) && (incoming_cl[407:404] <= higher_pred));
			bit_result[102] <= ((lower_pred <= incoming_cl[411:408]) && (incoming_cl[411:408] <= higher_pred));
			bit_result[103] <= ((lower_pred <= incoming_cl[415:412]) && (incoming_cl[415:412] <= higher_pred));
			bit_result[104] <= ((lower_pred <= incoming_cl[419:416]) && (incoming_cl[419:416] <= higher_pred));
			bit_result[105] <= ((lower_pred <= incoming_cl[423:420]) && (incoming_cl[423:420] <= higher_pred));
			bit_result[106] <= ((lower_pred <= incoming_cl[427:424]) && (incoming_cl[427:424] <= higher_pred));
			bit_result[107] <= ((lower_pred <= incoming_cl[431:428]) && (incoming_cl[431:428] <= higher_pred));
			bit_result[108] <= ((lower_pred <= incoming_cl[435:432]) && (incoming_cl[435:432] <= higher_pred));
			bit_result[109] <= ((lower_pred <= incoming_cl[439:436]) && (incoming_cl[439:436] <= higher_pred));
			bit_result[110] <= ((lower_pred <= incoming_cl[443:440]) && (incoming_cl[443:440] <= higher_pred));
			bit_result[111] <= ((lower_pred <= incoming_cl[447:444]) && (incoming_cl[447:444] <= higher_pred));
			bit_result[112] <= ((lower_pred <= incoming_cl[451:448]) && (incoming_cl[451:448] <= higher_pred));
			bit_result[113] <= ((lower_pred <= incoming_cl[455:452]) && (incoming_cl[455:452] <= higher_pred));
			bit_result[114] <= ((lower_pred <= incoming_cl[459:456]) && (incoming_cl[459:456] <= higher_pred));
			bit_result[115] <= ((lower_pred <= incoming_cl[463:460]) && (incoming_cl[463:460] <= higher_pred));
			bit_result[116] <= ((lower_pred <= incoming_cl[467:464]) && (incoming_cl[467:464] <= higher_pred));
			bit_result[117] <= ((lower_pred <= incoming_cl[471:468]) && (incoming_cl[471:468] <= higher_pred));
			bit_result[118] <= ((lower_pred <= incoming_cl[475:472]) && (incoming_cl[475:472] <= higher_pred));
			bit_result[119] <= ((lower_pred <= incoming_cl[479:476]) && (incoming_cl[479:476] <= higher_pred));
			bit_result[120] <= ((lower_pred <= incoming_cl[483:480]) && (incoming_cl[483:480] <= higher_pred));
			bit_result[121] <= ((lower_pred <= incoming_cl[487:484]) && (incoming_cl[487:484] <= higher_pred));
			bit_result[122] <= ((lower_pred <= incoming_cl[491:488]) && (incoming_cl[491:488] <= higher_pred));
			bit_result[123] <= ((lower_pred <= incoming_cl[495:492]) && (incoming_cl[495:492] <= higher_pred));
			bit_result[124] <= ((lower_pred <= incoming_cl[499:496]) && (incoming_cl[499:496] <= higher_pred));
			bit_result[125] <= ((lower_pred <= incoming_cl[503:500]) && (incoming_cl[503:500] <= higher_pred));
			bit_result[126] <= ((lower_pred <= incoming_cl[507:504]) && (incoming_cl[507:504] <= higher_pred));
			bit_result[127] <= ((lower_pred <= incoming_cl[511:508]) && (incoming_cl[511:508] <= higher_pred));
			
			processing_done <= 1'b1;
		end		
	end	
	
endmodule
