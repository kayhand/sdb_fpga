module filter_scan_p16_s4
   (
    input  logic clk,
    
    input  logic reset,
    input  logic en,
    
    input  logic [511:0] incoming_cl,
    input  logic [7:0]  predicate,
        
    output logic [63:0] bit_result
    );
	
	//1st partition
	always_ff @(posedge clk)
	begin
		logic [31:0] cl_part;
		if (reset)
		begin
			cl_part <= 32'b0;
		end
		else if (en)
		begin	
			cl_part = incoming_cl[31:0];
			
			bit_result[0] <= (cl_part[7:0] == predicate);
			bit_result[1] <= (cl_part[15:8] == predicate);
			bit_result[2] <= (cl_part[23:16] == predicate);
			bit_result[3] <= (cl_part[31:24] == predicate);
			//$display("1st part: %0d - %0d - %0d - %0d", cl_part[7:0], cl_part[15:8], cl_part[23:16], cl_part[31:24]);
		end
	end

	//2nd partition
	always_ff @(posedge clk)
	begin
		logic [31:0] cl_part;		
		if (reset)
		begin
			cl_part <= 32'b0;
		end		
		else if (en)
		begin
			cl_part = incoming_cl[63:32];
				
			bit_result[4] <= (cl_part[7:0] == predicate);
			bit_result[5] <= (cl_part[15:8] == predicate);
			bit_result[6] <= (cl_part[23:16] == predicate);
			bit_result[7] <= (cl_part[31:24] == predicate);
		
			//$display("2nd part: %0d - %0d - %0d - %0d", cl_part[7:0], cl_part[15:8], cl_part[23:16], cl_part[31:24]);
		end
	end

	//3rd partition
	always_ff @(posedge clk)
	begin			
		logic [31:0] cl_part;
		if (reset)
		begin
			cl_part <= 32'b0;
		end
		else if (en)
		begin
			cl_part = incoming_cl[95:64];			
			
			bit_result[8] <= (cl_part[7:0] == predicate);
			bit_result[9] <= (cl_part[15:8] == predicate);
			bit_result[10] <= (cl_part[23:16] == predicate);
			bit_result[11] <= (cl_part[31:24] == predicate);	
			
			//$display("3rd part: %0d - %0d - %0d - %0d", cl_part[7:0], cl_part[15:8], cl_part[23:16], cl_part[31:24]);
		end
	end

	//4th partition
	always_ff @(posedge clk)
	begin			
		logic [31:0] cl_part;
		if (reset)
		begin
			cl_part <= 32'b0;
		end
		else if (en)
		begin
			cl_part = incoming_cl[127:96];	
			
			bit_result[12] <= (cl_part[7:0] == predicate);
			bit_result[13] <= (cl_part[15:8] == predicate);
			bit_result[14] <= (cl_part[23:16] == predicate);
			bit_result[15] <= (cl_part[31:24] == predicate);		

			//$display("4th part: %0d - %0d - %0d - %0d", cl_part[7:0], cl_part[15:8], cl_part[23:16], cl_part[31:24]);
		end
	end
	
	//5th partition
	always_ff @(posedge clk)
	begin			
		logic [31:0] cl_part;
		if (reset)
		begin
			cl_part <= 32'b0;
		end
		else if (en)
		begin
			cl_part = incoming_cl[159:128];			
			
			bit_result[16] <= (cl_part[7:0] == predicate);
			bit_result[17] <= (cl_part[15:8] == predicate);
			bit_result[18] <= (cl_part[23:16] == predicate);
			bit_result[19] <= (cl_part[31:24] == predicate);	

			//$display("5th part: %0d - %0d - %0d - %0d", cl_part[7:0], cl_part[15:8], cl_part[23:16], cl_part[31:24]);
		end
	end
	
	//6th partition
	always_ff @(posedge clk)
	begin			
		logic [31:0] cl_part;
		if (reset)
		begin
			cl_part <= 32'b0;
		end
		else if (en)
		begin			
			cl_part = incoming_cl[191:160];	
			
			bit_result[20] <= (cl_part[7:0] == predicate);
			bit_result[21] <= (cl_part[15:8] == predicate);
			bit_result[22] <= (cl_part[23:16] == predicate);
			bit_result[23] <= (cl_part[31:24] == predicate);		

			//$display("6th part: %0d - %0d - %0d - %0d", cl_part[7:0], cl_part[15:8], cl_part[23:16], cl_part[31:24]);
		end
	end
	
	//7th partition
	always_ff @(posedge clk)
	begin			
		logic [31:0] cl_part;
		if (reset)
		begin
			cl_part <= 32'b0;
		end
		else if (en)
		begin
			cl_part = incoming_cl[223:192];
			
			bit_result[24] <= (cl_part[7:0] == predicate);
			bit_result[25] <= (cl_part[15:8] == predicate);
			bit_result[26] <= (cl_part[23:16] == predicate);
			bit_result[27] <= (cl_part[31:24] == predicate);			

			//$display("7th part: %0d - %0d - %0d - %0d", cl_part[7:0], cl_part[15:8], cl_part[23:16], cl_part[31:24]);
		end
	end
	
	//8th partition
	always_ff @(posedge clk)
	begin			
		logic [31:0] cl_part;
		if (reset)
		begin
			cl_part <= 32'b0;
		end
		else if (en)
		begin
			cl_part = incoming_cl[255:224];			
			
			bit_result[28] <= (cl_part[7:0] == predicate);
			bit_result[29] <= (cl_part[15:8] == predicate);
			bit_result[30] <= (cl_part[23:16] == predicate);
			bit_result[31] <= (cl_part[31:24] == predicate);	

			//$display("8th part: %0d - %0d - %0d - %0d", cl_part[7:0], cl_part[15:8], cl_part[23:16], cl_part[31:24]);
		end
	end
			
	
	//9th partition
	always_ff @(posedge clk)
	begin
		logic [31:0] cl_part;
		if (reset)
		begin
			cl_part <= 32'b0;
		end
		else if (en)
		begin					
			cl_part = incoming_cl[287:256];
			
			bit_result[32] <= (cl_part[7:0] == predicate);
			bit_result[33] <= (cl_part[15:8] == predicate);
			bit_result[34] <= (cl_part[23:16] == predicate);
			bit_result[35] <= (cl_part[31:24] == predicate);		

			//$display("9th part: %0d - %0d - %0d - %0d", cl_part[7:0], cl_part[15:8], cl_part[23:16], cl_part[31:24]);	
		end
	end
	
	//10th partition
	always_ff @(posedge clk)
	begin
		logic [31:0] cl_part;
		if (reset)
		begin
			cl_part <= 32'b0;
		end
		else if (en)
		begin					
			cl_part = incoming_cl[319:288];
			
			bit_result[36] <= (cl_part[7:0] == predicate);
			bit_result[37] <= (cl_part[15:8] == predicate);
			bit_result[38] <= (cl_part[23:16] == predicate);
			bit_result[39] <= (cl_part[31:24] == predicate);	

			//$display("10th part: %0d - %0d - %0d - %0d", cl_part[7:0], cl_part[15:8], cl_part[23:16], cl_part[31:24]);			
		end
	end
	
	//11th partition
	always_ff @(posedge clk)
	begin
		logic [31:0] cl_part;
		if (reset)
		begin
			cl_part <= 32'b0;
		end
		else if (en)
		begin
			cl_part = incoming_cl[351:320];
			
			bit_result[40] <= (cl_part[7:0] == predicate);
			bit_result[41] <= (cl_part[15:8] == predicate);
			bit_result[42] <= (cl_part[23:16] == predicate);
			bit_result[43] <= (cl_part[31:24] == predicate);		
	
			//$display("11th part: %0d - %0d - %0d - %0d", cl_part[7:0], cl_part[15:8], cl_part[23:16], cl_part[31:24]);		
		end
	end
	
	//12th partition
	always_ff @(posedge clk)
	begin
		logic [31:0] cl_part;
		if (reset)
		begin
			cl_part <= 32'b0;
		end
		else if (en)
		begin		
			cl_part = incoming_cl[383:352];
			
			bit_result[44] <= (cl_part[7:0] == predicate);
			bit_result[45] <= (cl_part[15:8] == predicate);
			bit_result[46] <= (cl_part[23:16] == predicate);
			bit_result[47] <= (cl_part[31:24] == predicate);		

			//$display("12th part: %0d - %0d - %0d - %0d", cl_part[7:0], cl_part[15:8], cl_part[23:16], cl_part[31:24]);		
		end
	end

	//13th partition
	always_ff @(posedge clk)
	begin
		logic [31:0] cl_part;
		if (reset)
		begin
			cl_part <= 32'b0;
		end
		else if (en)
		begin		
			cl_part = incoming_cl[415:384];
			
			bit_result[48] <= (cl_part[7:0] == predicate);
			bit_result[49] <= (cl_part[15:8] == predicate);
			bit_result[50] <= (cl_part[23:16] == predicate);
			bit_result[51] <= (cl_part[31:24] == predicate);			
	
			//$display("13th part: %0d - %0d - %0d - %0d", cl_part[7:0], cl_part[15:8], cl_part[23:16], cl_part[31:24]);
		end
	end
	
	//14th partition
	always_ff @(posedge clk)
	begin
		logic [31:0] cl_part;
		if (reset)
		begin
			cl_part <= 32'b0;
		end
		else if (en)
		begin					 
			cl_part = incoming_cl[447:416];
			
			bit_result[52] <= (cl_part[7:0] == predicate);
			bit_result[53] <= (cl_part[15:8] == predicate);
			bit_result[54] <= (cl_part[23:16] == predicate);
			bit_result[55] <= (cl_part[31:24] == predicate);		

			//$display("14th part: %0d - %0d - %0d - %0d", cl_part[7:0], cl_part[15:8], cl_part[23:16], cl_part[31:24]);	
		end
	end
	
	//15th partition
	always_ff @(posedge clk)
	begin
		logic [31:0] cl_part;
		if (reset)
		begin
			cl_part <= 32'b0;
		end
		else if (en)
		begin				
			cl_part = incoming_cl[479:448];
			
			bit_result[56] <= (cl_part[7:0] == predicate);
			bit_result[57] <= (cl_part[15:8] == predicate);
			bit_result[58] <= (cl_part[23:16] == predicate);
			bit_result[59] <= (cl_part[31:24] == predicate);		
	
			//$display("15th part: %0d - %0d - %0d - %0d", cl_part[7:0], cl_part[15:8], cl_part[23:16], cl_part[31:24]);	
		end
	end
	
	//16th partition
	always_ff @(posedge clk)
	begin
		logic [31:0] cl_part;
		if (reset)
		begin
			cl_part <= 32'b0;
		end
		else if (en)
		begin		
			cl_part = incoming_cl[511:480];
			
			bit_result[60] <= (cl_part[7:0] == predicate);
			bit_result[61] <= (cl_part[15:8] == predicate);
			bit_result[62] <= (cl_part[23:16] == predicate);
			bit_result[63] <= (cl_part[31:24] == predicate);	

			//$display("16th part: %0d - %0d - %0d - %0d", cl_part[7:0], cl_part[15:8], cl_part[23:16], cl_part[31:24]);
		end
	end
	
endmodule
