#ifndef __block_rw_h__
#define __block_rw_h__

#include "fpga/base/sw/opae_svc_wrapper.h"
#include "fpga/base/sw/csr_mgr.h"

#include <bitset>
#include <iostream>
#include <vector>

class BLOCK_RW{

private:
	OPAE_SVC_WRAPPER *fpga_wrapper;
	CSR_MGR *csrs;

	uint64_t column_part_pa;
	uint64_t read_buff_pa;
	uint64_t write_buff_pa;

	std::vector<uint64_t> bit_results;

public:
	BLOCK_RW();
	~BLOCK_RW();

	void connectToAccelerator();
	void connectToCSRManager();
	bool registerReadBuffer(void*& buff, size_t size);

	bool prepareReadBuffer(volatile void*& buff, void*& block, size_t size);
	void prepareWriteBuffer(volatile void*& buff, size_t size);

	void sendQueryParams(int total_cls, uint32_t pred, int bit_encoding);
	void sendQueryParams(int total_cls, uint32_t pred);
	void sendQueryParams(int total_cls);
	void registerBitMapIntoFPGA(void*& bit_map, int len);

	void setParallelism(int csr_id, int p_id){
		csrs->writeCSR(csr_id, p_id);
	}

	//0: scan, 1: join
	void setFunctionType(int f_id){
		csrs->writeCSR(7, f_id);
	}

	void shareBuffVA(int csr_id, intptr_t buff_va);

	void waitForProcessing(int total_cls, volatile void*& write_buff);
	void waitAndWriteResponse(int total_cls);

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

	void addBitResult(uint64_t buff){
		this->bit_results.push_back(buff);
	}

	int totalResults(){
		return this->bit_results.size();
	}

	void printFilterResult(){
		int filter_count = 0;
		int local_count = 0;
		for(uint64_t buff : bit_results){
			std::bitset<64> bit_res(buff);
			local_count = bit_res.count();
			std::cout << " < " << bit_res.to_string() << " > "
					<< " (" << local_count << ") " << std::endl;
			filter_count += local_count;
		}
		printf("Filter count: %d\n", filter_count);
	}

	int printPartitionResult(volatile void*& write_buff, int total_cls){
		uint8_t *buff = (uint8_t *) write_buff;
		int filter_count = 0;

		printf("\n---- PARTITION RESULT ----\n\n");
		for(int index = 0; index < total_cls; index++){

			std::string cl_result = "";
			for(int i = 0; i < 16; i++){
				std::bitset<8> bit_res(buff[index * 64 + i]);

				cl_result += bit_res.to_string();
				filter_count += bit_res.count();
			}
			uint8_t cl_id = buff[index * 64];

			printf("      CL %d ", index);
			std::cout << " <" << cl_result << " > " << std::endl;
		}

		std::cout << "---- Partition count: " << filter_count << "----" << std::endl;
		std::cout << "" << std::endl;

		return filter_count;
 	}

	int getPartitionCount(volatile void*& write_buff, int total_cls){
		uint8_t *buff = (uint8_t *) write_buff;
		int filter_count = 0;
		for(int index = 0; index < total_cls; index++){
			for(int i = 0; i < 16; i++){
				std::bitset<8> bit_res(buff[index * 64 + i]);
				filter_count += bit_res.count();
			}
		}
		return filter_count;
 	}

	void printVTPStats(){
		fpga_wrapper->printVTPStats();
	}

	void printRegisterValues(){
		printf("Current state of the registers: \n");
		for(int csr_id = 0; csr_id < 8; csr_id++){
			printf("CSR[%d]: %d | ", csr_id, csrs->readCSR(csr_id));
		}
		printf("\n");
	}

};

#endif
