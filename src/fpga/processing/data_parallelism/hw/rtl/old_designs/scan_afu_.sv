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

	typedef enum logic [2:0]
	{
		STATE_IDLE,
		STATE_REQ,
		STATE_RSP,
		STATE_PROCESSING,
		STATE_DONE
	}
	t_state;
	t_state state;

	// State transition parameters
	
	logic cl_req_allowed;
	logic cl_received;	
	logic req_issued;
	
	logic cl_processed;
	
	logic partition_processed; 
	
	// State counters
	
	logic[5:0] total_cls_processed = 0; // 0, 1, 2, ..., 63

	always_ff @(posedge clk)
	begin
		if (reset)
		begin
			state <= STATE_IDLE;
		end
		else
		begin
			case (state)		
				STATE_IDLE:
				begin
					if (cl_req_allowed)
					begin
						//$display("IDLE -> REQ ...");
						state <= STATE_REQ;
					end
					else if (query_completed)
					begin
						//$display("IDLE -> DONE (cls: %d)...", total_cls_processed);
						state <= STATE_DONE;
					end
				end
				STATE_REQ:
				begin
					if(req_issued)
					begin						
						//$display("REQ -> RSP (cls: %d)...", total_cls_processed);
						state <= STATE_RSP;
						
						//req_issued <= 1'b0;	
					end
				end
				STATE_RSP:
				begin
					if(cl_received)
					begin
						//$display("RSP -> PROCESSING (cls: %d)...", total_cls_processed);
						state <= STATE_PROCESSING;
						
						//total_cls_processed <= total_cls_processed + 1;
						
						//cl_received <= 1'b0;
					end
				end
				STATE_PROCESSING:
				begin
					if(cl_processed)
					begin
						//$display("PROCESSING -> IDLE (cls: %d)...", total_cls_processed);																					
						state <= STATE_IDLE;
					end				
				end
			endcase
		end
	end	
	
	
	/*
	t_state curr_state;
	always_comb
	begin		
		curr_state = state;
		case (state)			
			STATE_IDLE:
			begin
				$display("\n 	+++++++++++");
				$display(" 	IDLE STATE!");				
				$display(" 	+++++++++++\n");
			end

			STATE_REQ:
			begin
				$display("\n 	+++++++++++");
				$display(" 	REQUEST STATE!");
				$display(" 	+++++++++++\n");
			end

			STATE_RSP:
			begin
				$display("\n  +++++++++++");
				$display("  RESPONSE STATE!");
				$display("  +++++++++++\n");
			end
			
			STATE_PROCESSING:
			begin
				$display("\n 	+++++++++++");				
				$display("  PROCESSING STATE!");
				$display("  +++++++++++\n");
			end
			
			STATE_DONE:
			begin
				$display("\n 	+++++++++++");				
				$display("  DONE!");
				$display("  +++++++++++\n");
			end
		endcase
	end*/

	
	//logic [7:0] cl_id = 1; // 1 - 64
	
	// READ/WRITE HEADER SETUP
	t_ccip_c0_ReqMemHdr read_req_hdr;
	t_ccip_c1_ReqMemHdr write_hdr;
	
	//logic cl_reqs_done;
		
	/* * * * * * * * * * * * *
	**************************
	* * * MAIN AFU LOGIC * * * 
	**************************
	* * * * * * * * * * * * */

	always_ff @(posedge clk)
	begin
		if (reset)
		begin
			cl_req_allowed <= 1'b0;
		end
		else if (new_partition_ready)
		begin
			total_cls_processed <= 1'b0;
			partition_processed <= 1'b0;
			
			cl_req_allowed <= 1'b1;
		end
		else if (state == STATE_PROCESSING && cl_processed)
		begin
			cl_req_allowed <= ((total_cls_processed + 1) < total_cls);		
			partition_processed <= ((total_cls_processed + 1) == total_cls);
			
			total_cls_processed <= total_cls_processed + 1;	
		end
	end
	
	//
	// READ REQUEST 
	//	
	always_ff @(posedge clk)
	begin
		if (reset)
		begin
			af2cp_sTx.c0.valid <= 1'b0;			
		end
		else
		begin
			if(state == STATE_REQ)
			begin			
				af2cp_sTx.c0.valid <= !cp2af_sRx.c0TxAlmFull && !req_issued;
				af2cp_sTx.c0.hdr <= read_req_hdr;
				
				req_issued <= !cp2af_sRx.c0TxAlmFull && !req_issued;
			
				/*if(!cp2af_sRx.c0TxAlmFull && !req_issued)
				begin
					$display("==>");
					$display("==> REQ for CL block #%d issued! ==>", total_cls_processed);
					$display("==>\n");
				end*/
			end
			else if(state == STATE_RSP)
			begin
				req_issued <= 1'b0;
			end
		end
	end

	t_ccip_c0_RspMemHdr read_rsp_hdr;
	t_ccip_clData rsp_data;
	
	//
	// READ RESPONSE
	//
	logic rsp_received;
	always_ff @(posedge clk)
	begin		
		if(state == STATE_RSP)
		begin
			cl_received <= cci_c0Rx_isReadRsp(cp2af_sRx.c0);
			if(cci_c0Rx_isReadRsp(cp2af_sRx.c0))
			begin
				rsp_data <= cp2af_sRx.c0.data;
			end
				
			/*if(cci_c0Rx_isReadRsp(cp2af_sRx.c0))
			begin				
			
				$display("CL block received ...");				
				$display("\n");
				$display("<== RSP for CL block %0d (cls processed %0d)", cp2af_sRx.c0.hdr.mdata, 
					(total_cls_processed));
				$display("Filter processed? %b", cl_processed);
				$display("\n");					
			end*/
		end
		else if(state == STATE_PROCESSING)
		begin
			cl_received <= 1'b0;
		end
	end

	//
	// READ RESPONSE PROCESSING
	//
	logic [511:0] bit_result;
	
	logic [127:0] result_128way;
	logic [127:0] result_64way;
	logic [127:0] result_32way;
	logic [127:0] result_16way;
	
	logic done_128way;
	logic [1:0] done_64way;
	logic [3:0] done_32way;
	logic [7:0] done_16way;
	
	p128 scan_128way
	(
		.clk,
			
		.reset(reset || new_partition_ready),
		.en((parallelism == 0) && (state == STATE_PROCESSING)),				
				
		.incoming_cl(rsp_data),
		.predicate(filter_pred),
		
		.bit_result(result_128way),
		.done(done_128way)
	);
	
	p64 scan_64way1
	(
		.clk,
			
		.reset(reset || new_partition_ready),
		.en((parallelism == 1) && (state == STATE_PROCESSING)),				
				
		.incoming_cl(rsp_data[255:0]),
		.predicate(filter_pred),
		
		.bit_result(result_64way[63:0]),
		.done(done_64way[0])
	);
	
	p64 scan_64way2
	(
		.clk,
			
		.reset(reset || new_partition_ready),
		.en((parallelism == 1) && (state == STATE_PROCESSING)),				
				
		.incoming_cl(rsp_data[511:256]),
		.predicate(filter_pred),
		
		.bit_result(result_64way[127:64]),
		.done(done_64way[1])
	);
	
	/*
	p32 scan_32way1
	(
		.clk,
			
		.reset(reset || new_partition_ready),
		.en((parallelism == 2) && (state == STATE_PROCESSING)),				
				
		.incoming_cl(rsp_data[127:0]),
		.predicate(filter_pred),
		
		.bit_result(bit_result[31:0]),
		.done(done_32way[0])
	);
	
	p32 scan_32way2
	(
		.clk,
			
		.reset(reset || new_partition_ready),
		.en((parallelism == 2) && (state == STATE_PROCESSING)),				
				
		.incoming_cl(rsp_data[255:128]),
		.predicate(filter_pred),
		
		.bit_result(bit_result[63:31]),
		.done(done_32way[1])
	);
	
	p32 scan_32way3
	(
		.clk,
			
		.reset(reset || new_partition_ready),
		.en((parallelism == 2) && (state == STATE_PROCESSING)),				
				
		.incoming_cl(rsp_data[383:256]),
		.predicate(filter_pred),
		
		.bit_result(bit_result[95:64]),
		.done(done_32way[2])
	);
	
	p32 scan_32way4
	(
		.clk,
			
		.reset(reset || new_partition_ready),
		.en((parallelism == 2) && (state == STATE_PROCESSING)),				
				
		.incoming_cl(rsp_data[511:384]),
		.predicate(filter_pred),
		
		.bit_result(bit_result[127:96]),
		.done(done_32way[3])
	);*/
	
	always_comb
	begin
		if(state == STATE_PROCESSING)
		begin
			if(parallelism == 0)
			begin
				cl_processed = (done_128way == 1'b1);					
				bit_result = result_128way;
			end
			else if(parallelism == 1)
			begin
				cl_processed = (done_64way == 2'b11);			
				bit_result = result_64way;
			end
			else if(parallelism == 2)
			begin
				cl_processed <= (done_32way == 4'b1111);				
				bit_result = result_32way;
			end
			else if(parallelism == 3)
			begin
				cl_processed <= (done_16way == 8'b11111111);			
				bit_result = result_16way;
			end
		end
		else if(state == STATE_IDLE)
		begin
			cl_processed <= 1'b0;			
			bit_result <= 0;
		end
	end
		
	genvar ind;
	generate 
		for (ind = 0; ind < 2; ind = ind + 1) 
		begin
			p64 scan_64way
			(
				.clk,
		
				.reset(reset || new_partition_ready),
				.en((parallelism == 1) && (state == STATE_PROCESSING)),
				.unit_id(ind),
		
				.incoming_cl(rsp_data[ind * 256 +: 256]),
				.predicate(filter_pred),
		
				.bit_result(result_64way[ind * 64 +: 64]),
				//.done(cl_processed[ind * 16 +: 16])
				.done(done_64way[ind])
			); 
		end
	endgenerate
		
	genvar ind2;
	generate 
		for (ind2 = 0; ind2 < 4; ind2 = ind2 + 1) 
		begin
			p32 scan_32way
			(
				.clk,
		
				.reset(reset || new_partition_ready),
				.en((parallelism == 2) && (state == STATE_PROCESSING)),
				.unit_id(ind2),
		
				.incoming_cl(rsp_data[ind2 * 128 +: 128]),
				.predicate(filter_pred),
		
				.bit_result(result_32way[ind2 * 32 +: 32]),
				//.done(cl_processed[ind2 * 8 +: 8])
				.done(done_32way[ind2])
			); 
		end
	endgenerate

	genvar ind3;
	generate 
		for (ind3 = 0; ind3 < 8; ind3 = ind3 + 1) 
		begin
			p16 scan_16way
			(
				.clk,
		
				.reset(reset || new_partition_ready),
				.en((parallelism == 3) && (state == STATE_PROCESSING)),
				.unit_id(ind3),
		
				.incoming_cl(rsp_data[ind3 * 64 +: 64]),
				.predicate(filter_pred),
		
				.bit_result(result_16way[ind3 * 16 +: 16]),
				//.done(cl_processed[ind3 * 4 + 4])
				.done(done_16way[ind3])
			); 
		end
	endgenerate
	
	/*
	genvar ind4;
	generate 
		for (ind4 = 0; ind4 < 16; ind4 = ind4 + 1) 
		begin
			p8 scan_8way
			(
				.clk,
		
				.reset(reset || new_partition_ready),
				.en((parallelism == 4) && (state == STATE_PROCESSING)),
				.unit_id(ind4),
		
				.incoming_cl(rsp_data[ind4 * 32 +: 32]),
				.predicate(filter_pred),
		
				.bit_result(bit_result[ind4 * 8 +: 8]),
				.done(cl_processed[ind4 * 2 + 2])			
			); 
		end
	endgenerate*/
	
	/*
	genvar ind5;
	generate 
		for (ind5 = 0; ind5 < 32; ind5 = ind5 + 1) 
		begin
			p4 scan_4way
			(
				.clk,
		
				.reset(reset || new_partition_ready),
				.en((parallelism == 5) && (state == STATE_PROCESSING)),
		
				.incoming_cl(rsp_data[ind5 * 16 +: 16]),
				.predicate(filter_pred),
		
				.bit_result(bit_result[ind5 * 4 +: 4]),
				.done(cl_processed[ind5])			
			);
		end
	endgenerate*/
	
	
	/*always_ff @(posedge clk)
	begin
		if(new_partition_ready)
		begin
			total_cls_processed <= 0;			
			$display("\nWELCOME TO NANI!!!\n");
		end

		else if (cl_processed)
		begin
			
			$display("CL %d (%b)", total_cls_processed, cl_processed);
			
			$display("Bit Result_1: %b", bit_result[15:0]);
			$display("Bit Result_2: %b", bit_result[31:16]);
			
			$display("Bit Result_3: %b", bit_result[47:32]);
			$display("Bit Result_4: %b", bit_result[63:48]);
			
			$display("Bit Result_5: %b", bit_result[79:64]);
			$display("Bit Result_6: %b", bit_result[95:80]);
			
			$display("Bit Result_7: %b", bit_result[111:96]);
			$display("Bit Result_8: %b", bit_result[127:112]);
		end
	end*/
		
	// Control logic for memory writes 
	logic write_issued;	
	always_ff @(posedge clk)
	begin
		if (reset)
		begin
			af2cp_sTx.c1.valid <= 1'b0;
		end
		else
		begin
			af2cp_sTx.c1.valid <= (cl_processed && !cp2af_sRx.c1TxAlmFull);			
			
			/*if(parallelism == 0)
			begin
				af2cp_sTx.c1.data <= result_128way;
			end
			else if(parallelism == 1)
			begin
				af2cp_sTx.c1.data <= result_64way;
			end*/			
			
			af2cp_sTx.c1.data <= bit_result;
			af2cp_sTx.c1.hdr <= write_hdr;
			write_issued <= !(cl_processed && !cp2af_sRx.c1TxAlmFull);
				
			/*if(cl_processed && !cp2af_sRx.c1TxAlmFull)
			begin
				$display("==>");
				$display("==> WRITE REQUEST (cls: %d) ==>", total_cls_processed);
				$display("==>\n");				
		 	end*/
		end
	end
	
	logic write_processed;
	always_ff @(posedge clk)
	begin
		if(reset)
		begin
			write_processed <= 1'b0;
		end
		else if(cci_c1Rx_isWriteRsp(cp2af_sRx.c1))
		begin
			write_processed <= 1'b1;
		end
	end
	
	// READ HEADER SETUP
	always_comb
	begin
		read_req_hdr = t_ccip_c0_ReqMemHdr'(0);
		
		read_req_hdr.vc_sel = eVC_VA;
		read_req_hdr.req_type = eREQ_RDLINE_I;
		
		//eCL_LEN_1 -> 00 (0)
		//eCL_LEN_2 -> 01 (1)
		//eCL_LEN_4 -> 11 (3)
		//read_req_hdr.cl_len = t_ccip_clLen'(READ_REQ_SIZE - 1);
		read_req_hdr.cl_len = eCL_LEN_1;
		
		//read_req_hdr.mdata = buff_offset;		
		//read_req_hdr.address = read_buff_address + (buff_offset * READ_REQ_SIZE);
		
		read_req_hdr.address = read_buff_address + total_cls_processed;
	end

	// WRITE HEADER SETUP
	always_comb
	begin
		write_hdr = t_cci_c1_ReqMemHdr'(0);
	
		write_hdr.vc_sel = eVC_VA;
		write_hdr.sop = 1'b1;
		write_hdr.cl_len = eCL_LEN_1;
		write_hdr.req_type = eREQ_WRLINE_I; //no intent to cache
		
		//write_hdr.mdata = cl_id;
		write_hdr.mdata = total_cls_processed;
		write_hdr.address = write_buff_address + total_cls_processed;	
	end

	// CSRS writes to notify the SW about processing	
	always_comb
	begin
		csrs.afu_id = `AFU_ACCEL_UUID;	
		for (int i = 0; i < 8; i = i + 1)
		begin
			csrs.cpu_rd_csrs[i].data = 64'(0);
		end
		
		csrs.cpu_rd_csrs[0].data = total_cls_processed; 
		csrs.cpu_rd_csrs[1].data = partition_processed;
		csrs.cpu_rd_csrs[2].data = write_processed;
	end
	
	//assign af2cp_sTx.c1.valid = 1'b0;
	assign af2cp_sTx.c2.mmioRdValid = 1'b0;

endmodule