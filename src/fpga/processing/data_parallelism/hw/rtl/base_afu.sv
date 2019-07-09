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
	scan_afu
		scan_unit
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