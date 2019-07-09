// 16-bits
// 32-way parallelism
module lineorder_date
   (
    input  logic clk,    
    input  logic reset,
    
    input logic reading_bitmap,
    input logic bitmap_ready,
    
    input int cls_processed,
              
    input logic [511:0] incoming_cl, // either bitmap or FK partition
    
    output logic [511:0] bit_result
    );
	
	typedef logic [2559:0] bit_result_unpacked;	
	bit_result_unpacked bit_map;

	//int join_count;
	//logic [511:0] bitmap [5];
	
	/* Register BitMap */
	always_ff @(posedge clk)		
	begin	
		if(reading_bitmap)
		begin
			//$display("[SUBMODULE] [BM] (CL%0d)", cls_processed);
			
			//bitmap[cls_processed] <= incoming_cl;
			bit_map[cls_processed * 512 +: 512] <= incoming_cl; 
		end
	end
		
	/* Process Join */
	logic result_ready = 0;
	always_ff @(posedge clk)		
	begin		
		if(reset)
		begin
			bit_result <= 0;
		end
		else if (bitmap_ready)
		begin						 
			bit_result[0] <= (bit_map[incoming_cl[15:0]]);
			bit_result[1] <= (bit_map[incoming_cl[31:16]]);
			bit_result[2] <= (bit_map[incoming_cl[47:32]]);
			bit_result[3] <= (bit_map[incoming_cl[63:48]]);
			bit_result[4] <= (bit_map[incoming_cl[79:64]]);
			bit_result[5] <= (bit_map[incoming_cl[95:80]]);
			bit_result[6] <= (bit_map[incoming_cl[111:96]]);
			bit_result[7] <= (bit_map[incoming_cl[127:112]]);
			bit_result[8] <= (bit_map[incoming_cl[143:128]]);
			bit_result[9] <= (bit_map[incoming_cl[159:144]]);
			bit_result[10] <= (bit_map[incoming_cl[175:160]]);
			bit_result[11] <= (bit_map[incoming_cl[191:176]]);
			bit_result[12] <= (bit_map[incoming_cl[207:192]]);
			bit_result[13] <= (bit_map[incoming_cl[223:208]]);
			bit_result[14] <= (bit_map[incoming_cl[239:224]]);
			bit_result[15] <= (bit_map[incoming_cl[255:240]]);
			bit_result[16] <= (bit_map[incoming_cl[271:256]]);
			bit_result[17] <= (bit_map[incoming_cl[287:272]]);
			bit_result[18] <= (bit_map[incoming_cl[303:288]]);
			bit_result[19] <= (bit_map[incoming_cl[319:304]]);
			bit_result[20] <= (bit_map[incoming_cl[335:320]]);
			bit_result[21] <= (bit_map[incoming_cl[351:336]]);
			bit_result[22] <= (bit_map[incoming_cl[367:352]]);
			bit_result[23] <= (bit_map[incoming_cl[383:368]]);
			bit_result[24] <= (bit_map[incoming_cl[399:384]]);
			bit_result[25] <= (bit_map[incoming_cl[415:400]]);
			bit_result[26] <= (bit_map[incoming_cl[431:416]]);
			bit_result[27] <= (bit_map[incoming_cl[447:432]]);
			bit_result[28] <= (bit_map[incoming_cl[463:448]]);
			bit_result[29] <= (bit_map[incoming_cl[479:464]]);
			bit_result[30] <= (bit_map[incoming_cl[495:480]]);
			bit_result[31] <= (bit_map[incoming_cl[511:496]]);
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