#ifndef __fpga_handler_h__
#define __fpga_handler_h__

#include <pthread.h>
#include <vector>
#include <atomic>

#include "Thread.h"
#include "ThreadHandler.h"
#include "Syncronizer.h"

#include "exec/util/WorkQueue.h"
#include "network/server/TCPAcceptor.h"

#include "api/JobWrapper.h"
#include "api/ScanApi.h"
#include "api/JoinApi.h"

#include "ssb/sw/afu_handler.h"

class FPGAHandler : public ThreadHandler {

	void scanAtATime(ScanApi *& scanJob){
		int total_parts = scanJob->TotalPartitions();
		int total_elements = scanJob->TotalElements();
		int bit_encoding = scanJob->BitEncoding();

		JOB_TYPE scan_type = scanJob->JobType();

		uint32_t filter_pred;
		if(scan_type == LO_DISC_SCAN){ // 1 <= value <= 3
			filter_pred = scanJob->RangePredicate();
		}
		else{ // d_year: value == 1993; lo_quantity <= 24
			filter_pred = scanJob->FilterPredicate();
		}

		/*printf("\n");
		std::cout << "=====================================" << std::endl;
		std::cout << "[FH][AFU][INIT] Scan Type: " << scan_type << std::endl;
		std::cout << "[FH][AFU][INIT] Query Predicate: " << filter_pred << std::endl;
		std::cout << "[FH][AFU][INIT] Total partitions to process: " << total_parts << std::endl;
		std::cout << "[FH][AFU][INIT] Total number of elements: " << total_elements << std::endl;
		std::cout << "=====================================" << std::endl;
		printf("\n");*/

		int items_per_read = CL_SIZE / bit_encoding;
		//printf("[FH][AFU][INFO] AFU will receive %d compressed column values for each CL request! \n",
				//items_per_read);

		int total_cls_per_column = (int) ceil((double) total_elements / (double) items_per_read);
		//printf("[FH][AFU][INFO] AFU will read %d cache-lines in total for this column! \n", total_cls_per_column);

		//printf("[FH][AFU][INFO] State of the queue: ");
		//this->fpga_queue->printQueue();
		//printf("\n");

		size_t partition_size = PAGE_SIZE; // 4096
		int total_cls_per_partition = partition_size / 64; // 64

		int total_cls = min(total_cls_per_column, total_cls_per_partition);

		afu_handler.writeParameterToCSR(CSRS_TYPE::total_cls, total_cls);
		afu_handler.writeParameterToCSR(CSRS_TYPE::filter_predicate, filter_pred);
		afu_handler.writeParameterToCSR(CSRS_TYPE::job_type, scan_type);

		// timing
		hrtime_t start = gethrtime();
		while(this->fpga_queue->isNotEmpty()){
			Node *work_unit = this->fpga_queue->nextElement();
			int part_id = work_unit->value.getPart();

			volatile void* read_buff = read_buffers[scan_type][part_id];
			volatile void* write_buff = write_buffers[scan_type][part_id];

			afu_handler.writeBufferAddressToCSR(CSRS_TYPE::column_address, intptr_t(read_buff));
			afu_handler.writeBufferAddressToCSR(CSRS_TYPE::result_address, intptr_t(write_buff));

			afu_handler.waitForProcessing(total_cls, write_buff);
		}
		hrtime_t end = gethrtime();
		double micro_secs = (double) (end - start) / 1000.0;
		std::cout << "Took " << micro_secs << " microseconds " << std::endl;

		//printf("\n[FH][AFU][END] All partitions processed for the current column!\n\n");

		for(int buff_id = 0; buff_id < scanJob->TotalPartitions(); buff_id++){
		//for(int part_id = 0; part_id < total_parts; part_id++){
			volatile void* buff = write_buffers[scan_type][buff_id];
			scanJob->copyFPGAWriteBuffer((uint64_t*) buff, buff_id, total_cls);
		}

		//printf("\n[FH][RESULT] \t || Filter Count: %d || \n\n", filter_count);
	}

