module filter_scan
   (
    input  logic clk,
    
    input  logic reset,
    input  logic en,
    
    input  logic [511:0] data_block,
    input  logic [31:0]  predicate,
    
    // 0, 1, ... 7
    // 1st filter_block, 2nd filter block, ..., 8th filter block
    input  logic [5:0]  block_id,
    
    output logic [63:0] local_result,
    
    output logic [511:0] filter_result
    );
		
    always_ff @(posedge clk)
    begin
        if (reset)
        begin
            filter_result <= 512'b0;
        end
        else if (en)
        begin
        	logic [8:0] start_offset;
        	
        	logic [63:0] cur_word; // to process the cache-line in 64-bit blocks
        	logic [7:0]  cur_val;  // to keep 8-bit compressed column partition value
        	
        	logic [8:0]  word_offset; //0, 64, 128, ... ,  448
        	logic [5:0]  val_offset; //0, 8, 16, ... , 56
        	        	
        	//word_id -> use to get the proper range for each word [0-63], [64-127], ...
        	//j -> 8 words (64-bits) in every cache-line (512-bits)
        	//k -> 8 8-bit values in each 64-bit word
        	         	
        	start_offset = (block_id % 8) * 64;
        	for(int word_id = 0; word_id < 8; word_id++)
        	begin
        		word_offset = word_id * 64;        		
        		cur_word = data_block[word_offset +: 63]; //64-bits of data
        		val_offset = word_id * 8; //8 values in each word 
        		for(int k = 7; k >= 0; k--)
        		begin
        			cur_val = cur_word[k * 8 +: 7];
        			filter_result[start_offset + val_offset] = (cur_val == predicate);
        			//$write("%0d ", cur_val);
        			val_offset++;
        		end
        	end
        	
        	$display("\n == CL#%d processed (offset: %d) == \n", block_id, start_offset);
        	//$display("%0b", filter_result);
        end
    end

endmodule