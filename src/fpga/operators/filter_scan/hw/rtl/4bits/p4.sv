// 4-bit encoding
module p4
   (
    input  logic clk,
    
    input  logic reset,
    input  logic en,
        
    input  logic [15:0] incoming_cl,
    input  logic [3:0]  predicate,
        
    output logic [3:0] bit_result,
    output logic done
    );
	
	logic req_received;
	always_ff @(posedge clk)		
	begin		
		if (reset)	
		begin	
			bit_result <= 4'h0;
		end	
		else if (!en)
		begin
			done <= 1'b0;
			req_received <= 1'b0;
		end
		else if (en && !req_received)		
		begin
			req_received <= 1'b1;
			
			bit_result[0] <= (incoming_cl[3:0] >= predicate);
			bit_result[1] <= (incoming_cl[7:4] >= predicate);
			bit_result[2] <= (incoming_cl[11:8] >= predicate);
			bit_result[3] <= (incoming_cl[15:12] >= predicate);
			
			done <= 1'b1;
		end	
	end				
endmodule
