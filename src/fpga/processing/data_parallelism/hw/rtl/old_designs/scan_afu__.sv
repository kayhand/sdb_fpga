`include "cci_mpf_if.vh"
`include "afu_json_info.vh"

localparam CL_BYTE_IDX_BITS = 6;
typedef logic [$bits(t_cci_clAddr) + CL_BYTE_IDX_BITS - 1 : 0] t_byteAddr;

function automatic t_cci_clAddr byteAddrToClAddr(t_byteAddr addr);
	return addr[CL_BYTE_IDX_BITS +: $bits(t_cci_clAddr)];
endfunction

function automatic t_byteAddr clAddrToByteAddr(t_cci_clAddr addr);
	return {addr, CL_BYTE_IDX_BITS'(0)};
endfunction

localparam READ_REQ_SIZE = 1;
localparam WRITE_REQ_SIZE = 1;

module scan_afu
	(
		input  logic clk,
		input  logic reset,

		// CCI-P request/response
		input  t_if_ccip_Rx cp2af_sRx,
		output t_if_ccip_Tx af2cp_sTx,

		// CSR connections
		app_csrs.app csrs,

		// MPF tracks outstanding requests.  These will be true as long as
		// reads or unacknowledged writes are still in flight.
		input  logic c0NotEmpty,
		input  logic c1NotEmpty
	);
	
	/*** 
	 *
	 *	READ IN QUERY PARAMETERS FROM CSRs 
	 *	 	
	 ***/
	
	/*** 
	 *	READ BUFFER ADDRESS (CSRS[4])  
	 ***/	
	logic new_partition_ready;
	t_ccip_clAddr read_buff_address;
	always_ff @(posedge clk)
	begin
		new_partition_ready <= csrs.cpu_wr_csrs[4].en;
		if (csrs.cpu_wr_csrs[4].en)
		begin			
			read_buff_address <= byteAddrToClAddr(csrs.cpu_wr_csrs[4].data);		
		end
	end
	
	/*** 
	 *	WRITE BUFFER ADDRESS (CSRS[5])  
	 ***/	
	t_ccip_clAddr write_buff_address;
	always_ff @(posedge clk)
	begin
		if (csrs.cpu_wr_csrs[5].en)
		begin
			write_buff_address <= byteAddrToClAddr(csrs.cpu_wr_csrs[5].data);		
		end
	end

	/*** 
	 *	QUERY STATE (CSRS[5])  
	 ***/		
	logic query_completed;
	always_ff @(posedge clk)
	begin
		if (csrs.cpu_wr_csrs[6].en)
		begin	
			query_completed <= csrs.cpu_wr_csrs[6].en;
			//$display("All partitions processed!\n");
		end	
	end
							
	/*** 
	 *	TOTAL CACHE-LINES IN EACH INCOMING PARTITION BLOCK (CSRS[0]) 
	 ***/
	logic[6:0] total_cls; // total cache lines to read -- SW writes it to the first CSR	
	always_ff @(posedge clk)
	begin
		if (csrs.cpu_wr_csrs[0].en)
		begin
			total_cls <= csrs.cpu_wr_csrs[0].data; // (4 - 1)
			
			//total_cl_blocks <= csrs.cpu_wr_csrs[0].data / CL_REQ_SIZE - 1; // 63
			//$display("\nAFU will read %0d cache lines in total!", csrs.cpu_wr_csrs[0].data);		
		end
	end
	
	/*** 
	 *	FILTER PREDICATE VALUE (CSRS[1]) 
	 ***/
	logic[31:0] filter_pred; // predicate for the scan operation -- SW writes it to the second CSR
	always_ff @(posedge clk)
	begin
		if (csrs.cpu_wr_csrs[1].en)
		begin			
			filter_pred <= csrs.cpu_wr_csrs[1].data;
			//$display("AFU received the filter predicate: %0d\n", csrs.cpu_wr_csrs[1].data);		
		end
	end
	
	/***
	 *	BIT-ENCODING 
	 ***/
	// 0: 4-bits, 1: 8-bits , 2: 16-bits, 3: 32-bits
	logic [1:0] bit_encoding; 
	always_ff @(posedge clk)
	begin
		if (csrs.cpu_wr_csrs[2].en)
		begin
			bit_encoding <= csrs.cpu_wr_csrs[2].data; 	
			//$display("Bit encoding: %0d", csrs.cpu_wr_csrs[2].data);
		end
	end
	
	/***
	 *	PARALLELISM 	 
	 * 0: 128-way, 1: 64-way, 2: 32-way, 3: 16-way
	 * 4: 8-way, 5: 4-way, 6: 2-way, 7: 1-way
	 * 
	 * ***/
	logic [2:0] parallelism; //3-bits for 7 different options 
	always_ff @(posedge clk)
	begin
		if (csrs.cpu_wr_csrs[3].en)
		begin
			parallelism <= csrs.cpu_wr_csrs[3].data; 	
			//$display("Parallelism: %0d", csrs.cpu_wr_csrs[3].data);
		end
	end

	logic [7:0] total_cls_processed = 0;
	logic partition_processed = 0;
	logic write_processed = 0;
	
	always_ff @(posedge clk)
	begin
		if(csrs.cpu_wr_csrs[4].en)
		begin
			total_cls_processed <= 0;
			
			partition_processed <= 1'b0;
			write_processed <= 1'b0;	
			
			$display("New partition ready!");
		end
		else if(csrs.cpu_wr_csrs[6].en)
		begin
			total_cls_processed <= total_cls;
			
			partition_processed <= 1'b1;
			write_processed <= 1'b1;
			$display("Partition completed!");			
		end
	end
	
	// CSRS writes to notify the SW about processing	
	always_comb
	begin
		csrs.afu_id = `AFU_ACCEL_UUID;	
		for (int i = 0; i < 8; i = i + 1)
		begin
			csrs.cpu_rd_csrs[i].data = 64'(0);
		end
		
		csrs.cpu_rd_csrs[3].data = bit_encoding;
		csrs.cpu_rd_csrs[4].data = parallelism;
		
		csrs.cpu_rd_csrs[0].data = total_cls_processed; 
		csrs.cpu_rd_csrs[1].data = partition_processed;
		csrs.cpu_rd_csrs[2].data = write_processed;
		
	end
	
	assign af2cp_sTx.c0.valid = 1'b0;
	assign af2cp_sTx.c1.valid = 1'b0;
	assign af2cp_sTx.c2.mmioRdValid = 1'b0;

endmodule