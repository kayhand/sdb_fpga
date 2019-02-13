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
		fiu.c1Tx = cci_mpf_cvtC1TxFromBase(af2mpf_sTx.c1);
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

	// State transition parameters
	logic read_issued = 1'b0;
	logic read_processed = 1'b0;
	logic write_issued = 1'b0;

	// Output param
	logic[63:0] write_block;

	// Values that the AFU will write into some CSRs
	// ====================================================================
	//
	//  CSRs (simple connections to the external CSR management engine)
	//
	// ====================================================================
	always_comb
	begin
		csrs.afu_id = `AFU_ACCEL_UUID;		
		for (int i = 0; i < NUM_APP_CSRS; i = i + 1)
		begin
			csrs.cpu_rd_csrs[i].data = 64'(0);
		end
	
		csrs.cpu_rd_csrs[0].data = write_issued;
		csrs.cpu_rd_csrs[1].data = write_block;		
	end

	// AFU receives two MMIO writes
	// CSR[0] -> keeps the address of the write buffer
	// CSR[1] -> keeps the address of the read buffer

	logic rd_block_ready; //state transition param

	t_ccip_clAddr rd_block_addr; //42 bits
	t_ccip_clAddr wr_block_addr; //42 bits

	always_ff @(posedge clk)
	begin
		if (csrs.cpu_wr_csrs[0].en)
		begin
			wr_block_addr <= t_ccip_clAddr'(csrs.cpu_wr_csrs[0].data);	
			$display("Write block address received: %h!", wr_block_addr);
		end
	end

	always_ff @(posedge clk)
	begin
		if (csrs.cpu_wr_csrs[1].en)
		begin
			rd_block_ready <= csrs.cpu_wr_csrs[1].en;
			rd_block_addr <= t_ccip_clAddr'(csrs.cpu_wr_csrs[1].data);
			$display("Read block address received: %h!", rd_block_addr);
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
						$display("AFU starting to read the block!");
						state <= STATE_READ;
					end
				end
				STATE_READ:
				begin
					if(read_processed)
					begin
						$display("AFU processed the read block!");
						state <= STATE_WRITE;	
					end
				end
				STATE_WRITE:
				begin
					if (write_issued)
					begin
						$display("AFU processed the write block!");
						state <= STATE_IDLE;
						rd_block_ready <= 1'b0;
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
	logic rd_needed = 1'b0;
	logic rd_issued = 1'b0;
	
	always_ff @(posedge clk)
	begin
		if(reset)
		begin
			rd_needed <= 1'b0;
		end
		else
		begin
			if(rd_block_ready && !rd_issued)
			begin
				rd_needed <= rd_block_ready;
				rd_addr <= t_ccip_clAddr'(rd_block_addr);
				$display("Data ready in address %h", rd_addr);				
			end
		end
	end
	
	t_ccip_c0_ReqMemHdr read_req_hdr;
	always_comb
	begin
		read_req_hdr.vc_sel = eVC_VA;
		read_req_hdr.cl_len = eCL_LEN_1;
		read_req_hdr.req_type = eREQ_RDLINE_I;
		read_req_hdr.mdata = t_ccip_mdata'(0);
	
		read_req_hdr.address = rd_addr;
		
		if(rd_needed)
		begin
			$display("Read header created with address %h", read_req_hdr.address);
		end
	end
	

	//Issue a READ_REQUEST
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
			af2cp_sTx.c0.valid <= rd_needed && !cp2af_sRx.c0TxAlmFull;
			
			if(rd_needed && !rd_issued && !cp2af_sRx.c0TxAlmFull)
			begin
				$display("Issuing a read request for %h", read_req_hdr.address);
			
				rd_issued <= 1'b1;
				rd_needed <= 1'b0;
			end
		end
	end

	logic rd_returned;
	t_ccip_clData rsp_data;
	//Check if a READ_RESPONSE ready
	always_ff @(posedge clk)
	if(cp2af_sRx.c0.rspValid && !read_processed)
	begin
		$display("Read response received!");
		rsp_data <= cp2af_sRx.c0.data;
		
		$display("    Received entry v%0d: %0d",
				fiu.c0Rx.hdr.cl_num, cp2af_sRx.c0.data[63:0]);			
		$display("Second entry is: %d", rsp_data[127:64]);		
		$display("Second entry is: %d", cp2af_sRx.c0.data[127:64]);
		
		write_block <= cp2af_sRx.c0.data[63:0];
		read_processed <= 1'b1;
		write_issued <= 1'b1;
	end
	
/*
	always_ff @(posedge clk)
	begin
		if(read_processed)
		begin
			write_block <= rsp_data[127:64];
			write_issued <= 1'b1;			
		end
	end
*/
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

	/*
t_ccip_c1_ReqMemHdr write_hdr;

always_comb
begin
	//Initialize header
	write_hdr = t_cci_c1_ReqMemHdr'(0);
	
	write_hdr.vc_sel = eVC_VA;
	write_hdr.sop = 1'b1;
	write_hdr.cl_len = eCL_LEN_1;
	write_hdr.req_type = eREQ_WRLINE_I;
	write_hdr.address = wr_block_addr;
	
	$display("Write header created/updated!");
end

//assign fiu.c1Tx.data = t_ccip_clData'({ block_part_4, 64'h1 });
assign af2cp_sTx.c1.data = t_ccip_clData'('h0021646c726f77206f6c6c6548);

always_ff @(posedge clk)
begin
	if(reset)
	begin
		af2cp_sTx.c1.valid <= 1'b0;
	end
	else
	begin
		// Request the write as long as the channel isn't full.
		af2cp_sTx.c1.valid <= ((state == STATE_WRITE) &&
				! cp2af_sRx.c1TxAlmFull);
		if(af2cp_sTx.c1.valid)
		begin
			$display("write issued!");
		end
	end
	af2cp_sTx.c1.hdr <= write_hdr;
end
	 */

	assign af2cp_sTx.c2.mmioRdValid = 1'b0;

endmodule // app_afu_cci