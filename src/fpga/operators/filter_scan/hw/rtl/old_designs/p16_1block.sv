// 32-bit encoding
module p16_1block 
   (
    input  logic clk,
    
    input  logic reset,
    input  logic en,
    
    input  logic [511:0] incoming_cl,
    input  logic [31:0]  predicate,
        
    output logic [15:0] bit_result    
    );
	
	always_ff @(posedge clk)		
	begin		
		if (reset)	
		begin	
			bit_result <= 16'b0;
		end	
		else if (en)	
		begin	
			bit_result[0] <= (incoming_cl[31:0] <= predicate);
			bit_result[1] <= (incoming_cl[63:32] <= predicate);
			bit_result[2] <= (incoming_cl[95:64] <= predicate);
			bit_result[3] <= (incoming_cl[127:96] <= predicate);
			bit_result[4] <= (incoming_cl[159:128] <= predicate);
			bit_result[5] <= (incoming_cl[191:160] <= predicate);
			bit_result[6] <= (incoming_cl[223:192] <= predicate);
			bit_result[7] <= (incoming_cl[255:224] <= predicate);
			bit_result[8] <= (incoming_cl[287:256] <= predicate);
			bit_result[9] <= (incoming_cl[319:288] <= predicate);
			bit_result[10] <= (incoming_cl[351:320] <= predicate);
			bit_result[11] <= (incoming_cl[383:352] <= predicate);
			bit_result[12] <= (incoming_cl[415:384] <= predicate);
			bit_result[13] <= (incoming_cl[447:416] <= predicate);
			bit_result[14] <= (incoming_cl[479:448] <= predicate);
			bit_result[15] <= (incoming_cl[511:480] <= predicate);
		end	
	end				
endmodule