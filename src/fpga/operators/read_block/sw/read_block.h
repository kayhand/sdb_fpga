#ifndef __read_block_h__
#define __read_block_h__

#include "fpga/base/sw/opae_svc_wrapper.h"
#include "fpga/base/sw/csr_mgr.h"

#include <bitset>
#include <iostream>

class READ_BLOCK{

private:
	OPAE_SVC_WRAPPER *fpga_wrapper;
	CSR_MGR *csrs;

	uint64_t column_part_pa;
	uint64_t read_buff_pa;
	uint64_t write_buff_pa;

public:
	READ_BLOCK();
	~READ_BLOCK();

	void connectToAccelerator();
	void connectToCSRManager();
	bool registerReadBuffer(void*& buff, size_t size);
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

			/*std::cout << i << ": " << high << " | " << low << std::endl;
			local_count += high.count() + low.count();
			if((i + 1) % 8 == 0){
				std::cout << "\n===== " << local_count << " ====\n" << std::endl;
				count += local_count;
				local_count = 0;
			}*/

		}
		std::cout << "Count result: " << count << std::endl;
	}

	void printVTPStats(){
		fpga_wrapper->printVTPStats();
	}

};

#endif