	void joinAtATime(JoinApi *& joinJob){
		int bitmap_size = joinJob->BitMapSize();
		int bitmap_cls = bitmap_size / CL_SIZE + 1;

		JOB_TYPE join_type = joinJob->JobType();

		printf("\n");
		std::cout << "=====================================" << std::endl;
		std::cout << "[FH][INIT] Registering join bitmap " << std::endl;
		std::cout << "[FH][INIT] Bitmap Size: " << bitmap_size << std::endl;
		std::cout << "[FH][INIT] Bitmap CLs: " << bitmap_cls << std::endl;
		std::cout << "=====================================" << std::endl;
		printf("\n");

		afu_handler.writeParameterToCSR(CSRS_TYPE::job_type, join_type);
		afu_handler.writeParameterToCSR(CSRS_TYPE::total_cls, bitmap_cls);
		afu_handler.writeParameterToCSR(CSRS_TYPE::bitmap_state, 1);

		volatile void* bitmap_buff = read_buffers[join_type][0];
		afu_handler.writeBufferAddressToCSR(CSRS_TYPE::column_address, intptr_t(bitmap_buff));

		afu_handler.waitForBitMapProcessing();

		printf("\n[FH][AFU][JOIN_STATUS] AFU received the bitmap!\n");

		//Continue with join processing ...
		int fk_parts = joinJob->TotalPartitions();
		int total_elements = joinJob->TotalElements();
		int fk_encoding = joinJob->BitEncoding();

		printf("\n");
		std::cout << "=====================================" << std::endl;
		std::cout << "[FH][INIT] Total # of FK partitions: " << fk_parts << std::endl;
		std::cout << "[FH][INIT] Total # of elements in FK Column: " << total_elements << std::endl;
		std::cout << "[FH][INIT] FK Column Bit Encoding: (" << fk_encoding << "-bits) "<< std::endl;
		std::cout << "=====================================" << std::endl;
		printf("\n");

		int fk_partition_cls = PAGE_SIZE / 64;
		afu_handler.writeParameterToCSR(CSRS_TYPE::total_cls, fk_partition_cls);
		afu_handler.writeParameterToCSR(CSRS_TYPE::bitmap_state, 0);

		while(this->fpga_queue->isNotEmpty()){
			Node *work_unit = this->fpga_queue->nextElement();
			int part_id = work_unit->value.getPart();

			volatile void* read_buff = read_buffers[join_type][part_id + 1];
			volatile void* write_buff = write_buffers[join_type][part_id];

			afu_handler.writeBufferAddressToCSR(CSRS_TYPE::column_address, intptr_t(read_buff));
			afu_handler.writeBufferAddressToCSR(CSRS_TYPE::result_address, intptr_t(write_buff));

			afu_handler.waitForJoinProcessing();
		}
		printf("\n[FH][AFU][END] All partitions processed for the FK column!\n\n");

		/*for(int part_id = 0; part_id < 1; part_id++){
			volatile void* buff = write_buffers[join_type][part_id];
			joinJob->copyFPGAWriteBuffer((uint32_t*) buff, part_id);
			printf("\n[FH][JOIN][BIT_RESULT] \n");
			joinJob->countBitResults();
			printf("\n[FH][JOIN][BIT_RESULT] \n");
		}*/

		for(int buff_id = 0; buff_id < joinJob->TotalPartitions(); buff_id++){
			volatile void* buff = write_buffers[join_type][buff_id];
			joinJob->copyFPGAWriteBuffer((uint32_t*) buff, buff_id);
		}
	}

	AFU_HANDLER afu_handler;

public:
	FPGAHandler(Syncronizer *sync, EXEC_TYPE e_type, int thr_id) :
		ThreadHandler(sync, e_type, thr_id) {
	}

	inline void executeScan(Node *work_unit){
		int part_id = work_unit->value.getPart();

	}

