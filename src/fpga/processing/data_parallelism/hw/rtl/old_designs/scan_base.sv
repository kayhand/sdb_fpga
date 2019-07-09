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
	input  logic c1NotEmpty,
	
	output [3:0] value
);
			
assign value = 4'b1111;
	
assign af2cp_sTx.c0.valid = 1'b0;
assign af2cp_sTx.c1.valid = 1'b0;
assign af2cp_sTx.c2.mmioRdValid = 1'b0;

endmodule