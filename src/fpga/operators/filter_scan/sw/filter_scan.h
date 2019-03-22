#ifndef __filter_scan_h__
#define __filter_scan_h__

#include "fpga/base/sw/opae_svc_wrapper.h"
#include "fpga/base/sw/csr_mgr.h"

#include <bitset>
#include <iostream>

class FPGA_SCAN{

private:
	OPAE_SVC_WRAPPER *fpga_wrapper;
	CSR_MGR *csrs;

	uint64_t read_buff_pa;
	uint64_t write_buff_pa;

public:
	FPGA_SCAN();
	~FPGA_SCAN();

	void connectToAccelerator();
	void connectToCSRManager();

	bool prepareReadBuffer(volatile void*& buff, void*& block, size_t size);
	void prepareWriteBuffer(volatile void*& buff, size_t size);

	void sendQueryParams(int total_cls, uint32_t pred);
	void shareBuffVA(int csr_id, intptr_t buff_va);

	void waitAndWriteResponse(int total_cls, volatile uint64_t*& buff);
	void notifyFPGA(int code);

	bool isAFUOK(){
		return fpga_wrapper->isOk();
	}

	void freeBuffer(void *&buff){
		fpga_wrapper->freeBuffer(buff);
	}

	void printFilterResults(volatile uint64_t *& buff, int total_words){
		int count = 0;
		//int local_count = 0;
		for(int i = 0; i < total_words; i++){
			std::bitset<32> high(buff[i] >> 32);
			std::bitset<32> low(buff[i]);
			count += high.count() + low.count();
		}
		std::cout << "Count result: " << count << std::endl;
	}

};

#endif