	void *run() {
		this->thr_sync->waitOnStartBarrier();

		printf("[FH] FPGA Thread waiting on FPGA barrier!\n");

		if(!this->connectToFPGA()){
			printf("[FH] -- Problem with connecting to the FPGA Unit!\n");
		}
		else{
			printf("[FH] -- Preparing column partition buffers for FPGA!\n");

			// Scan Buffers
			//d_year->PrintInputBlock(0, true);
			this->prepareInputBuffersForFPGA(afu_handler, d_year);

			lo_discount->setNumOfPartitions(732);
			this->prepareInputBuffersForFPGA(afu_handler, lo_discount);

			//lo_quantity->setNumOfPartitions(1465);
			//this->prepareInputBuffersForFPGA(afu_handler, lo_quantity);

			this->prepareResultBuffersForFPGA(afu_handler, d_year);
			this->prepareResultBuffersForFPGA(afu_handler, lo_discount);
			//this->prepareResultBuffersForFPGA(afu_handler, lo_quantity);

			printf("[FH] -- Buffers ready for processing!\n");
		}

		this->thr_sync->waitOnFPGABarrier();

		printf("\n ===================== \n");
		printf("[FH][D_YEAR_SCAN][START]!\n");
		afu_handler.notifyFPGA(QUERY_STATE::SCAN_PROCESSING);
		this->scanAtATime(d_year);
		printf("[FH][D_YEAR_SCAN][END]!\n");
		printf("[FH][D_YEAR_SCAN][COUNT]\n");
		d_year->countBitResults();
		printf("=====================\n");

		/*printf("\n[FH][JOIN][START]!\n");
		lineorder_date->setNumOfPartitions(2);
		this->prepareBitMapBuffer(afu_handler, lineorder_date);
		this->prepareInputBuffersForFPGA(afu_handler, lineorder_date);
		this->prepareResultBuffersForFPGA(afu_handler, lineorder_date);*/

		/*afu_handler.notifyFPGA(QUERY_STATE::JOIN_PROCESSING);
		this->addWorkItems(JOB_TYPE::LO_DATE_JOIN, this->fpga_queue, lineorder_date->TotalPartitions());
		this->joinAtATime(lineorder_date);
		printf("\n[FH][JOIN][END]!\n");
		printf("\n[FH][JOIN][COUNT]\n");
		lineorder_date->countBitResults();*/

		printf("\n ===================== \n");
		printf("[FH][LO_DISCOUNT_SCAN][START]!\n");
		this->addWorkItems(LO_DISC_SCAN, this->fpga_queue, lo_discount->TotalPartitions());
		afu_handler.notifyFPGA(QUERY_STATE::SCAN_PROCESSING);
		this->scanAtATime(lo_discount);
		printf("[FH][LO_DISCOUNT_SCAN][END]!\n");
		printf("[FH][LO_DISCOUNT_SCAN][COUNT]\n");
		lo_discount->countBitResults();
		printf("=====================\n");

		/*printf("\n ===================== \n");
		printf("[FH][LO_QUANTITY_SCAN][START]!\n");
		this->addWorkItems(LO_QUANTITY_SCAN, this->fpga_queue, lo_quantity->TotalPartitions());
		afu_handler.notifyFPGA(QUERY_STATE::SCAN_PROCESSING);
		this->scanAtATime(lo_quantity);
		printf("[FH][LO_QUANTITY_SCAN][END]!\n");
		printf("[FH][LO_QUANTITY_SCAN][COUNT]\n");
		lo_quantity->countBitResults();
		printf("=====================\n");*/

		printf("\n[FH][END] Sending query completion signal!\n");
		afu_handler.notifyFPGA(QUERY_STATE::QUERY_DONE);

		this->releaseAllBuffers(afu_handler);
		printf("[FH] Buffers released!\n");

		this->thr_sync->waitOnEndBarrier();
		printf("[FH] FPGA Thread done!\n");

		return NULL;
	}

