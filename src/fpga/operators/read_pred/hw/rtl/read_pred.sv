`include "cci_mpf_if.vh"
`include "csr_mgr.vh"
`include "afu_json_info.vh"


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

    // ====================================================================
    //
    //  CSRs (simple connections to the external CSR management engine)
    //
    // ====================================================================
    
    
    logic[64:0] param_value;
    
    always_comb
    begin
    	// The AFU ID is a unique ID for a given program.  Here we generated
    	// one with the "uuidgen" program and stored it in the AFU's JSON file.
    	// ASE and synthesis setup scripts automatically invoke afu_json_mgr
    	// to extract the UUID into afu_json_info.vh.
    	csrs.afu_id = "a610831b-d12a-4d07-8368-1640faa3d0cd";

    	// Default
    	for (int i = 0; i < NUM_APP_CSRS; i = i + 1)
    	begin
    		csrs.cpu_rd_csrs[i].data = 64'(0);
    	end
    	
    	csrs.cpu_rd_csrs[0].data = param_value;
    end

    //
    // Consume configuration CSR writes
    //

    // CSR 1 triggers the read of parameter
    logic parameter_ready;
    //t_ccip_clAddr parameter_addr;

    always_ff @(posedge clk)
    begin
    	if (csrs.cpu_wr_csrs[1].en)
    	begin
    		parameter_ready <= csrs.cpu_wr_csrs[1].en;
    	end
    end
      
    logic csr_written;
    always_ff @(posedge clk)
    begin
    	if (parameter_ready)
    	begin
    		//csrs.cpu_rd_csrs[0].data <= csrs.cpu_wr_csrs[1].data;
    		param_value <= csrs.cpu_wr_csrs[1].data;
    		csr_written <= 1'b1;
    	end
    end
    
       
    // =========================================================================
    //
    //   Main AFU logic
    //
    // =========================================================================

    //
    // States in our simple example.
    //
    typedef enum logic [0:0]
    {
        STATE_IDLE,
        STATE_RUN
    }
    t_state;

    t_state state;

    //
    // State machine
    //
    always_ff @(posedge clk)
    begin
        if (reset)
        begin
            state <= STATE_IDLE;
        end
        else
        begin
            // Trigger the AFU when mem_addr is set above.  (When the CPU
            // tells us the address to which the FPGA should write a message.)
            if ((state == STATE_IDLE) && parameter_ready)
            begin
                state <= STATE_RUN;
                $display("AFU running...");
            end

            if ((state == STATE_RUN) && csr_written)
            begin
                state <= STATE_IDLE;
                $display("AFU done...");
            end
        end
    end

    
endmodule // app_afu