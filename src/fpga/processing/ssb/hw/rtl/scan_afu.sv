`include "afu_json_info.vh"
`include "helper.vh"

module scan_afu
	(
		input  logic clk,
		input  logic reset,
		
		input  logic is_active,

		// CCI-P request/response
		input  t_if_ccip_Rx cp2af_sRx,
		output t_if_ccip_Tx af2cp_sTx,

		// CSR connections
		app_csrs.app csrs,

		// MPF tracks outstanding requests.  These will be true as long as
		// reads or unacknowledged writes are still in flight.
		input  logic c0NotEmpty,
		input  logic c1NotEmpty,
		
		input logic join_partition_processed
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
		if(is_active)
		begin
			new_partition_ready <= csrs.cpu_wr_csrs[4].en;
			if (csrs.cpu_wr_csrs[4].en)
			begin			
				read_buff_address <= byteAddrToClAddr(csrs.cpu_wr_csrs[4].data);		
			end
		end
	end
	
	/*** 
	 *	WRITE BUFFER ADDRESS (CSRS[5])  
	 ***/	
	t_ccip_clAddr write_buff_address;
	always_ff @(posedge clk)
	begin
		if (csrs.cpu_wr_csrs[5].en && is_active)
		begin
			write_buff_address <= byteAddrToClAddr(csrs.cpu_wr_csrs[5].data);		
		end
	end
							
	/*** 
	 *	TOTAL CACHE-LINES IN EACH INCOMING PARTITION BLOCK (CSRS[0]) 
	 ***/
	logic[6:0] total_cls; // total cache lines to read -- SW writes it to the first CSR	
	always_ff @(posedge clk)
	begin
		if (csrs.cpu_wr_csrs[0].en && is_active)
		begin
			total_cls <= csrs.cpu_wr_csrs[0].data; // (4 - 1)
			
			//total_cl_blocks <= csrs.cpu_wr_csrs[0].data / CL_REQ_SIZE - 1; // 63
			//$display("\nAFU will read %0d cache lines in total!", csrs.cpu_wr_csrs[0].data);		
		end
	end
	
	/*** 
	 *	FILTER PREDICATE VALUE (CSRS[1]) 
	 ***/
	//might be a single value or two predicates padded together
	logic[7:0] filter_pred; // predicate for the scan operation -- SW writes it to the second CSR	
	always_ff @(posedge clk)
	begin
		if (csrs.cpu_wr_csrs[1].en && is_active)
		begin			
			filter_pred <= csrs.cpu_wr_csrs[1].data;
			//$display("AFU received the filter predicate: %0d\n", csrs.cpu_wr_csrs[1].data);		
		end
	end
	
	/***
	 *	SCAN_COLUMN (CSRS[2])
	 ***/
	// 0: d_year, 1: lo_discount , 2: lo_quantity
	
	logic [1:0] scan_column; 
	always_ff @(posedge clk)
	begin
		if (csrs.cpu_wr_csrs[2].en && is_active)
		begin
			scan_column <= csrs.cpu_wr_csrs[2].data; 	
			$display("Scan Id: %0d", csrs.cpu_wr_csrs[2].data);
		end
	end
	
	typedef enum logic [2:0]
	{
		STATE_WAITING,
		STATE_IDLE,
		STATE_REQ,
		STATE_RSP,
		STATE_PROCESSING
	}
	t_state;
	t_state state;

	// State transition parameters	
	logic cl_req_allowed = 0;
	logic cl_req_issued = 0;
	logic cl_received = 0;	
	logic [2:0] cl_processed;
	
	logic partition_processed; 
	logic write_processed;
	
	// State counters
	int total_cls_processed = 0; // 0, 1, 2, ..., 63

	always_ff @(posedge clk)
	begin
		if (reset)
		begin
			state <= STATE_WAITING;
		end
		else
		begin
			case (state)		
				STATE_WAITING:
				begin
					if(new_partition_ready)
					begin
						state <= STATE_IDLE;
						$display("[SCAN] WAITING -> IDLE (cls: %d)...", total_cls_processed);
					end
				end
				
				STATE_IDLE:
				begin
					if (cl_req_allowed)
					begin
						//$display("IDLE -> REQ ...");
						state <= STATE_REQ;
					end
					else if (partition_processed)
					begin
						$display("[SCAN] IDLE -> WAITING (cls: %d)...", total_cls_processed);
						state <= STATE_WAITING;
					end
				end
				STATE_REQ:
				begin
					if(cl_req_issued)
					begin						
						//$display("REQ -> RSP (cls: %d)...", total_cls_processed);
						state <= STATE_RSP;
						
						//cl_req_issued <= 1'b0;	
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
	
	/* * * * * * * * * * * * *
	 **************************
	 * * * MAIN AFU LOGIC * * * 
	 **************************
	 * * * * * * * * * * * * */
	
	int res_count = 0;
	always_ff @(posedge clk)
	begin
		if (reset)
		begin			
			cl_req_allowed <= 1'b1;
			total_cls_processed <= 1'b0;
			partition_processed <= 1'b0;
			res_count = 0;
		end
		else if (new_partition_ready)
		begin
			cl_req_allowed <= 1'b1;
			total_cls_processed <= 1'b0;
			partition_processed <= 1'b0;
			res_count = 0;
		end
		else if (state == STATE_PROCESSING && cl_processed)
		begin
			cl_req_allowed <= ((total_cls_processed + 1) < total_cls);		
			partition_processed <= ((total_cls_processed + 1) == total_cls);
			
			total_cls_processed <= total_cls_processed + 1;	
		end
		else if (state == STATE_WAITING && new_partition_ready)
		begin
			partition_processed <= 1'b0;
		end
		else if (state == STATE_WAITING)
		begin
			total_cls_processed <= 0;			
		end
	end

	//
	// READ REQUEST 
	//
	t_ccip_c0_ReqMemHdr read_req_hdr;
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
				af2cp_sTx.c0.valid <= !cp2af_sRx.c0TxAlmFull && !cl_req_issued;
				af2cp_sTx.c0.hdr <= read_req_hdr;
				
				cl_req_issued <= !cp2af_sRx.c0TxAlmFull && !cl_req_issued;
			
				/*if(!cp2af_sRx.c0TxAlmFull && !cl_req_issued)
				begin
					$display("==>");
					$display("==> REQ for CL block #%d issued! ==>", total_cls_processed);
					$display("==>\n");
				end*/
			end
			else if(state == STATE_RSP)
			begin
				cl_req_issued <= 1'b0;
			end
		end
	end

	//
	// READ RESPONSE
	//	
	t_ccip_c0_RspMemHdr read_rsp_hdr;
	t_ccip_clData rsp_data;	
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
	logic [511:0] bit_result_1;
	logic [511:0] bit_result_2;
	logic [511:0] bit_result_3;
	
	d_year d_year_scan
	(
		.clk,
		
		.reset(state == STATE_IDLE),
		.en(state == STATE_PROCESSING && scan_column == 0),
		
		.predicate(filter_pred[3:0]),
		.d_year_cl(rsp_data),
		
		.total_cls_processed,
		
		.bit_result(bit_result_1),
		.processing_done(cl_processed[0])
	);
	
	lo_discount lo_discount_scan
	(
		.clk,
		
		.reset(state == STATE_IDLE),
		.en(state == STATE_PROCESSING && scan_column == 1),
		
		.lower_pred(filter_pred[3:0]),
		.higher_pred(filter_pred[7:4]),
		
		.incoming_cl(rsp_data),
		
		.total_cls_processed,
		
		.bit_result(bit_result_2),
		.processing_done(cl_processed[1])
	);
	
	lo_quantity lo_quantity_scan
	(
		.clk,
		
		.reset(state == STATE_IDLE),
		.en(state == STATE_PROCESSING && scan_column == 2),
		
		.predicate(filter_pred[7:0]),
		.incoming_cl(rsp_data),
		
		.bit_result(bit_result_3),
		.processing_done(cl_processed[2])
	);	
	
	// Control logic for memory writes 
	t_ccip_c1_ReqMemHdr write_hdr;
	logic write_issued;	
	always_ff @(posedge clk)
	begin
		if (reset)
		begin
			af2cp_sTx.c1.valid <= 1'b0;
		end
		else
		begin
			af2cp_sTx.c1.valid <= ((state == STATE_PROCESSING) 
					&& cl_processed && !cp2af_sRx.c1TxAlmFull);						
			af2cp_sTx.c1.data <= (bit_result_1 | bit_result_2 | bit_result_3);
			af2cp_sTx.c1.hdr <= write_hdr;
			
			write_issued <= !((state == STATE_PROCESSING) && cl_processed && !cp2af_sRx.c1TxAlmFull);
				
			/*if((state == STATE_PROCESSING) 
					&& cl_processed && !cp2af_sRx.c1TxAlmFull)
			begin
				$display("\n==>");
				$display("==> WRITE ISSUED (cls: %d) ==>", total_cls_processed);
				$display("==> Bit_result: %0b ", bit_result);
				
				foreach(bit_result[idx]) begin
					res_count += bit_result[idx];
				end
				$display("==> Count: %d", res_count);
				
				$display("==>\n");
			end*/
		end
	end
		
	always_ff @(posedge clk)
	begin
		if(reset || new_partition_ready)
		begin
			write_processed <= 1'b0;
		end
		else if(partition_processed && cci_c1Rx_isWriteRsp(cp2af_sRx.c1))
		begin
			write_processed <= 1'b1;
		end
		else if(state == STATE_IDLE && cl_processed == 0)
		begin
			write_processed <= 1'b0;
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
	//always_comb
	//begin
		//csrs.afu_id = `AFU_ACCEL_UUID;	
		/*for (int i = 0; i < 4; i = i + 1)
		begin
			csrs.cpu_rd_csrs[i].data = 64'(0);
		end*/
		
	//	csrs.cpu_rd_csrs[0].data = total_cls_processed; 
	//	csrs.cpu_rd_csrs[1].data = partition_processed;
	//	csrs.cpu_rd_csrs[2].data = write_processed;
	//end
	
	always_comb
	begin
		csrs.afu_id = `AFU_ACCEL_UUID;
		for (int i = 0; i < 8; i = i + 1)
		begin
			csrs.cpu_rd_csrs[i].data = 64'(0);
		end	
		csrs.cpu_rd_csrs[1].data = partition_processed;
		csrs.cpu_rd_csrs[5].data = join_partition_processed;			
	end
	
	//assign af2cp_sTx.c1.valid = 1'b0;
	assign af2cp_sTx.c2.mmioRdValid = 1'b0;

endmodule