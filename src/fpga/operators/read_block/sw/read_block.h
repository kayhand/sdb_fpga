#ifndef __read_block_h__
#define __read_block_h__

#include "fpga/base/sw/opae_svc_wrapper.h"
#include "fpga/base/sw/csr_mgr.h"

class READ_BLOCK{

private:
	OPAE_SVC_WRAPPER *fpga_wrapper;
	CSR_MGR *csrs;

	uint64_t read_buff_pa;
	uint64_t write_buff_pa;

public:
	READ_BLOCK();
	~READ_BLOCK();

	void connectToAccelerator();
	void connectToCSRManager();
	bool prepareReadBuffer(volatile void*& buff, size_t size);
	void prepareWriteBuffer(volatile void*& buff, size_t size);
	void shareDataBlock();
	void waitAndWriteResponse(volatile uint64_t*& buff);

	bool isAFUOK(){
		return fpga_wrapper->isOk();
	}

};

#endif
