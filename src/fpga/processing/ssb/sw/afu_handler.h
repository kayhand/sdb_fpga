#ifndef __scan_afu_handler_h__
#define __scan_afu_handler_h__

#define CL_SIZE 512
#define WORD_SIZE 64

#include "fpga/base/sw/opae_svc_wrapper.h"

#include "fpga/base/sw/csr_mgr.h"

#include "util/Types.h"

#include <bitset>
#include <iostream>
#include <vector>


class AFU_HANDLER{

private:
	OPAE_SVC_WRAPPER *fpga_wrapper;

	CSR_MGR *csrs;

	uint64_t column_part_pa;
	uint64_t read_buff_pa;
	uint64_t write_buff_pa;

	std::vector<uint64_t> bit_results;

public:
	AFU_HANDLER();
	~AFU_HANDLER();

	void connectToAccelerator();
	void connectToCSRManager();

	bool prepareReadBuffer(volatile void*& buff, void*& block, size_t size);
	void prepareWriteBuffer(volatile void*& buff, size_t size);

	void writeParameterToCSR(CSRS_TYPE csr_type, uint32_t param_value){
		csrs->writeCSR((int) csr_type, param_value);
	}

	void writeBufferAddressToCSR(CSRS_TYPE csr_type, intptr_t param_value){
		csrs->writeCSR((int) csr_type, param_value);
	}

	void waitForProcessing(int total_cls, volatile void*& write_buff);

	void waitForBitMapProcessing();
	void waitForJoinProcessing();

	void sendBitMapForJoin();

	void notifyFPGA(QUERY_STATE state);

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

	int countFilterResult(volatile void*& write_buff, int total_cls, int bit_encoding){
		// --> write_buff was updated 1-CL (512-bits) at-a-time
		// --> each buffer has 64-CLs of data in it (4096 BYTES)
		// 	--> assuming word_size is 64-bits
		// 	--> each result bufffer have | 64 * (512 / word_size) | = | 64 * (512/64) | = 512 words in it

		int words_per_cl = CL_SIZE / WORD_SIZE; // 8 slots in (uint64*_t) write_buff
		int res_words_per_cl = (CL_SIZE / bit_encoding) / WORD_SIZE; // # of slots required in (uint64*_t) write_buff
		// 4-bit encoding: 2 (512 / 4 / 64)
		// 8-bit encoding: 1 (512 / 8 / 64)

		uint64_t *result_buffer = (uint64_t *) write_buff;

		int count_per_cl = 0;
		int count_total = 0;

		int buff_index = 0;

		printf("\n[FH][RES_COUNT] \n");
		printf("\n ===================== \n");
		printf("\t");
		for(int cur_cl = 0; cur_cl < total_cls; cur_cl++){ // < 64
			for(int word_id = 0; word_id < res_words_per_cl; word_id++){ // <
				std::bitset<64> bit_result(result_buffer[buff_index + word_id]);
				count_per_cl += bit_result.count();
			}
			//printf("(CL #%d @%d: %d), ", cur_cl, buff_index, count_per_cl);

			count_total += count_per_cl;
			count_per_cl = 0;

			buff_index += words_per_cl;
		}
		printf("\n");
		printf("=====================\n");
		return count_total;
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
