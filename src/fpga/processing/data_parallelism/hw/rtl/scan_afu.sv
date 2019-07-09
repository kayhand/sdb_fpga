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
	logic[3:0] filter_pred; // predicate for the scan operation -- SW writes it to the second CSR
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
	logic[7:0] cl_processed = 0;
	
	logic partition_processed; 
	logic write_processed;
	
	// State counters
	
	logic[5:0] total_cls_processed = 0; // 0, 1, 2, ..., 63

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
						//$display("IDLE -> DONE (cls: %d)...", total_cls_processed);
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
					if(cl_processed == 8'b11111111)
					begin
						//$display("PROCESSING -> IDLE (cls: %d)...", total_cls_processed);																					
						state <= STATE_IDLE;
					end				
				end
			endcase
		end
	end	

	
	t_state curr_state;
	always_comb
	begin		
		curr_state = state;
		case (state)	
			STATE_WAITING:
			begin
				$display("\n 	+++++++++++");				
				$display(" WAITING FOR A PARTITION!");
				
				$display("total cls: %0d", total_cls_processed);
				$display("allowed: %0b, issued: %0b, received: %0b, processed: %0b",
						cl_req_allowed, cl_req_issued, cl_received, cl_processed);
				$display("p_processed: %0b", partition_processed);
								
				$display("  +++++++++++\n");
			end
			
			STATE_IDLE:
			begin
				$display("\n 	+++++++++++");
				$display(" 	IDLE STATE!");				
								
				$display("total cls: %0d", total_cls_processed);
				$display("allowed: %0b, issued: %0b, received: %0b, processed: %0b",
						cl_req_allowed, cl_req_issued, cl_received, cl_processed);
				$display("p_processed: %0b", partition_processed);
				
				$display(" 	+++++++++++\n");	
			end

			/*STATE_REQ:
			begin
				$display("\n 	+++++++++++");
				$display(" 	REQUEST STATE!");				
				
				$display("total cls: %0d", total_cls_processed);
				$display("allowed: %0b, issued: %0b, received: %0b, processed: %0b",
						cl_req_allowed, cl_req_issued, cl_received, cl_processed);
				$display("p_processed: %0b", partition_processed);
				
				$display(" 	+++++++++++\n");
			end

			STATE_RSP:
			begin
				$display("\n  +++++++++++");
				$display("  RESPONSE STATE!");				
				
				$display("total cls: %0d", total_cls_processed);
				$display("allowed: %0b, issued: %0b, received: %0b, processed: %0b",
						cl_req_allowed, cl_req_issued, cl_received, cl_processed);
				$display("p_processed: %0b", partition_processed);
				
				$display(" 	+++++++++++\n");
			end
			
			STATE_PROCESSING:
			begin
				$display("\n 	+++++++++++");				
				$display("  PROCESSING STATE!");				
				
				$display("total cls: %0d", total_cls_processed);
				$display("allowed: %0b, issued: %0b, received: %0b, processed: %0b",
						cl_req_allowed, cl_req_issued, cl_received, cl_processed);
				$display("p_processed: %0b", partition_processed);
				
				$display(" 	+++++++++++\n");
			end*/

		endcase
	end
	
	
	/* * * * * * * * * * * * *
	 **************************
	 * * * MAIN AFU LOGIC * * * 
	 **************************
	 * * * * * * * * * * * * */

	always_ff @(posedge clk)
	begin
		if (reset)
		begin
			cl_req_allowed <= 1'b1;
			total_cls_processed <= 1'b0;
			partition_processed <= 1'b0;
		end
		else if (new_partition_ready)
		begin
			cl_req_allowed <= 1'b1;
			total_cls_processed <= 1'b0;
			partition_processed <= 1'b0;
		end
		else if (state == STATE_PROCESSING && (cl_processed == 8'b11111111))
		begin
			cl_req_allowed <= ((total_cls_processed + 1) < total_cls);		
			partition_processed <= ((total_cls_processed + 1) == total_cls);
			
			total_cls_processed <= total_cls_processed + 1;	
		end	
		else if (state == STATE_WAITING)
		begin
			total_cls_processed <= 0;			
		end
		else if (state == STATE_WAITING && new_partition_ready)
		begin
			partition_processed <= 1'b0;
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
	
	/*filter_unit u_filter_unit
	(
		.clk,
		
		.reset(state == STATE_IDLE),
		.en(state == STATE_PROCESSING),
		
		.predicate(filter_pred),
		.incoming_cl(rsp_data),
		
		.bit_result(bit_result[127:0]),
		.processing_done(cl_processed)
	);*/
	
	/*
	p64 first_p64
	(
		.clk,
		
		.reset(state == STATE_IDLE),
		.en(state == STATE_PROCESSING),
		
		.predicate(filter_pred),
		.incoming_cl(rsp_data[255:0]),
		
		.bit_result(bit_result[63:0]),
		.processing_done(cl_processed[0])
	);
	
	p64 second_p64
	(
		.clk,
		
		.reset(state == STATE_IDLE),
		.en(state == STATE_PROCESSING && (cl_processed[0] == 1'b1)),
		
		.predicate(filter_pred),
		.incoming_cl(rsp_data[511:256]),
		
		.bit_result(bit_result[127:64]),
		.processing_done(cl_processed[1])
	);*/
	
	/*
	p32 first_p32
	(
		.clk,
		
		.reset(state == STATE_IDLE),
		.en(state == STATE_PROCESSING),
		
		.predicate(filter_pred),
		.incoming_cl(rsp_data[127:0]),
		
		.bit_result(bit_result[31:0]),
		.processing_done(cl_processed[0])
	);
			
	p32 second_p32
	(
		.clk,
		
		.reset(state == STATE_IDLE),
		.en(state == STATE_PROCESSING && (cl_processed[0] == 1'b1)),
		
		.predicate(filter_pred),
		.incoming_cl(rsp_data[255:128]),
		
		.bit_result(bit_result[63:32]),
		.processing_done(cl_processed[1])
	);
	
	p32 third_p32
	(
		.clk,
		
		.reset(state == STATE_IDLE),
		.en(state == STATE_PROCESSING && (cl_processed[1:0] == 2'b11)),
		
		.predicate(filter_pred),
		.incoming_cl(rsp_data[383:256]),
		
		.bit_result(bit_result[95:64]),
		.processing_done(cl_processed[2])
	);
	
	p32 fourth_p32
	(
		.clk,
		
		.reset(state == STATE_IDLE),
		.en(state == STATE_PROCESSING && (cl_processed[2:0] == 3'b111)),
		
		.predicate(filter_pred),
		.incoming_cl(rsp_data[511:384]),
		
		.bit_result(bit_result[127:96]),
		.processing_done(cl_processed[3])
	);
	*/
	
	p16 first_p16
	(
		.clk,
		
		.reset(state == STATE_IDLE),
		.en(state == STATE_PROCESSING),
		
		.predicate(filter_pred),
		
		.incoming_cl(rsp_data[63:0]),
		
		.bit_result(bit_result[15:0]),
		.processing_done(cl_processed[0])
	);
	
	p16 second_p16
	(
		.clk,
		
		.reset(state == STATE_IDLE),
		.en(state == STATE_PROCESSING && (cl_processed[0] == 1'b1)),
		
		.predicate(filter_pred),
		.incoming_cl(rsp_data[127:64]),
		
		.bit_result(bit_result[31:16]),
		.processing_done(cl_processed[1])
	);
	
	p16 third_p16
	(
		.clk,
		
		.reset(state == STATE_IDLE),
		.en(state == STATE_PROCESSING && (cl_processed[1:0] == 2'b11)),
		
		.predicate(filter_pred),
		.incoming_cl(rsp_data[191:128]),
		
		.bit_result(bit_result[47:32]),
		.processing_done(cl_processed[2])
	);
	
	p16 fourth_p16
	(
		.clk,
		
		.reset(state == STATE_IDLE),
		.en(state == STATE_PROCESSING && (cl_processed[2:0] == 3'b111)),
		
		.predicate(filter_pred),
		.incoming_cl(rsp_data[255:192]),
		
		.bit_result(bit_result[63:48]),
		.processing_done(cl_processed[3])
	);
	
	p16 fifth_p16
	(
		.clk,
		
		.reset(state == STATE_IDLE),
		.en(state == STATE_PROCESSING && (cl_processed[3:0] == 4'b1111)),
		
		.predicate(filter_pred),
		.incoming_cl(rsp_data[319:256]),
		
		.bit_result(bit_result[79:64]),
		.processing_done(cl_processed[4])
	);
	
	p16 sixth_p16
	(
		.clk,
		
		.reset(state == STATE_IDLE),
		.en(state == STATE_PROCESSING && (cl_processed[4:0] == 5'b11111)),
		
		.predicate(filter_pred),
		.incoming_cl(rsp_data[383:320]),
		
		.bit_result(bit_result[95:80]),
		.processing_done(cl_processed[5])
	);
	
	p16 seventh_p16
	(
		.clk,
		
		.reset(state == STATE_IDLE),
		.en(state == STATE_PROCESSING && (cl_processed[5:0] == 6'b111111)),
		
		.predicate(filter_pred),
		.incoming_cl(rsp_data[447:384]),
		
		.bit_result(bit_result[111:96]),
		.processing_done(cl_processed[6])
	);
	
	p16 eight_p16
	(
		.clk,
		
		.reset(state == STATE_IDLE),
		.en(state == STATE_PROCESSING && (cl_processed[6:0] == 7'b1111111)),
		
		.predicate(filter_pred),
		.incoming_cl(rsp_data[511:448]),
		
		.bit_result(bit_result[127:112]),
		.processing_done(cl_processed[7])
	);
		

	// Control logic for memory writes 
	t_ccip_c1_ReqMemHdr write_hdr;
	logic write_issued;	
	always_ff @(posedge clk)
	begin
		if (reset)
		begin
			af2cp_sTx.c1.valid <= 1'b0;
			bit_result[511:128] <= 0;
		end
		else
		begin
			af2cp_sTx.c1.valid <= (((state == STATE_PROCESSING) && (cl_processed == 8'b11111111)) && !cp2af_sRx.c1TxAlmFull);						
			af2cp_sTx.c1.data <= bit_result;
			af2cp_sTx.c1.hdr <= write_hdr;
			
			write_issued <= !(((state == STATE_PROCESSING) && (cl_processed == 8'b11111111)) && !cp2af_sRx.c1TxAlmFull);
				
			/*if(((state == STATE_PROCESSING) && cl_processed) && !cp2af_sRx.c1TxAlmFull)
			begin
				$display("==>");
				$display("==> WRITE REQUEST (cls: %d) ==>", total_cls_processed);
				$display("==>\n");				
			end*/
		end
	end
		
	always_ff @(posedge clk)
	begin
		if(reset)
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