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
	
	
	//
	// Convert between byte addresses and line addresses.  The conversion
	// is simple: adding or removing low zero bits.
	//

	localparam CL_BYTE_IDX_BITS = 6;
	typedef logic [$bits(t_cci_clAddr) + CL_BYTE_IDX_BITS - 1 : 0] t_byteAddr;

	function automatic t_cci_clAddr byteAddrToClAddr(t_byteAddr addr);
		return addr[CL_BYTE_IDX_BITS +: $bits(t_cci_clAddr)];
	endfunction

	function automatic t_byteAddr clAddrToByteAddr(t_cci_clAddr addr);
		return {addr, CL_BYTE_IDX_BITS'(0)};
	endfunction

	// State transition parameters
	logic read_issued = 1'b0;
	logic all_reads_done = 1'b0;
	logic writes_processed = 1'b1;

	// Last cache line id this AFU processed
	logic[6:0] last_cl = 0; //  0 to 63
	logic[2:0] last_res = 0; // 0 to 7
	
	// Output param
	t_ccip_clData write_block;

	// AFU uses CSR[0] to notify the SW that the reads are done using the last_cl parameter	
	always_comb
	begin
		csrs.afu_id = `AFU_ACCEL_UUID;		
		for (int i = 0; i < NUM_APP_CSRS; i = i + 1)
		begin
			csrs.cpu_rd_csrs[i].data = 64'(0);
		end
	
		csrs.cpu_rd_csrs[0].data = last_cl; //last cache line processed
		csrs.cpu_rd_csrs[1].data = last_res; //last bit vector result generated
		
		csrs.cpu_rd_csrs[2].data = (writes_processed & all_reads_done);
	end

	logic rd_block_ready; //state transition param

	t_ccip_clAddr rd_block_addr;
	t_ccip_clAddr wr_block_addr; 

	logic[6:0] total_cl; //total cache lines to read -- SW writes it to the 3rd CSR
	logic[31:0] filter_pred; // predicate for the scan operation -- SW writes it to the 4th CSR
	
	/*** 
	 * AFU receives the following MMIO writes and reads them for the processing
	 *	- CSR[1]: start address for the incoming column partition
	 *	- CSR[2]: number of cache lines to read from the corresponding partition
	 *	- CSR[3]: filter comparison value	 	
	 ***/
	
	always_ff @(posedge clk)
	begin
		if (csrs.cpu_wr_csrs[0].en)
		begin
			wr_block_addr <= byteAddrToClAddr(csrs.cpu_wr_csrs[0].data);	
			$display("Write block address received: %0h (%0h)!",  
					byteAddrToClAddr(csrs.cpu_wr_csrs[0].data), 
					csrs.cpu_wr_csrs[0].data);
		end
	end

	logic rd_needed = 1'b0;
	logic rd_issued = 1'b0;
		
	logic start_processed = 1'b0;
	logic rds_done = 1'b0;
	
	always_ff @(posedge clk) 
	begin
		if (csrs.cpu_wr_csrs[1].en)
		begin
			rd_block_ready <= csrs.cpu_wr_csrs[1].en;
			rd_block_addr <= byteAddrToClAddr(csrs.cpu_wr_csrs[1].data);
			$display("Read block address received: %0h (%0h)!",  
					byteAddrToClAddr(csrs.cpu_wr_csrs[1].data), 
					csrs.cpu_wr_csrs[1].data);
			
			//reset all the params
			read_issued = 0;
			all_reads_done = 0;
			
			rd_needed = 0;
			rd_issued = 0;
		
			start_processed = 0;
			rds_done = 0;
			
			writes_processed = 1;

			last_cl = 0;
			last_res = 0;
		end
	end
	
	always_ff @(posedge clk)
	begin
		if (csrs.cpu_wr_csrs[2].en)
		begin
			total_cl <= csrs.cpu_wr_csrs[2].data;
			$display("AFU will read %0d cache lines in total!\n", csrs.cpu_wr_csrs[2].data);		
		end
	end

	always_ff @(posedge clk)
	begin
		if (csrs.cpu_wr_csrs[3].en)
		begin
			filter_pred <= csrs.cpu_wr_csrs[3].data;
			$display("AFU received the filter predicate: %0d\n", csrs.cpu_wr_csrs[3].data);		
		end
	end
	
	// =========================================================================
	//
	//   State machine
	//
	// =========================================================================

	typedef enum logic [1:0]
		{
		STATE_IDLE,
		STATE_READ,
		STATE_WRITE
	}
	t_state;

	t_state state;
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
					if (rd_block_ready)
					begin
						$display("\nAFU starting to read the block!\n");
						state <= STATE_READ;
					end			
				end
				STATE_READ:
				begin
					if(all_reads_done)
					begin
						$display("\nAFU processed all the read blocks!\n");
						state <= STATE_WRITE;
						rd_block_ready <= 1'b0; // to avoid coming back to the READ state from the IDLE state
					end
				end	
				STATE_WRITE:
				begin
					if (writes_processed)
					begin
						$display("\nAFU processed the write blocks!\n");
						state <= STATE_IDLE;
					end
				end
			endcase
		end
	end

	// Reading from main-memory (Channel 0)
	// 1) Issue read request (Port Rx)
	//    -- Create the request header, hdr (t_ccip_c0_ReqMemHdr)
	//		 -> vc_sel (t_ccip_vc)
	//		 -> cl_len
	//		 -> req_type (t_ccip_c1_req)
	//		 -> address (t_ccip_clAddr) 
	//		 -> mdata (t_ccip_mdata)
	//    -- set the request valid flag

	t_ccip_clAddr rd_addr;
	
	// Initial setup for the READ functionality
	// start address for the partition block
	always_ff @(posedge clk)
	begin
		if(reset)
		begin
			rd_needed <= 1'b0;			
		end
		else
		begin
			if(rd_block_ready && !start_processed)
			begin
				rd_needed <= rd_block_ready;
				//rd_addr <= t_ccip_clAddr'(rd_block_addr);
				//$display("Start address for the partition %h", t_ccip_clAddr'(rd_block_addr));
				
				start_processed <= 1'b1;
			end
		end
	end
	
	// READ HEADER SETUP
	// For each cache line the AFU advances the memory pointer (rd_block_addr) by 64 bytes (512 bits)
	
	t_ccip_c0_ReqMemHdr read_req_hdr;
	always_comb
	begin
		read_req_hdr.vc_sel = eVC_VA;
		read_req_hdr.cl_len = eCL_LEN_1;
		read_req_hdr.req_type = eREQ_RDLINE_I;
		read_req_hdr.mdata = t_ccip_mdata'(0);
	
		read_req_hdr.address = rd_block_addr;
		
		/*if(rd_block_ready && rd_needed)
		begin
			$display(" READ HEADER: CL %d -- read address: %h", last_cl, read_req_hdr.address);			
		end*/
	end

	//Issue a READ_REQUEST for the next cache-line address
	always_ff @(posedge clk)
	begin
		if(reset)
		begin
			af2cp_sTx.c0.valid <= 1'b0;
		end
		else
		begin
			//clearValids
			af2cp_sTx.c0.valid <= 1'b0;
				
			af2cp_sTx.c0.hdr <= read_req_hdr;
			af2cp_sTx.c0.hdr.mdata <= last_cl;
			af2cp_sTx.c0.valid <= rd_needed && !cp2af_sRx.c0TxAlmFull;
			
			if(rd_needed && !rds_done && !cp2af_sRx.c0TxAlmFull)
			begin
				//$display("  READ REQUEST: CL %d -- read address: %h", last_cl, read_req_hdr.address);	
	
				rd_needed <= 1'b0; //switch off read requests until we receieve a response for the current one
				last_cl++;
				if(last_cl == total_cl)
				begin
					rds_done <= 1'b1;
				end
			end
		end
	end
	
	logic [511:0] bit_result = 0'b0;  // maximum # of bits that this AFU can create a WRITE REQUEST 
	logic [63:0] cur_word; // process the current cache-line in 64-bit blocks
	logic [7:0] cur_val; // 8-bit compressed column partition value
	
	logic [8:0] c_id = 9'b0; //0 to 511
	
	logic new_write_issued = 1'b0; 
		
	t_ccip_clData rsp_data;
	//Check if a READ_RESPONSE ready
	always_ff @(posedge clk)
	begin
		if(cp2af_sRx.c0.rspValid && !all_reads_done)
		begin
			rsp_data <= cp2af_sRx.c0.data;		
			//$display("    ================");
			//$display("    READ RESPONSE RECEIVED FOR CL %0d", cp2af_sRx.c0.hdr.mdata);
			//$display("      cl-level address:   %0h!", rd_block_addr);
			//$display("      byte-level address: %0h!", clAddrToByteAddr(rd_block_addr));
			
			//$display("Predicate: %0d (%0b)", filter_pred, filter_pred);
			//$display("		values in cache-line %0d!", last_cl);
			
			//i -> use to get the proper range for each word [0-63], [64-127], ...
			//j -> 8 words (64-bits) in every cache-line (512-bits)
			//k -> 8 8-bit values in each 64-bit word
			
			for(int i = 0, j = 0; j < 8; j++) 
			begin
				i = j * 64;
				//c_id = j * 8 + (last_cl - 1) * 64; // index of the column value in the corresponding partition
				
				cur_word = cp2af_sRx.c0.data[ i +: 63];				
				for(int k = 7; k >= 0; k--) //reverse processing for endianness
				begin
					cur_val = cur_word[k * 8 +: 7]; //-> [7:0], [15:8], ..., [63:56]
					
					bit_result[c_id++] = (cur_val == filter_pred);											
				end
			end
			
			//$display("  ++++++++    ");
			//issue a write for every 8 cache-lines (512-values) read
			//c_id rolls over to 0 after every 512-values read
			if(c_id == 0)
			begin
			//	$display("  Filter result: %0d %0b", last_res++, bit_result);
				//issue a write to send the filter result back to the SW
				write_block <= bit_result;
				new_write_issued <= 1'b1;
			end
			//$display("  ++++++++    ");
			
			//$display("    ================");
			++rd_block_addr;			
			//$display("Read block address for next CL: %h!", rd_block_addr);			
		
			if(last_cl < total_cl)
			begin
				rd_needed <= 1'b1;
			end
			
			/*if(last_cl == total_cl)
			begin
				all_reads_done <= 1'b1; // all cache-lines are processed in the incoming partition
			
				//write_block <= bit_result;
				//write_issued <= 1'b1;
			
				$display("\nAll reads are done!");
			end
			else
			begin
				rd_needed <= 1'b1; //switch back the flag to let the AFU to issue the next READ REQUEST
			end
			*/
		end
	end
	
	// ==========================================================================
	//  WRITE LOGIC -- after reaching WRITE_STATE  
	//	Step 1:	Prepare a WRITE REQUEST by defining the c1_ReqMemHdr
	//	Step 2: Send the WRITE REQUEST
	//	Step 3: Receive the RESPONSE for WRITE REQUEST
	// ==========================================================================

	// Writing into main-memory (Channel 1) -- structs from cci-if/ccip_if_pkg.sv
	// ==========================================================================
	// 1) Issue write request (Port Tx) -- t_if_ccip_c1_Tx
	//    -- Create the request header, hdr (t_ccip_c1_ReqMemHdr)
	//		 -> vc_sel (t_ccip_vc)
	//		 -> sop
	//		 -> cl_len
	//		 -> req_type (t_ccip_c1_req)
	//		 -> address (t_ccip_clAddr)
	//		 -> mdata (t_ccip_mdata)
	//    -- data to write into (t_ccip_clData)
	//    -- set the request valid flag
	// ==========================================================================

t_ccip_c1_ReqMemHdr write_hdr;
always_comb
begin
	//Initialize header
	write_hdr = t_cci_c1_ReqMemHdr'(0);
	
	write_hdr.vc_sel = eVC_VA;
	write_hdr.sop = 1'b1;
	write_hdr.cl_len = eCL_LEN_1;
	write_hdr.req_type = eREQ_WRLINE_I; //no intent to cache
	//write_hdr.req_type = eREQ_WRPUSH_I; //no intent to cache
	write_hdr.address = wr_block_addr;
	
	//$display("Write header created with address %h", write_hdr.address);
end

assign af2cp_sTx.c1.hdr = write_hdr;
assign af2cp_sTx.c1.data = write_block;

always_ff @(posedge clk)
begin
	if(reset)
	begin
		af2cp_sTx.c1.valid <= 1'b0;
	end
	else
	begin
		// Request the write as long as the channel isn't full.
		//af2cp_sTx.c1.valid <= ((state == STATE_WRITE) && !cp2af_sRx.c1TxAlmFull);		
		af2cp_sTx.c1.valid <= (new_write_issued && !cp2af_sRx.c1TxAlmFull);
		
		if(af2cp_sTx.c1.valid && new_write_issued)
		begin			
			$display("    Issued a new write (%0b) for address %0d", new_write_issued, wr_block_addr++);
			writes_processed <= 1'b0;
			new_write_issued <= 1'b0;
		end
	end
end

always_ff @(posedge clk)
begin
	if(cp2af_sRx.c1.rspValid && !writes_processed)
	begin
		writes_processed <= 1'b1;
		$display("--> Last write processed!");
		
		if(last_cl == total_cl)
		begin
			all_reads_done <= 1'b1; // all cache-lines are processed in the incoming partition			
			$display("\nAll reads are done for this partition!");
		end
		
	end
end

//assign af2cp_sTx.c1.valid = 1'b0;
assign af2cp_sTx.c2.mmioRdValid = 1'b0;

endmodule // app_afu_cci