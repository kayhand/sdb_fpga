`include "cci_mpf_if.vh"
`include "csr_mgr.vh"
`include "afu_json_info.vh"

//"accelerator-type-uuid": "332729aa-28af-11e9-bfc9-a4bf014f74bf"

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

	typedef enum logic [2:0]
	{
		STATE_IDLE,
		STATE_READ,
		STATE_DONE
	}
	t_state;
	t_state state;

	// State transition parameters
	logic new_block_received;
	logic reads_done;
	
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
					end
					else if (query_completed)
					begin
						state <= STATE_DONE;
					end
				end
				STATE_READ:
				begin
					if(reads_done)
					begin
						state <= STATE_IDLE;
					end
				end
			endcase
		end
	end	
		
	/*** 
	 *
	 *	READ IN QUERY PARAMETERS FROM CSRs 
	 *	 	
	 ***/
	
	/*** 
	 *	READ BUFFER ADDRESS (CSRS[2])  
	 ***/	
	t_ccip_clAddr read_buff_address;
	always_ff @(posedge clk)
	begin
		new_block_received <= csrs.cpu_wr_csrs[3].en;
		if (csrs.cpu_wr_csrs[3].en)
		begin			
			read_buff_address <= byteAddrToClAddr(csrs.cpu_wr_csrs[3].data);		
		end
	end

	/*** 
	 *	QUERY STATE (CSRS[5])  
	 ***/	
	
	always_ff @(posedge clk)
	begin
		if (csrs.cpu_wr_csrs[5].en)
		begin	
			query_completed <= csrs.cpu_wr_csrs[5].en;
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
			total_cls <= csrs.cpu_wr_csrs[0].data; // 4
			
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
			$display("Bit encoding: %0d", csrs.cpu_wr_csrs[2].data);
		end
	end
	
	logic[6:0] cl_offset = 0;
	logic[6:0] cls_processed = 0; // 0, 1, 2, ..., 63
	
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
		
		read_req_hdr.mdata = cl_offset;
		read_req_hdr.address = read_buff_address + (cl_offset * CL_REQ_SIZE);		
	end
		
	/* * * * * * * * * * * * *
	**************************
	* * * MAIN AFU LOGIC * * * 
	**************************
	* * * * * * * * * * * * */
	
	logic requests_done;
	
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
			
			//if (!reads_done && reads_allowed && !cp2af_sRx.c0TxAlmFull)
			//begin
			//	$display("==>");
			//	$display("==> REQ for CL block #%d ==>", cl_offset);
			//	$display("==>\n");
								
			//	cl_offset <= cl_offset + 1;
			//end
		end
	end

	assign requests_done = (cl_offset == total_cls);	
	
	t_ccip_c0_RspMemHdr read_rsp_hdr;
	t_ccip_clData rsp_data;
	
	logic [5:0] cl_block; // 0 - 63
	//logic [1:0] cl_num; // tracking for multi cache-line reads

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
			if (cci_c0Rx_isReadRsp(cp2af_sRx.c0))
			begin					
				//rsp_data <= cp2af_sRx.c0.data;
				
				cl_block <= cp2af_sRx.c0.hdr.mdata;		
				//cl_num <= cp2af_sRx.c0.hdr.cl_num;
				
				//$display("\n");
				//$display("<== RSP for CL block %0d (cls processed %0d)", cp2af_sRx.c0.hdr.mdata, (cls_processed + 1));
				//$display("\n");
							
				//cls_processed <= cls_processed + 1;
			end
		end
	end	

	assign reads_done = (cls_processed == total_cls); 

	always_ff @(posedge clk)
	begin
		if(new_block_received)
		begin
			cls_processed <= 0;
			cl_offset <= 0;			
		end
		else if (af2cp_sTx.c0.valid)
		begin
			cl_offset <= cl_offset + 1;
		end
		else if (cci_c0Rx_isReadRsp(cp2af_sRx.c0))
		begin
			cls_processed <= cls_processed + 1;
		end
	end
	
	//
	// READ RESPONSE PROCESSING
	//
	
	logic [63:0] bit_result;
	
	/*p128_1block scan_4bit
	(
		.clk,
		
		.reset(reset || new_block_received),
		.en((bit_encoding == 0) && cci_c0Rx_isReadRsp(cp2af_sRx.c0)),
		
		.incoming_cl(cp2af_sRx.c0.data),
		.predicate(filter_pred),
		
		.bit_result(bit_result[255:128]) 
	);*/

	p64_1block scan_8bit
	(
		.clk,
		
		.reset(reset || new_block_received),
		.en((bit_encoding == 1) && cci_c0Rx_isReadRsp(cp2af_sRx.c0)),
		
		.incoming_cl(cp2af_sRx.c0.data),
		.predicate(filter_pred),
		
		.bit_result(bit_result) 
	);

	/*
	p32_1block scan_16bit
	(
		.clk,
		
		.reset(reset || new_block_received),
		.en((bit_encoding == 2) && cci_c0Rx_isReadRsp(cp2af_sRx.c0)),
		
		.incoming_cl(cp2af_sRx.c0.data),
		.predicate(filter_pred),
		
		.bit_result(bit_result) 
	);
	
	
	p16_1block scan_32bit
	(
		.clk,
		
		.reset(reset || new_block_received),
		.en((bit_encoding == 3) && cci_c0Rx_isReadRsp(cp2af_sRx.c0)),
		
		.incoming_cl(cp2af_sRx.c0.data),
		.predicate(filter_pred),
		
		.bit_result(bit_result[15:0]) 
	);*/
	
	always_ff @(posedge clk)
	begin	
		if(reset)
		begin
			csrs.cpu_rd_csrs[2].data = 0;
			
			csrs.cpu_rd_csrs[3].data = 0;
			csrs.cpu_rd_csrs[4].data = 0;
			csrs.cpu_rd_csrs[5].data = 0;
			csrs.cpu_rd_csrs[6].data = 0;
		end
		else
		begin
			if(rsp_received)
			begin
				csrs.cpu_rd_csrs[2].data = cl_block;
								
				csrs.cpu_rd_csrs[3].data = bit_result;
				//csrs.cpu_rd_csrs[4].data = bit_result[127:64];
				//csrs.cpu_rd_csrs[5].data = bit_result[191:128];
				//csrs.cpu_rd_csrs[6].data = bit_result[255:192];
			
				//$display("CL #%0d bit result: %0b", cl_block, bit_result);
				//for(int i = 0; i < 64; i = i + 1)
				//begin
				//	part_count = part_count + bit_result[i];
				//end
				//$display("(Count: %0d)", part_count);
			end	
		end
	end

	// CSRS writes to notify the SW about processing	
	always_comb
	begin
		csrs.afu_id = `AFU_ACCEL_UUID;	
		
		csrs.cpu_rd_csrs[1].data = 64'(0);	
		csrs.cpu_rd_csrs[7].data = 64'(0);
				
		csrs.cpu_rd_csrs[0].data = reads_done;	
	end
	
	assign af2cp_sTx.c1.valid = 1'b0;
	assign af2cp_sTx.c2.mmioRdValid = 1'b0;

endmodule