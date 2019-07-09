// 16-bits
// 32-way parallelism
module scan_join_agg
   (
    input  logic clk,    
    input  logic reset,
    
    input logic reading_bitmap,
    input logic bitmap_ready,
    
    input  logic [7:0] lo_quantity_pred,
    
    input  logic [3:0] lo_discount_lower_pred,
    input  logic [3:0] lo_discount_upper_pred,

    //input logic [511:0] lo_quantity_cl,  // 64 lo_quantity values (8-bit encoding)
    //input logic [511:0] lo_discount_cl,  // 128 lo_discount values (4-bit encoding)
    
    // cons: less data parallelism 
    // pros: no materilization
    
    input logic [255:0] lo_quantity_cl,  // 32 lo_quantity values (8-bit encoding)
    input logic [127:0] lo_discount_cl,  // 32 lo_discount values (4-bit encoding)
    
    input logic [511:0] fk_cl, // 32 lo_orderdate values (16-bit encoding)
    input logic [511:0] bitmap_cl,
    
    output int agg_result
    );
	
	typedef logic [2559:0] bit_map_unpacked;	
	bit_map_unpacked bit_map;

	/* Register BitMap */
	always_ff @(posedge clk)		
	begin	
		if(reading_bitmap)
		begin
			bit_map[cls_processed * 512 +: 512] <= bitmap_cl; 
		end
	end
		
	/* Process Scans and Join */
	logic bit_result[31:0];
	logic result_ready = 0;
	always_ff @(posedge clk)		
	begin		
		if(reset)
		begin
			bit_result <= 32'b0;
		end
		else if (bitmap_ready)
		begin						 	
			bit_result[0] <= (lo_quantity_cl[7:0] <= lo_quantity_pred)
							 	&& (lo_discount_cl[3:0] >= lo_discount_lower_pred && lo_discount_cl[3:0] <= lo_discount_higher_pred) 
							 		&& (bit_map[fk_cl[15:0]]);	
			
			/*** ... ***/
			
			bit_result[31] <= (lo_quantity_cl[255:248] <= lo_quantity_pred)
				&& (lo_discount_cl[127:124] >= lo_discount_lower_pred && lo_discount_cl[127:124] <= lo_discount_higher_pred) 
				&& (bit_map[fk_cl[511:496]]);
						
		end
	end
	
	/* Process Aggregation: 
	 * SUM(lo_discount) */
	always_ff @(posedge clk)		
	begin		
		if(reset)
		begin
			agg_result <= 0;
		end
		else
		begin
			foreach(bit_result[idx])
			begin
				agg_result += bit_result[idx] * 
					disc_dict[lo_discount_cl[idx * 4 +: 4]];
			end
		end
	end
	
	/* Test Join Result */
	/*
	always_ff @(posedge clk)
	begin
		if(reset)
		begin
			join_count <= 0;
		end
		else if(result_ready) 
		begin			
			//$display("++++ CL%0d ++++", cls_processed);
			foreach(bit_result[idx])
			begin
			//	$display("%0d, %0d) -- ", cls_processed * 32 + idx, bit_result[idx]);
				join_count += bit_result[idx];
			end
			$display("==> Join Count: %d", join_count);
			result_ready <= 1'b0;
		end
	end
	*/
		
	/* Test BitMap */
	/*
	int bitmap_count = 0; 
	always_ff @(posedge clk)
	begin
		if(bitmap_ready && bitmap_count == 0) 
		begin
			//foreach(bitmap[idx])
			//begin
			//	foreach(bitmap[idx][idy])
			//	begin
			//		res_count += bitmap[idx][idy];
			//	end
			//end
			foreach(bit_map[idx])
			begin
				bitmap_count += bit_map[idx];
				if(bit_map[idx] == 1'b1)
				begin
					//$write("%0d ", idx);
				end				
			end
			//$write("\n");
			//bit_map = bit_result_unpacked'(bitmap);
		end
	end
	*/
	
	/* Testing FK Input */
	/*
	always_ff @(posedge clk)
	begin
		if (bitmap_ready)
		begin	
			//$display("++++ CL%0d ++++", cls_processed);
			//$display("lo_id, lo_orderdate, join_res");
			//for(int lo_id = 0; lo_id < 32; lo_id++)
			//begin
			//	$display("<%0d, %0d, %0b>", cls_processed * 32 + lo_id, 
			//			incoming_cl[lo_id * 16 +: 16], 
			//			bit_map[incoming_cl[lo_id * 16 +: 16]]); 
			//end 
		end		
	end
	*/
	

endmodule