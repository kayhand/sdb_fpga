// 4-bit encoding
module p1
   (
    input  logic clk,
    
    input  logic reset,
    input  logic en,
    
    input  logic [3:0] incoming_cl,
    input  logic [3:0]  predicate,
        
    output logic bit_result    
    );
	
	always_ff @(posedge clk)		
	begin		
		if (reset)	
		begin	
			bit_result <= 1'b0;
		end	
		else if (en)	
		begin
			bit_result <= (incoming_cl[3:0] <= predicate);
		end	
	end				
endmodule
