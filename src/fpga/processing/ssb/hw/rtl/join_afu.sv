`include "helper.vh"

module join_afu
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
		
		output logic partition_processed
	);
	
	/*** 
	 *
	 *	READ IN QUERY PARAMETERS FROM CSRs 
	 *	 	
	 ***/

	logic reading_bitmap;	
	logic bitmap_ready;
	always_ff @(posedge clk)
	begin
		if(is_active)
		begin
			if (csrs.cpu_wr_csrs[6].en)
			begin
				reading_bitmap <= csrs.cpu_wr_csrs[6].data;
				bitmap_ready <= !csrs.cpu_wr_csrs[6].data;
				$display("[SW Signal] -- Bitmap status: %0b", reading_bitmap);
			end
		end
	end	
		
	/***
	 * CL ADDRESS (CSRS[4])  
	 ***/	
	logic new_partition_ready = 0;
	t_ccip_clAddr cl_address;
	always_ff @(posedge clk)
	begin
		if(is_active)
		begin
			new_partition_ready <= csrs.cpu_wr_csrs[4].en;
			if (csrs.cpu_wr_csrs[4].en)
			begin			
				cl_address <= byteAddrToClAddr(csrs.cpu_wr_csrs[4].data);		
			end
		end
	end
	
	/*** 
	 *	RESULT BUFFER ADDRESS (CSRS[5])  
	 ***/	
	t_ccip_clAddr result_address;
	logic wr_init = 0;
	always_ff @(posedge clk)
	begin
		if(is_active)
		begin
			if (csrs.cpu_wr_csrs[5].en)
			begin
				result_address <= byteAddrToClAddr(csrs.cpu_wr_csrs[5].data);
				//$display("Result address: %0h", byteAddrToClAddr(csrs.cpu_wr_csrs[5].data));
				wr_init <= 1'b1;
			end
			else
			begin
				wr_init <= 1'b0;
			end
		end
	end
							
	/*** 
	 *	TOTAL CACHE-LINES TO PROCESS FOR THIS PARTITION (CSRS[0]) 
	 ***/
	logic[6:0] cls_to_process; // total cache lines to read	
	always_ff @(posedge clk)
	begin
		if(is_active)
		begin
			if (csrs.cpu_wr_csrs[0].en)
			begin
				cls_to_process <= csrs.cpu_wr_csrs[0].data;		
				$display("[SW Signal] -- Total CLs for the incoming partition: %0d", csrs.cpu_wr_csrs[0].data);
			end
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
	
	//logic partition_processed = 0; // if (cls_processed == cls_to_process) 
	logic cl_req_allowed = 1; // else if (cls_processed < cls_to_process)
	
	logic cl_req_issued = 0; // if (sTx.c0.valid)
	logic cl_received = 0; // if (sRx.c0.valid)
	logic cl_processed = 0; // set by the processing modules
	int cls_processed = 0;
	
	always_ff @(posedge clk)
	begin
		if(state == STATE_WAITING)
		begin
			if (csrs.cpu_wr_csrs[6].en && csrs.cpu_wr_csrs[6].data == 0)
			begin
				$display("[STATUS] FK processing about to start, current state of the parameters:");
				$display("\npartition_processed: %0b", partition_processed);
				$display("cl_req_allowed: %0b\n", cl_req_allowed);
				$display("cl_req_issued: %0b", cl_req_issued);
				$display("cl_received: %0b", cl_received);
				$display("cl_processed: %0b", cl_processed);
				$display("cls_processed: %0d\n", cls_processed);
			end
		end
	end
	
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
						$display("WAITING -> IDLE (cls: %0d)...\n", cls_processed);
						state <= STATE_IDLE;					
						
						partition_processed <= 1'b0;
						cl_req_allowed <= 1'b1;

						cls_processed <= 0;
					end					
				end
				STATE_IDLE:
				begin
					if (partition_processed)
					begin
						$display("IDLE -> WAITING  (cls: %0d)...\n", cls_processed);
						state <= STATE_WAITING;						
					end
					else if (cl_req_allowed)
					begin
					//	$display("IDLE -> REQ  (cls: %0d)...\n", cls_processed);
						state <= STATE_REQ;
						
						cl_req_allowed <= 1'b0;
					end
				end
				STATE_REQ:
				begin
					if(cl_req_issued)
					begin						
					//	$display("REQ -> RSP  (cls: %0d)...\n", cls_processed);
						state <= STATE_RSP;
					end
				end
				STATE_RSP:
				begin
					if(cl_received)
					begin
					//	$display("RSP -> PROCESSING  (cls: %0d)...\n", cls_processed);
						state <= STATE_PROCESSING;
						
						//cl_received <= 1'b0;
					end
				end
				STATE_PROCESSING:
				begin
					if(cl_processed)
					begin
						//$display("PROCESSING -> IDLE  (CL%0d)...\n", cls_processed);
						state <= STATE_IDLE;
						
						cl_req_allowed <= ((cls_processed + 1) < cls_to_process);
						partition_processed <= ((cls_processed + 1) == cls_to_process);
						
						cls_processed <= cls_processed + 1;
						cl_processed <= 1'b0;
					end
					else
					begin
						cl_processed <= 1'b1;
						//cls_processed <= cls_processed + 1;
						//$display("PROCESSING (CL%0d)...\n", cls_processed);
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
	
	/***
		SENDING READ REQUEST OVER sTx [c0] 
	***/
		
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
			end
			else if(state == STATE_RSP)
			begin
				cl_req_issued <= 1'b0;
			end			
		end
	end

	/***
		RECEIVING READ RESPONSE FROM sRx [c0] 
	 ***/
	
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
		end
		else if(state == STATE_PROCESSING)
		begin
			cl_received <= 1'b0;
		end
	end

	//
	// READ RESPONSE PROCESSING
	//
	t_ccip_c1_ReqMemHdr write_hdr;
	logic [511:0] bit_result;
	
	always_ff @(posedge clk)
	begin
		if (reset)
		begin
			af2cp_sTx.c1.valid <= 1'b0;
		end
		else if(bitmap_ready && cl_processed && state == STATE_PROCESSING)
		begin		
			af2cp_sTx.c1.hdr <= write_hdr;
			af2cp_sTx.c1.data <= bit_result;
			
			af2cp_sTx.c1.valid <= !cp2af_sRx.c1TxAlmFull;
			
			//$display("[WRITE REQ] CL #%0d (%0b)", cls_processed, bit_result);
			//$display("			address (%0h)", write_hdr.address);
		end
		else
		begin
			af2cp_sTx.c1.valid <= 1'b0;
		end
	end
		
	lineorder_date lo_date_join
	(
		.clk,
		.reset,
		
		.reading_bitmap((state == STATE_PROCESSING) &&
			!cl_processed && reading_bitmap),
		
		.bitmap_ready((state == STATE_PROCESSING) && 
			!cl_processed && bitmap_ready),
				
		.cls_processed,
		
		.incoming_cl(rsp_data),
		.bit_result(bit_result)	
	);
		
	/*
	 *  READ REQUEST HEADER SETUP  
	 */
	always_comb
	begin
		read_req_hdr = t_ccip_c0_ReqMemHdr'(0);
		
		read_req_hdr.vc_sel = eVC_VA;
		read_req_hdr.req_type = eREQ_RDLINE_I;
		
		read_req_hdr.cl_len = eCL_LEN_1;
		read_req_hdr.address = cl_address + cls_processed;
	end
			
	/*
	 *  WRITE REQUEST HEADER SETUP  
	 */
	always_comb
	begin
		write_hdr = t_cci_c1_ReqMemHdr'(0);
	
		write_hdr.vc_sel = eVC_VA;
		write_hdr.sop = 1'b1;
		write_hdr.cl_len = eCL_LEN_1;
		write_hdr.req_type = eREQ_WRLINE_I; //no intent to cache
			
		write_hdr.mdata = cls_processed;
		write_hdr.address = result_address + cls_processed;
		
		//$display("[WRITE_HDR][UPDATE] (CL%0d) (addr: %0h)", cls_processed, write_hdr.address);
	end
	
	// CSRS writes to notify the SW about processing	
	//always_comb
	//begin
		//csrs.afu_id = `AFU_ACCEL_UUID;	
		/*for (int i = 4; i < 8; i = i + 1)
		begin
			csrs.cpu_rd_csrs[i].data = 64'(0);
		end*/
		
		//csrs.cpu_rd_csrs[4].data = bitmap_ready;
	//	csrs.cpu_rd_csrs[5].data = partition_processed;
	//end
	
	//assign af2cp_sTx.c1.valid = 1'b0;
	assign af2cp_sTx.c2.mmioRdValid = 1'b0;

endmodule