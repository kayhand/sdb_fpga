`include "cci_mpf_if.vh"
`include "csr_mgr.vh"

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
	
	/*** 
	 *	QUERY STATE (CSRS[7])  
	 ***/		
	//0: scan, 1: join, 2: agg, 5: query_done
	logic[2:0] query_state;
	logic new_operator;
	always_ff @(posedge clk)
	begin
		if (csrs.cpu_wr_csrs[7].en)
		begin	
			query_state <= csrs.cpu_wr_csrs[7].data;
			$display("[BASE_AFU] Current processing state: %0d", csrs.cpu_wr_csrs[7].data);
		end
		new_operator <= csrs.cpu_wr_csrs[7].en;
	end
	
	//
	// Convert MPF interfaces back to the standard CCI structures.
	//
	t_if_ccip_Rx mpf2af_sRx;
	t_if_ccip_Tx af2mpf_sTx;

	t_if_ccip_Tx join_sTx;
		
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

		/*
		FIX THIS
		if(reset)
		begin
			fiu.c0Tx = cci_mpf_cvtC0TxFromBase(af2mpf_sTx.c0);
			fiu.c1Tx = cci_mpf_cvtC1TxFromBase(af2mpf_sTx.c1);
			fiu.c2Tx = af2mpf_sTx.c2;
		end
		else if(query_state == 0)
		begin
			fiu.c0Tx.hdr.address = af2mpf_sTx.c0.hdr.address;
			fiu.c1Tx.hdr.address = af2mpf_sTx.c1.hdr.address;
		end
		else if(query_state == 1)
		begin
			fiu.c0Tx.hdr.address = join_sTx.c0.hdr.address;
			fiu.c1Tx.hdr.address = join_sTx.c1.hdr.address;
		end
		*/
	
		if (reset || query_state == 0)
		begin
			fiu.c0Tx = cci_mpf_cvtC0TxFromBase(af2mpf_sTx.c0);
			fiu.c1Tx = cci_mpf_cvtC1TxFromBase(af2mpf_sTx.c1);
			fiu.c2Tx = af2mpf_sTx.c2;
			//$display("[BASE_AFU] Tx[c0] and Tx[c1] ports are set for scans!");
		end
		else if(query_state == 1)
		begin
			fiu.c0Tx = cci_mpf_cvtC0TxFromBase(join_sTx.c0);				
			fiu.c1Tx = cci_mpf_cvtC1TxFromBase(join_sTx.c1);
			fiu.c2Tx = join_sTx.c2;
				
			//$display("[BASE_AFU] Tx[c0] and Tx[c1] ports are set for joins!");
		end
		
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
			
		//	$display("[MPF] Read Req Detected!");
		end
				
		if (cci_mpf_c1TxIsWriteReq(fiu.c1Tx))
		begin
			// See comments on the c0Tx fields above
			fiu.c1Tx.hdr.ext.addrIsVirtual = 1'b1;
			fiu.c1Tx.hdr.ext.mapVAtoPhysChannel = 1'b1;
			fiu.c1Tx.hdr.ext.checkLoadStoreOrder = 1'b1;

			// Don't ever request an MPF partial write
			fiu.c1Tx.hdr.pwrite = t_cci_mpf_c1_PartialWriteHdr'(0);
			
		//	$display("[MPF] Write Req Detected!");
		end

		//fiu.c2Tx = af2mpf_sTx.c2;	
	end
	
	logic join_partition_processed;
	
	// Connect to the AFU
	scan_afu
		scan_unit
		(
			.clk,
			.reset,
			
			.is_active(query_state == 0),			
			
			.cp2af_sRx(mpf2af_sRx),			
			.af2cp_sTx(af2mpf_sTx),
						
			.csrs,
			.c0NotEmpty,
			.c1NotEmpty,
			
			.join_partition_processed(join_partition_processed)
		);
		
		/*
	join_afu
		join_unit
		(
			.clk,
			.reset,
			
			.is_active(query_state == 1),
			
			.cp2af_sRx(mpf2af_sRx),
			.af2cp_sTx(join_sTx),
			
			.csrs,
			.c0NotEmpty,
			.c1NotEmpty,
			
			.partition_processed(join_partition_processed)
		);	*/
					
endmodule //app_afu