// 4-bit encoding
module p8
   (
    input  logic clk,
    
    input  logic reset,
    input  logic en,
    
    input logic [3:0] unit_id,
    
    input  logic [31:0] incoming_cl,
    input  logic [3:0]  predicate,
        
    output logic [7:0] bit_result,
    output logic [1:0] done
    );
	
	logic req_received;
	always_ff @(posedge clk)		
	begin		
		if (reset)	
		begin	
			bit_result <= 8'h00;
		end	
		else if (!en)
		begin
			done <= 2'b00;
			req_received <= 1'b0;
		end
		else if (en && !req_received)
		begin
			req_received <= 1'b1;
		
			bit_result[0] <= (incoming_cl[3:0] >= predicate);
			bit_result[1] <= (incoming_cl[7:4] >= predicate);
			bit_result[2] <= (incoming_cl[11:8] >= predicate);
			bit_result[3] <= (incoming_cl[15:12] >= predicate);
			bit_result[4] <= (incoming_cl[19:16] >= predicate);
			bit_result[5] <= (incoming_cl[23:20] >= predicate);
			bit_result[6] <= (incoming_cl[27:24] >= predicate);
			bit_result[7] <= (incoming_cl[31:28] >= predicate);
			bit_result[8] <= (incoming_cl[35:32] >= predicate);
			
			done <= 2'b11;
		end	
	end				
endmodule
