// 4-bit encoding for each lo_discount value
// 128-way parallelism

module discount_sum
   (
    input  logic clk,
    
    input  logic reset,
    input  logic en,
              
    input  logic [127:0] discount_cl [3:0], // lo_discount block    
    input  logic [127:0] bit_map, // d_year scan result
        
    output logic [127:0] agg_result [3:0], // pre-reduce
    output logic processing_done
    );
		
	always_ff @(posedge clk)
	begin		
		if (reset)	
		begin				
			processing_done <= 1'b0;		
		end
		else if (en)
		begin
			agg_result[0] <= discount_cl[0] * bit_map[0];
			agg_result[1] <= discount_cl[1] * bit_map[1];
			agg_result[2] <= discount_cl[2] * bit_map[2];
			agg_result[3] <= discount_cl[3] * bit_map[3];
			agg_result[4] <= discount_cl[4] * bit_map[4];
			agg_result[5] <= discount_cl[5] * bit_map[5];
			agg_result[6] <= discount_cl[6] * bit_map[6];
			agg_result[7] <= discount_cl[7] * bit_map[7];
			agg_result[8] <= discount_cl[8] * bit_map[8];
			agg_result[9] <= discount_cl[9] * bit_map[9];
			agg_result[10] <= discount_cl[10] * bit_map[10];
			agg_result[11] <= discount_cl[11] * bit_map[11];
			agg_result[12] <= discount_cl[12] * bit_map[12];
			agg_result[13] <= discount_cl[13] * bit_map[13];
			agg_result[14] <= discount_cl[14] * bit_map[14];
			agg_result[15] <= discount_cl[15] * bit_map[15];
			agg_result[16] <= discount_cl[16] * bit_map[16];
			agg_result[17] <= discount_cl[17] * bit_map[17];
			agg_result[18] <= discount_cl[18] * bit_map[18];
			agg_result[19] <= discount_cl[19] * bit_map[19];
			agg_result[20] <= discount_cl[20] * bit_map[20];
			agg_result[21] <= discount_cl[21] * bit_map[21];
			agg_result[22] <= discount_cl[22] * bit_map[22];
			agg_result[23] <= discount_cl[23] * bit_map[23];
			agg_result[24] <= discount_cl[24] * bit_map[24];
			agg_result[25] <= discount_cl[25] * bit_map[25];
			agg_result[26] <= discount_cl[26] * bit_map[26];
			agg_result[27] <= discount_cl[27] * bit_map[27];
			agg_result[28] <= discount_cl[28] * bit_map[28];
			agg_result[29] <= discount_cl[29] * bit_map[29];
			agg_result[30] <= discount_cl[30] * bit_map[30];
			agg_result[31] <= discount_cl[31] * bit_map[31];
			agg_result[32] <= discount_cl[32] * bit_map[32];
			agg_result[33] <= discount_cl[33] * bit_map[33];
			agg_result[34] <= discount_cl[34] * bit_map[34];
			agg_result[35] <= discount_cl[35] * bit_map[35];
			agg_result[36] <= discount_cl[36] * bit_map[36];
			agg_result[37] <= discount_cl[37] * bit_map[37];
			agg_result[38] <= discount_cl[38] * bit_map[38];
			agg_result[39] <= discount_cl[39] * bit_map[39];
			agg_result[40] <= discount_cl[40] * bit_map[40];
			agg_result[41] <= discount_cl[41] * bit_map[41];
			agg_result[42] <= discount_cl[42] * bit_map[42];
			agg_result[43] <= discount_cl[43] * bit_map[43];
			agg_result[44] <= discount_cl[44] * bit_map[44];
			agg_result[45] <= discount_cl[45] * bit_map[45];
			agg_result[46] <= discount_cl[46] * bit_map[46];
			agg_result[47] <= discount_cl[47] * bit_map[47];
			agg_result[48] <= discount_cl[48] * bit_map[48];
			agg_result[49] <= discount_cl[49] * bit_map[49];
			agg_result[50] <= discount_cl[50] * bit_map[50];
			agg_result[51] <= discount_cl[51] * bit_map[51];
			agg_result[52] <= discount_cl[52] * bit_map[52];
			agg_result[53] <= discount_cl[53] * bit_map[53];
			agg_result[54] <= discount_cl[54] * bit_map[54];
			agg_result[55] <= discount_cl[55] * bit_map[55];
			agg_result[56] <= discount_cl[56] * bit_map[56];
			agg_result[57] <= discount_cl[57] * bit_map[57];
			agg_result[58] <= discount_cl[58] * bit_map[58];
			agg_result[59] <= discount_cl[59] * bit_map[59];
			agg_result[60] <= discount_cl[60] * bit_map[60];
			agg_result[61] <= discount_cl[61] * bit_map[61];
			agg_result[62] <= discount_cl[62] * bit_map[62];
			agg_result[63] <= discount_cl[63] * bit_map[63];
			agg_result[64] <= discount_cl[64] * bit_map[64];
			agg_result[65] <= discount_cl[65] * bit_map[65];
			agg_result[66] <= discount_cl[66] * bit_map[66];
			agg_result[67] <= discount_cl[67] * bit_map[67];
			agg_result[68] <= discount_cl[68] * bit_map[68];
			agg_result[69] <= discount_cl[69] * bit_map[69];
			agg_result[70] <= discount_cl[70] * bit_map[70];
			agg_result[71] <= discount_cl[71] * bit_map[71];
			agg_result[72] <= discount_cl[72] * bit_map[72];
			agg_result[73] <= discount_cl[73] * bit_map[73];
			agg_result[74] <= discount_cl[74] * bit_map[74];
			agg_result[75] <= discount_cl[75] * bit_map[75];
			agg_result[76] <= discount_cl[76] * bit_map[76];
			agg_result[77] <= discount_cl[77] * bit_map[77];
			agg_result[78] <= discount_cl[78] * bit_map[78];
			agg_result[79] <= discount_cl[79] * bit_map[79];
			agg_result[80] <= discount_cl[80] * bit_map[80];
			agg_result[81] <= discount_cl[81] * bit_map[81];
			agg_result[82] <= discount_cl[82] * bit_map[82];
			agg_result[83] <= discount_cl[83] * bit_map[83];
			agg_result[84] <= discount_cl[84] * bit_map[84];
			agg_result[85] <= discount_cl[85] * bit_map[85];
			agg_result[86] <= discount_cl[86] * bit_map[86];
			agg_result[87] <= discount_cl[87] * bit_map[87];
			agg_result[88] <= discount_cl[88] * bit_map[88];
			agg_result[89] <= discount_cl[89] * bit_map[89];
			agg_result[90] <= discount_cl[90] * bit_map[90];
			agg_result[91] <= discount_cl[91] * bit_map[91];
			agg_result[92] <= discount_cl[92] * bit_map[92];
			agg_result[93] <= discount_cl[93] * bit_map[93];
			agg_result[94] <= discount_cl[94] * bit_map[94];
			agg_result[95] <= discount_cl[95] * bit_map[95];
			agg_result[96] <= discount_cl[96] * bit_map[96];
			agg_result[97] <= discount_cl[97] * bit_map[97];
			agg_result[98] <= discount_cl[98] * bit_map[98];
			agg_result[99] <= discount_cl[99] * bit_map[99];
			agg_result[100] <= discount_cl[100] * bit_map[100];
			agg_result[101] <= discount_cl[101] * bit_map[101];
			agg_result[102] <= discount_cl[102] * bit_map[102];
			agg_result[103] <= discount_cl[103] * bit_map[103];
			agg_result[104] <= discount_cl[104] * bit_map[104];
			agg_result[105] <= discount_cl[105] * bit_map[105];
			agg_result[106] <= discount_cl[106] * bit_map[106];
			agg_result[107] <= discount_cl[107] * bit_map[107];
			agg_result[108] <= discount_cl[108] * bit_map[108];
			agg_result[109] <= discount_cl[109] * bit_map[109];
			agg_result[110] <= discount_cl[110] * bit_map[110];
			agg_result[111] <= discount_cl[111] * bit_map[111];
			agg_result[112] <= discount_cl[112] * bit_map[112];
			agg_result[113] <= discount_cl[113] * bit_map[113];
			agg_result[114] <= discount_cl[114] * bit_map[114];
			agg_result[115] <= discount_cl[115] * bit_map[115];
			agg_result[116] <= discount_cl[116] * bit_map[116];
			agg_result[117] <= discount_cl[117] * bit_map[117];
			agg_result[118] <= discount_cl[118] * bit_map[118];
			agg_result[119] <= discount_cl[119] * bit_map[119];
			agg_result[120] <= discount_cl[120] * bit_map[120];
			agg_result[121] <= discount_cl[121] * bit_map[121];
			agg_result[122] <= discount_cl[122] * bit_map[122];
			agg_result[123] <= discount_cl[123] * bit_map[123];
			agg_result[124] <= discount_cl[124] * bit_map[124];
			agg_result[125] <= discount_cl[125] * bit_map[125];
			agg_result[126] <= discount_cl[126] * bit_map[126];
			agg_result[127] <= discount_cl[127] * bit_map[127];
									
			processing_done <= 1'b1;
		end	
	end				
endmodule
