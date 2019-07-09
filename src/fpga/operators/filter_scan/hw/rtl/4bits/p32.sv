// 4-bit encoding
module p32
   (
    input  logic clk,
    
    input  logic reset,
    input  logic en,
        
    input  logic [3:0]  predicate,    
    input  logic [127:0] incoming_cl,
        
    output logic [31:0] bit_result,    
    output logic processing_done
    );
	
	logic req_received;	
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
						
			processing_done <= 1'b1;
		end	
	end				
endmodule
