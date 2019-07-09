// 4-bit encoding
module p2
   (
    input  logic clk,
    
    input  logic reset,
    input  logic en,
    
    input  logic [7:0] incoming_cl,
    input  logic [3:0]  predicate,
        
    output logic [1:0] bit_result    
    );
	
	always_ff @(posedge clk)		
	begin		
		if (reset)	
		begin	
			bit_result <= 2'b0;
		end	
		else if (en)	
		begin
			bit_result[0] <= (incoming_cl[3:0] <= predicate);
			bit_result[1] <= (incoming_cl[7:4] <= predicate);
		end	
	end				
endmodule
