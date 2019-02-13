#ifndef __read_pred_h__
#define __read_pred_h__


#include "fpga/base/sw/opae_svc_wrapper.h"
#include "fpga/base/sw/csr_mgr.h"

#include "afu_json_info.h"

class READ_PRED{

private:
	OPAE_SVC_WRAPPER *fpga_wrapper;
	CSR_MGR *csrs;

public:
	READ_PRED();
	READ_PRED(const char* accel_uuid);
	~READ_PRED();

	bool isAccOK(){
		return fpga_wrapper->isOk();
	}

	void connectToAccelerator();
	void connectToCSRManager();
	void writePredicate(uint64_t predicate);
	void waitAndWriteResponse();

};

#endif
