`include "cci_mpf_if.vh"
`include "csr_mgr.vh"
`include "afu_json_info.vh"

// Getting the address of the block from CSR -- cci-if/cci_csr_if_pkg.sv
// 1) Check if there was a CSR write over Channel 0 Port Rx, t_if_cci_c0_Rx rx_c0
// 	  -- cci_csr_isWrite(rx_C0), 
// 2) Get the physical address of the data block, t_cci_mmioAddr
//	  -- cci_csr_getAddress (rx_C0)

//fiu.c0Tx
//fiu.c1Tx
//fiu.c2Tx

// Reading from main-memory (Channel 0) -- structs from cci-if/ccip_if_pkg.sv
// ============================================================
// 1) Issue read request (Port Tx) -- t_if_ccip_c0_Tx
//    -- Create the request header, hdr (t_ccip_c0_ReqMemHdr)
//    -- Set the request flag, valid
// =============================================================
// 2) Process read response (Port Rx) -- t_if_ccip_c0_Rx
//    -- Process the response header, hdr (t_ccip_c0_RspMemHdr)
//    -- Requested data is in data, (t_ccip_clData)
//	  -- rspValid is set

// Can also use helper functions from /cci-if/ccip_if_funcs_pkg.sv

// Writing into main-memory (Channel 1) -- structs from cci-if/ccip_if_pkg.sv
// ============================================================
// 1) Issue write request (Port Tx) -- t_if_ccip_c1_Tx
//    -- Create the request header, hdr (t_ccip_c1_ReqMemHdr)
//    -- data to write into (t_ccip_clData)
//    -- Set the request flag, valid
// =============================================================

module app_afu
		(
		input  logic clk,

		// Connection toward the host.  Reset comes in here.
		cci_mpf_if.to_fiu fiu,

		// CSR connections
		app_csrs.app csrs,

		// MPF tracks outstanding requests.  These will be true as long as
		// reads or unacknowledged writes are still in flight.
		input  logic c0NotEmpty,
		input  logic c1NotEmpty
		);

	// Local reset to reduce fan-out
	logic reset = 1'b1;
	always @(posedge clk)
	begin
		reset <= fiu.reset;
	end

	//
	// Convert MPF interfaces back to the standard CCI structures.
	//
	t_if_ccip_Rx mpf2af_sRx;
	t_if_ccip_Tx af2mpf_sTx;
	
	//
	// The base module has already registered the Rx wires heading
	// toward the AFU, so wires are acceptable.
	//
	always_comb
	begin
		//
		// Response wires
		//

		mpf2af_sRx.c0 = fiu.c0Rx;
		mpf2af_sRx.c1 = fiu.c1Rx;

		mpf2af_sRx.c0TxAlmFull = fiu.c0TxAlmFull;
		mpf2af_sRx.c1TxAlmFull = fiu.c1TxAlmFull;

		//
		// Request wires
		//
		fiu.c0Tx = cci_mpf_cvtC0TxFromBase(af2mpf_sTx.c0);		
		
		if (cci_mpf_c0TxIsReadReq(fiu.c0Tx))
		begin
			// Treat all addresses as virtual.  If MPF's VTP isn't
			// enabled this field is ignored and addresses will remain
			// physical.
			fiu.c0Tx.hdr.ext.addrIsVirtual = 1'b1;

			// Enable eVC_VA to physical channel mapping.  This will only
			// be triggered when MPF's ENABLE_VC_MAP is set.
			fiu.c0Tx.hdr.ext.mapVAtoPhysChannel = 1'b1;

			// Enforce load/store and store/store ordering within lines.
			// This will only be triggered when ENFORCE_WR_ORDER is set.
			fiu.c0Tx.hdr.ext.checkLoadStoreOrder = 1'b1;
		end

		fiu.c1Tx = cci_mpf_cvtC1TxFromBase(af2mpf_sTx.c1);
		if (cci_mpf_c1TxIsWriteReq(fiu.c1Tx))
		begin
			// See comments on the c0Tx fields above
			fiu.c1Tx.hdr.ext.addrIsVirtual = 1'b1;
			fiu.c1Tx.hdr.ext.mapVAtoPhysChannel = 1'b1;
			fiu.c1Tx.hdr.ext.checkLoadStoreOrder = 1'b1;

			// Don't ever request an MPF partial write
			fiu.c1Tx.hdr.pwrite = t_cci_mpf_c1_PartialWriteHdr'(0);
		end

		fiu.c2Tx = af2mpf_sTx.c2;	
	end
	
	// Connect to the AFU
	app_afu_cci
		app_cci
		(
			.clk,
			.reset,
			.cp2af_sRx(mpf2af_sRx),
			.af2cp_sTx(af2mpf_sTx),
			.csrs,
			.c0NotEmpty,
			.c1NotEmpty
		);

endmodule //app_afu

localparam CL_BYTE_IDX_BITS = 6;
typedef logic [$bits(t_cci_clAddr) + CL_BYTE_IDX_BITS - 1 : 0] t_byteAddr;

function automatic t_cci_clAddr byteAddrToClAddr(t_byteAddr addr);
	return addr[CL_BYTE_IDX_BITS +: $bits(t_cci_clAddr)];
endfunction

function automatic t_byteAddr clAddrToByteAddr(t_cci_clAddr addr);
	return {addr, CL_BYTE_IDX_BITS'(0)};
endfunction

localparam CL_REQ_SIZE = 1;

module app_afu_cci
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

	typedef enum logic [1:0]
	{
		STATE_IDLE,
		STATE_READ,
		STATE_WRITE,
		STATE_DONE
	}
	t_state;
	t_state state;

	// State transition parameters
	logic new_block_received;
	logic reads_done;
	logic write_block_ready;
	//logic writes_done;
	
	logic query_completed = 0;

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
					if (new_block_received)
					begin
						state <= STATE_READ;
						
						$display("\n 	+++++++++++");
						$display(" 	NEW PARTITION BLOCK!");				
						$display(" 	+++++++++++\n");
					end
					else if (!reads_done)
					begin
						state <= STATE_READ;
					end					
					else if (query_completed)
					//else if (writes_done)
					begin
						state <= STATE_DONE;	
					end
				end

				STATE_READ:
				begin
					if (write_block_ready)
					begin
						state <= STATE_WRITE;
					end
					else if(reads_done)
					begin
						state <= STATE_IDLE;
					end
				end

				STATE_WRITE:
				begin
					if (!cp2af_sRx.c1TxAlmFull)
					begin
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

			STATE_READ:
			begin
				$display("\n 	+++++++++++");
				$display(" 	READ STATE!");
				$display(" 	+++++++++++\n");
			end

			STATE_WRITE:
			begin
				$display("\n  +++++++++++");
				$display("  WRITE STATE!");
				$display("  +++++++++++\n");
			end
			
			STATE_DONE:
			begin
				$display("\n 	+++++++++++");				
				$display(" 	PROCESSING DONE! (last_res: %0d) (writes_done? %0d)", last_res, writes_done);
				$display("  +++++++++++\n");
			end
		endcase
	end
	*/
	
	/*** 
	 *
	 *	READ IN QUERY PARAMETERS FROM CSRs 
	 *	 	
	 ***/
			
	logic[6:0] total_cl; // total cache lines to read -- SW writes it to the first CSR
	logic[6:0] total_cl_blocks; // total READ REQUESTS required
	
	logic[7:0] filter_pred; // predicate for the scan operation -- SW writes it to the second CSR
	logic [1:0] func_type; //0: filter, 1: filter_unrolled, 2: filter_pipelined
		
	always_ff @(posedge clk)
	begin
		if (csrs.cpu_wr_csrs[0].en)
		begin
			total_cl <= csrs.cpu_wr_csrs[0].data;
			total_cl_blocks <= csrs.cpu_wr_csrs[0].data / CL_REQ_SIZE;
			//$display("\nAFU will read %0d cache lines in total!", csrs.cpu_wr_csrs[0].data);		
		end
		if (csrs.cpu_wr_csrs[1].en)
		begin			
			filter_pred <= csrs.cpu_wr_csrs[1].data;
			//$display("AFU received the filter predicate: %0d\n", csrs.cpu_wr_csrs[1].data);		
		end
		//if (csrs.cpu_wr_csrs[7].en)
		//begin
			//func_type <= csrs.cpu_wr_csrs[7].data;
			//$display("Operation Id: %0d\n", csrs.cpu_wr_csrs[7].data);
		//end
	end
	
	/*** 
	 *
	 *	READ IN BUFFER ADDRESSES 
	 *	 	
	 ***/
	
	t_ccip_clAddr read_buff_address;
	t_ccip_clAddr write_buff_address;
	
	always_ff @(posedge clk)
	begin
		new_block_received <= csrs.cpu_wr_csrs[2].en;
		if (csrs.cpu_wr_csrs[2].en)
		begin			
			read_buff_address <= byteAddrToClAddr(csrs.cpu_wr_csrs[2].data);		
		end
	end
	
	/*
	always_ff @(posedge clk)
	begin
		if (csrs.cpu_wr_csrs[3].en)
		begin
			write_buff_address <= byteAddrToClAddr(csrs.cpu_wr_csrs[3].data);
			writes_done <= 1'b0;
			//$display("Write buffer address: %0h\n", 
					//byteAddrToClAddr(csrs.cpu_wr_csrs[3].data));
		end	
	end 
	*/
	
	always_ff @(posedge clk)
	begin
		if (csrs.cpu_wr_csrs[5].en)
		begin	
			query_completed <= 1'b1;
			$display("All partitions processed!\n");
		end	
	end
	
	/* * * * * * * * * * * * *
	**************************
	* * * MAIN AFU LOGIC * * * 
	**************************
	* * * * * * * * * * * * */
	
	// LAST READ REQUEST BLOCK
	logic[6:0] last_cl_block = 0;
	// LAST CL in a READ RESPONSE
	logic[6:0] last_cl = 0;
	logic [3:0] last_res = 0;
	
	always_ff @(posedge clk)
	begin
		if(new_block_received)
		begin
			last_cl_block <= 0;
			last_cl <= 0;
			last_res <= 0;
		end
	end
	
	//is last READ RESP received?	
	assign requests_done = (last_cl_block == total_cl_blocks);	
	
	// DECIDE IF READS WILL BE ALLOWED
		
	logic reads_allowed;
	always_ff @(posedge clk)
	begin
		if (reset)
		begin
			reads_allowed <= 1'b0;
		end
		else
		begin			
			if(reads_allowed)
			begin
				//clear reads for this cycle
				reads_allowed <= cp2af_sRx.c0TxAlmFull;
			end
			else
			begin
				//turn back on read request when there is a response
				reads_allowed <= new_block_received ||
					(!reads_done && !requests_done && cci_c0Rx_isReadRsp(cp2af_sRx.c0));	
			end
		end
	end
		 
	// READ HEADER SETUP
	t_cci_clAddr read_address;
	t_ccip_c0_ReqMemHdr read_req_hdr;
	always_comb
	begin
		read_req_hdr = t_ccip_c0_ReqMemHdr'(0);
		
		read_req_hdr.vc_sel = eVC_VA;
		read_req_hdr.req_type = eREQ_RDLINE_I;
		
		//eCL_LEN_1 -> 00 (0)
		//eCL_LEN_2 -> 01 (1)
		//eCL_LEN_4 -> 11 (3)
		read_req_hdr.cl_len = t_ccip_clLen'(CL_REQ_SIZE - 1); 
		
		read_req_hdr.mdata = last_cl_block;
		read_req_hdr.address = read_buff_address + (last_cl_block * CL_REQ_SIZE);		
	end
	
	logic[6:0] counter = 0;
	
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
			// Generate a read request when allowed and the FIU isn't full
			af2cp_sTx.c0.valid <= (!reads_done && reads_allowed && !cp2af_sRx.c0TxAlmFull);
			af2cp_sTx.c0.hdr <= read_req_hdr;

			if (!reads_done && reads_allowed && !cp2af_sRx.c0TxAlmFull)
			begin
				/*$display("==>");
				$display("==> REQ for CL block #%d (cycle %0d) ==>", last_cl_block, counter);
				$display("==>\n");*/
				
				counter <= counter + 1;
				last_cl_block <= last_cl_block + 1;
			end
		end
	end	
	
	t_ccip_c0_RspMemHdr read_rsp_hdr;
	t_ccip_clData rsp_data;
	
	logic [5:0] cl_block; // 0 - 63		
	logic [1:0] cl_num; // tracking for multi cache-line reads
		
	logic [2:0] write_block = 0;
	//
	// READ RESPONSE
	//
	logic rsp_received;	
	always_ff @(posedge clk)
	begin
		if (reset)
		begin
			rsp_received <= 1'b0;
		end
		else
		begin
			rsp_received <= cci_c0Rx_isReadRsp(cp2af_sRx.c0);
			rsp_data <= cp2af_sRx.c0.data;
	
			cl_block <= cp2af_sRx.c0.hdr.mdata;		
			cl_num <= cp2af_sRx.c0.hdr.cl_num;
		
			if (cci_c0Rx_isReadRsp(cp2af_sRx.c0))
			begin
				/*$display("\n");
				$display("<== Block %0d, CL num. %0d (cycle %0d)", 
						cp2af_sRx.c0.hdr.mdata, cp2af_sRx.c0.hdr.cl_num, counter);*/
						
			 	last_cl <= last_cl + 1;			 	
				counter <= counter + 1;
			end
		end
	end	
	
	assign reads_done = (last_cl == total_cl);
	
	logic [63:0] bit_result;
	logic [31:0] join_result;
	
	//
	// READ RESPONSE PROCESSING
	//
	filter_scan_p64 filter_scan
	(
		.clk,
		
		.reset(reset || new_block_received),
		.en(cci_c0Rx_isReadRsp(cp2af_sRx.c0)),
		
		.incoming_cl(cp2af_sRx.c0.data),	
		.predicate(filter_pred),
		
		.bit_result(bit_result) 
	);
		
	logic [512:0] write_cl;
	always_ff @(posedge clk)
	begin
		if (reset)
		begin
			write_cl <= 512'b0;
		end
		else
		begin
			if(rsp_received)
			begin
				
				//$display("Result vector: %0b", bit_result);
				/*write_cl[write_block * 64 +: 63] <= bit_result;				
				if(write_block == 7)
				begin
					$display("Write CL ready!");
					//write_block_ready <= 1'b1;
					write_cl <= 512'b0;
				end
				$display("Write CL (block %d): %0b", write_block, write_cl);				
				*/
				write_block <= write_block + 1;
			end
		end
	end
	
	/*t_ccip_c1_ReqMemHdr write_hdr;
	always_comb
	begin
		write_hdr = t_cci_c1_ReqMemHdr'(0);
	
		write_hdr.vc_sel = eVC_VA;
		write_hdr.sop = 1'b1;
		write_hdr.cl_len = eCL_LEN_1;
		write_hdr.req_type = eREQ_WRLINE_I; //no intent to cache
		write_hdr.address = write_buff_address + last_res;
	
	end*/

	// Control logic for memory writes
	always_ff @(posedge clk)
	begin
		//if (reset)
		//begin
		//	af2cp_sTx.c1.valid <= 1'b0;
		//end
		//else
		//begin
			// Request the write as long as the channel isn't full.
		//	af2cp_sTx.c1.data <= write_cl;
		//	af2cp_sTx.c1.valid <= ((state == STATE_WRITE) && !cp2af_sRx.c1TxAlmFull);
			
			//if((state == STATE_WRITE) && !cp2af_sRx.c1TxAlmFull)
			if(state == STATE_WRITE)
			begin				
				$display("  WRITE REQUEST (%d)!", last_res);
				//	$display(" |%0b| \n |%0b| \n |%0b| \n |%0b| \n |%0b| \n |%0b| \n |%0b| \n |%0b| \n", 
				//			write_cl[0 * 64 +: 63], write_cl[1 * 64 +: 63], write_cl[2 * 64 +: 63], write_cl[3 * 64 +: 63], 
				//			write_cl[4 * 64 +: 63], write_cl[5 * 64 +: 63], write_cl[6 * 64 +: 63], write_cl[7 * 64 +: 63]);
				
				//write_cl <= 0;				
				last_res <= last_res + 1;
				//write_block_ready <= 1'b0;
			end
		//end
		//af2cp_sTx.c1.hdr <= write_hdr;
	end
	
	/*
	always_ff @(posedge clk)
	begin
		if(reads_done && !writes_done)
		begin
			//$display("Reads done, waiting for last write to be completed!");
			//writes_done <= cp2af_sRx.c1.rspValid;
			writes_done <= 1'b1;
			//if(cp2af_sRx.c1.rspValid)
			//begin
				//$display("Final write also processed!");
			//end
		end
	end
	*/

	//assign writes_done = (last_res >= (total_cl / 8));
	
	// CSRS writes to notify the SW about processing	
	always_comb
	begin
		csrs.afu_id = `AFU_ACCEL_UUID;		
		for (int i = 0; i < NUM_APP_CSRS; i = i + 1)
		begin
			csrs.cpu_rd_csrs[i].data = 64'(0);
		end
	
		csrs.cpu_rd_csrs[0].data = last_cl; //last cache line processed
		csrs.cpu_rd_csrs[1].data = last_res; //last bit vector result generated
		
		//csrs.cpu_rd_csrs[2].data = reads_done && writes_done;
		csrs.cpu_rd_csrs[2].data = reads_done;
	end
	
	assign af2cp_sTx.c1.valid = 1'b0;
	assign af2cp_sTx.c2.mmioRdValid = 1'b0;

endmodule