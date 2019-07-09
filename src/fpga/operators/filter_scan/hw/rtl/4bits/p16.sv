// 4-bit encoding
module p16
   (
    input  logic clk,
    
    input  logic reset,
    input  logic en,
    
    input  logic [3:0]  predicate,
    input  logic [63:0] incoming_cl,
        
    output logic [15:0] bit_result,
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
			
			processing_done <= 1'b1;
		end
	end		
endmodule