#ifndef __mem_rw_h__
#define __mem_rw_h__


#include "fpga/base/sw/opae_svc_wrapper.h"
#include "fpga/base/sw/csr_mgr.h"

class MEMORY_RW{

private:
	OPAE_SVC_WRAPPER *fpga_wrapper;
	CSR_MGR *csrs;

	volatile char* buff;
	uint64_t buff_pa;

public:
	MEMORY_RW(const char* accel_uuid);
	~MEMORY_RW();

	void connectToAccelerator();
	void connectToCSRManager();
	void allocateBuffer(size_t size);
	void notifyAccelerator();
	void waitAndWriteResponse();

};

#endif