	bool connectToFPGA(){
		printf("[FH] Connection to AFU initializing...\n");
		afu_handler.connectToAccelerator();
		printf("[FH] Connected to the AFU ...\n");
		if(!afu_handler.isAFUOK()){
			printf("[FH] Problem connecting to the AFU!\n");
			return false;
		}
		else{
			afu_handler.connectToCSRManager();
		}
		printf("[FH] -- Connection established!\n");
		return true;
	}

	void prepareBitMapBuffer(AFU_HANDLER &fpga_wrapper, JoinApi* joinApi){
		int block_size = PAGE_SIZE;
		volatile void* read_buff;

		int job_id = joinApi->JobType();

		uint64_t** bitmap_block = joinApi->BitMap();
		testBitMap(bitmap_block, joinApi->BitMapSize());

		void* bitmap_buff = (void *) (*bitmap_block);

		bool isOK = fpga_wrapper.prepareReadBuffer(read_buff, bitmap_buff, block_size);
		if(isOK){
			read_buffers[job_id].push_back(read_buff);
		}
		else{
			printf("[FH] -- Problem with buffer allocation for the bitmap \n");
		}
	}

	void testBitMap(uint64_t** bitmap_result, int size){
		printf("\n ===================== \n");
		printf("Testing bitmap result before semi-join setup ...\n");
		printf("Bitmap size: %d \n", size);

		uint64_t *bit_map = *bitmap_result;

		int word_id = 0;
		int filter_count = 0;
		int remaining = size;
		while(remaining > 0){
			std::bitset<64> bit_res(bit_map[word_id]);
			filter_count += bit_res.count();
			word_id++;
			remaining -= 64;
		}

		printf("\n");
		printf("\n[FH][FILTER_COUNT] \t || Filter Count: %d || \n\n", filter_count);
		printf("=====================\n");

 	}

	void prepareInputBuffersForFPGA(AFU_HANDLER &fpga_wrapper, JobWrapper* jobWrapper){
		int block_size = PAGE_SIZE;
		volatile void* read_buff;

		int job_id = jobWrapper->JobType();
		int total_partitions = jobWrapper->TotalPartitions();

		printf("Job_id: %d \n # of input buffers (partition blocks): %d\n\n", job_id, total_partitions);
		for(int part_id = 0; part_id < total_partitions; part_id++){
			void* partition_block = (void *) jobWrapper->BaseColumn()->PartData(part_id);
			bool isOK = fpga_wrapper.prepareReadBuffer(read_buff, partition_block, block_size);
			if(isOK){
				read_buffers[job_id].push_back(read_buff);
			}
			else{
				printf("[FH] -- Problem with buffer allocation (part_id: %d)\n", part_id);
			}
		}

		printf("%d read buffers allocated for the AFU\n", read_buffers[job_id].size());
	}

	void prepareResultBuffersForFPGA(AFU_HANDLER& fpga_wrapper, JobWrapper* jobWrapper){
		int block_size = PAGE_SIZE;
		volatile void* write_buff;

		int job_id = jobWrapper->JobType();
		int total_parts = jobWrapper->TotalPartitions();

		for(int part_id = 0; part_id < total_parts; part_id++){
			fpga_wrapper.prepareWriteBuffer(write_buff, block_size);
			write_buffers[job_id].push_back(write_buff);
		}

		printf("[FH] -- %d write buffers for job #%d is ready for FPGA\n",
				write_buffers[job_id].size(), job_id);
	}

	void releaseAllBuffers(AFU_HANDLER &fpga_wrapper){
		for(auto &buff : read_buffers){
			fpga_wrapper.freeBuffer((void *&) (buff.second));
		}

		for(auto &buff : write_buffers){
			fpga_wrapper.freeBuffer((void *&) (buff.second));
		}
	}

	void printBitMap(uint8_t *bit_map){
		for(int i = 0; i < 100; i++){
			uint8_t cur_res = bit_map[i];
			for(int ind = 0; ind < 8; ind++){
				cout << (cur_res & 1);
				cur_res >>= 1;
			}
		}
		cout << endl;
	}
};

#endif
