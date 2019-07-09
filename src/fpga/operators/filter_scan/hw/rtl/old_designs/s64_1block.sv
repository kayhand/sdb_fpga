module s64_1block
   (
    input  logic clk,
    
    input  logic reset,
    input  logic en,
    
    input  logic [511:0] incoming_cl,
    input  logic [7:0]  predicate,
        
    output logic [63:0] bit_result
    );

	always_ff @(posedge clk)		
	begin		
		if (reset)	
		begin	
			bit_result <= 64'b0;
		end	
		else if (en)	
		begin	
			bit_result[0] <= (incoming_cl[7:0] <= predicate);
			
			for(int i = 0; i < 64; i++)
			begin
				bit_result[i] <= (incoming_cl[i * 8 +: 7] <= predicate);
			end
		end	
	end		
	
endmodule