#ifndef __read_pred_h__
#define __read_pred_h__


#include "fpga/base/sw/opae_svc_wrapper.h"
#include "fpga/base/sw/csr_mgr.h"

class READ_PRED{

private:
	OPAE_SVC_WRAPPER *fpga_wrapper;
	CSR_MGR *csrs;

public:
	READ_PRED(const char* accel_uuid);
	~READ_PRED();

	void connectToAccelerator();
	void connectToCSRManager();
	void writePredicate(uint64_t predicate);
	void waitAndWriteResponse();

};

#endif
