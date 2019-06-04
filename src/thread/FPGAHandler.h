#ifndef __fpga_handler_h__
#define __fpga_handler_h__

#include <pthread.h>
#include <vector>
#include <atomic>

#include <opae/fpga.h>

#include "Thread.h"
#include "ThreadHandler.h"
#include "Syncronizer.h"

#include "exec/util/WorkQueue.h"
#include "network/server/TCPAcceptor.h"

#include "api/ScanApi.h"

#include "data_parallelism/sw/block_rw.h"

enum AFU_TYPE {
	FILTER_SCAN = 0,
	JOIN = 1
};

enum BIT_ENCODING {
	_4_BITS = 0,
	_8_BITS = 1,
	_16_BITS = 2,
	_32_BITS = 3
};

enum PARALLELISM {
	_128_WAY = 0,
	_64_WAY = 1,
	_32_WAY = 2,
	_16_WAY = 3,
	_8_WAY = 4,
	_4_WAY = 5,
	_2_WAY = 6,
	_1_WAY = 7
};

class FPGAHandler : public ThreadHandler {

	void scanPipeline() {
		printf("[FH] Starting the scan pipeline...\n");

		int total_parts = this->lo_discount->TotalPartitions();
		uint32_t filter_pred = this->lo_discount->FilterPredicate();
		size_t block_size = 4096;

		printf("[FH] Column scan for the lo_discount column is starting (pred: %u) ...\n", filter_pred);
		printf("[FH] Total partitions to process: %d\n", total_parts);

		BLOCK_RW block_rw;
		block_rw.connectToAccelerator();

		if(!block_rw.isAFUOK()){
			printf("[FH] Problem connecting to the AFU!\n");
		}
		else{
			block_rw.connectToCSRManager();

			for(int part_id = 0; part_id < 1; part_id++){
				printf("[FH] Preparing read/write buffers for partition %d ...\n", part_id);

				void* partition_block = retriveScanBlock(this->lo_discount, part_id);
				//void* read_buff = retriveScanBlock(part_id);

				size_t wr_buff_size = block_size; //need block_size bits
				printf("[FH] Write block size: %d\n", (int) wr_buff_size);

				volatile void* read_buff;
				volatile uint64_t* write_buff;

				bool isBuffReady = block_rw.prepareReadBuffer(read_buff, partition_block, block_size);
				if(!isBuffReady){
					printf("[FH] Problem with using an already created buffer!\n");
				}
				else{
					printf("[FH] Column partition %d ready for FPGA!\n", part_id);

					block_rw.prepareWriteBuffer((volatile void*&) write_buff, wr_buff_size);

					printf("[FH] Sending buffer addresses to the FPGA ...\n");
					int total_cls = block_size / 64;
					block_rw.sendQueryParams(total_cls, filter_pred);
					block_rw.setFunctionType((int) AFU_TYPE::FILTER_SCAN);

					block_rw.shareBuffVA(2, intptr_t(read_buff));
					block_rw.shareBuffVA(3, intptr_t(write_buff));

					printf("[FH] Waiting for FPGA response ...\n");
					block_rw.waitAndWriteResponse(total_cls);

					block_rw.freeBuffer((void *&) read_buff);
					block_rw.freeBuffer((void *&) write_buff);
				}

				//trigger join jobs after first scan completion
				//hardcode a bit_map vector representing the date items for now
			}
			block_rw.notifyFPGA(1);
		}
	}

	void siliconDB(ScanApi *& scanJob){
		int total_parts = scanJob->TotalPartitions();
		uint32_t filter_pred = scanJob->FilterPredicate();

		printf("\n[FH] --> Column scan is starting (pred: %u) ...\n", filter_pred);
		printf("[FH] --> Total partitions to process: %d\n\n", total_parts);

		size_t block_size = PAGE_SIZE;
		int total_cls = block_size / 64;

		int bit_encoding = BIT_ENCODING::_16_BITS;

		block_rw.sendQueryParams(total_cls, filter_pred, bit_encoding);
		block_rw.setParallelism(3, parallel_units);

		while(this->fpga_queue->isNotEmpty()){
			Node *work_unit = this->fpga_queue->nextElement();
			int part_id = work_unit->value.getPart();

			printf("\n+++++++++++++++++++++++++++++++\n\n");
			printf("\n---- Partition %d !\n", part_id);
			block_rw.printRegisterValues();

			volatile void* read_buff = read_buffers[part_id];
			volatile void* write_buff = write_buffers[part_id];

			block_rw.shareBuffVA(4, intptr_t(read_buff));
			block_rw.shareBuffVA(5, intptr_t(write_buff));

			// CONTINUE: HANDLE MAIN-MEMORY READS FOR FILTER-RESULT VECTORS
			block_rw.waitForProcessing(total_cls, write_buff);

			printf("\n\n+++++++++++++++++++++++++++++++\n\n");
			//block_rw.printPartitionResult(write_buff, total_cls);

			//this->thr_sync->decrementAggCounter();
		}

		block_rw.notifyFPGA(1);

		int filter_count = 0;
		for(auto buff : write_buffers){
			//filter_count += block_rw.printPartitionResult(buff, total_cls);
			filter_count += block_rw.getPartitionCount(buff, total_cls);
		}
		printf("\n \t [FH] Filter Count: %d \n\n", filter_count);
	}

	void joinPipeline() {
		printf("[FH] Starting the join pipeline...\n");

        int total_parts = this->lineorder_date->TotalPartitions();
        void* bit_map = (void *) this->d_year->BitResult();
        volatile void* bit_map_buff;

		printf("[FH] Total partitions to process: %d\n", total_parts);

		//printBitMap((uint8_t *) bit_map);

        size_t block_size = 4096;

        BLOCK_RW block_rw;
		block_rw.connectToAccelerator();

		if(!block_rw.isAFUOK()){
			printf("[FH] Problem connecting to the AFU!\n");
		}
		else{
			block_rw.connectToCSRManager();

			bool isBuffReady = block_rw.prepareReadBuffer(bit_map_buff, bit_map, block_size);
			if(!isBuffReady){
				printf("[FH] Problem with BitMap buffer!\n");
			}
			else{
				block_rw.registerBitMapIntoFPGA(bit_map, 2556);
			}

			for(int part_id = 0; part_id < 1; part_id++){
				printf("[FH] Preparing read/write buffers for partition %d ...\n", part_id);

				void* fk_block = retriveFKBlock(lineorder_date, part_id);

				size_t wr_buff_size = block_size; //need block_size bits
				printf("[FH]  Write block size: %d\n", (int) wr_buff_size);

				volatile void* read_buff;

				volatile uint64_t* write_buff;

				bool isBuffReady = block_rw.prepareReadBuffer(read_buff, fk_block, block_size);
				if(!isBuffReady){
					printf("[FH] Problem with FK read buffer!\n");
				}
				else{
					printf("[FH] FK column partition %d ready for FPGA!\n", part_id);

					block_rw.prepareWriteBuffer((volatile void*&) write_buff, wr_buff_size);

					printf("[FH] Sending buffer addresses to the FPGA ...\n");
					int total_cls = block_size / 64 / 4;
					block_rw.setParallelism(3, parallel_units);
					block_rw.setFunctionType((int) AFU_TYPE::JOIN);

					block_rw.shareBuffVA(2, intptr_t(read_buff));
					block_rw.shareBuffVA(3, intptr_t(write_buff));

					printf("[FH] Waiting for FPGA response ...\n");
					block_rw.waitAndWriteResponse(total_cls);

					block_rw.freeBuffer((void *&) read_buff);
					block_rw.freeBuffer((void *&) write_buff);
				}

				//trigger join jobs after first scan completion
				//hardcode a bit_map vector representing the date items for now
			}
			block_rw.notifyFPGA(1);
		}

	}

	PARALLELISM parallel_units = PARALLELISM::_128_WAY;

	BLOCK_RW block_rw;

public:
	FPGAHandler(Syncronizer *sync, EXEC_TYPE e_type, int thr_id, PARALLELISM parallel_units) :
		ThreadHandler(sync, e_type, thr_id) {
		this->parallel_units = parallel_units;
	}

	inline void executeScan(Node *work_unit){
		int part_id = work_unit->value.getPart();

	}

	void *run() {
		this->thr_sync->waitOnStartBarrier();

		printf("[FH] FPGA Thread waiting on FPGA barrier!\n");
		this->fpga_queue->printQueue();
		printf("\n");

		if(!this->fpga_queue->isNotEmpty()){
			this->thr_sync->waitOnFPGABarrier();
			this->releaseAllBuffers(block_rw);
			printf("[FH] Buffers released!\n");
			this->thr_sync->waitOnEndBarrier();
			printf("[FH] FPGA Thread done!\n");

			return NULL;
		}

		ScanApi *&currScan = c_mktsegment;
		//ScanApi *&currScan = lo_quantity;
		//ScanApi *&currScan = lo_orderdate;

		if(!this->connectToFPGA()){
			printf("[FH] -- Problem with connecting to the FPGA Unit!\n");
		}
		else{
			printf("[FH] -- Preparing column partition buffers for FPGA!\n");
			this->prepareReadBuffersForFPGA(block_rw, currScan);
			this->prepareWriteBuffersForFPGA(block_rw, currScan);
			printf("[FH] -- Buffers ready for processing!\n");
		}

		this->thr_sync->waitOnFPGABarrier();

		this->siliconDB(currScan);
		//this->scanPipeline();
		//this->joinPipeline();

		printf("[FH] FPGA Thread done with the execution pipeline!\n");

		this->releaseAllBuffers(block_rw);

		printf("[FH] Buffers released!\n");

		this->thr_sync->waitOnEndBarrier();

		printf("[FH] FPGA Thread done!\n");

		return NULL;
	}

	bool connectToFPGA(){
		printf("[FH] Connection to AFU initializing...\n");
		block_rw.connectToAccelerator();
		printf("[FH] Connected to the AFU ...\n");
		if(!block_rw.isAFUOK()){
			printf("[FH] Problem connecting to the AFU!\n");
			return false;
		}
		else{
			block_rw.connectToCSRManager();
		}
		printf("[FH] -- Connection established!\n");
		return true;
	}

	void prepareReadBuffersForFPGA(BLOCK_RW &fpga_wrapper, ScanApi *&scanColumn){
		int block_size = PAGE_SIZE;
		volatile void* read_buff;
		for(int part_id = 0; part_id < scanColumn->TotalPartitions(); part_id++){
			void* partition_block = scanColumn->DataBlock(part_id);
			bool isOK = fpga_wrapper.prepareReadBuffer(read_buff, partition_block, block_size);
			if(isOK){
				read_buffers.push_back(read_buff);
			}
			else{
				printf("[FH] -- Problem with buffer allocation (part_id: %d)\n", part_id);
			}
		}
		printf("[FH] -- %d read buffers (out of %d) in total ready for FPGA\n",
				read_buffers.size(), scanColumn->TotalPartitions());
	}

	void prepareWriteBuffersForFPGA(BLOCK_RW &fpga_wrapper, ScanApi *&scanColumn){
		int block_size = PAGE_SIZE;
		volatile void* write_buff;
		for(int part_id = 0; part_id < scanColumn->TotalPartitions(); part_id++){
			fpga_wrapper.prepareWriteBuffer(write_buff, block_size);
			write_buffers.push_back(write_buff);
		}
		printf("[FH] -- %d write buffers (out of %d) in total ready for FPGA\n",
				write_buffers.size(), scanColumn->TotalPartitions());
	}

	void releaseAllBuffers(BLOCK_RW &fpga_wrapper){
		for(auto &buff : read_buffers){
			fpga_wrapper.freeBuffer((void *&) buff);
		}

		for(auto &buff : write_buffers){
			fpga_wrapper.freeBuffer((void *&) buff);
		}
	}

	void* retriveScanBlock(ScanApi *& scanColumn, int part_id){
		return scanColumn->DataBlock(part_id);
	}

	void* retriveFKBlock(JoinApi *& join, int part_id){
		return join->DataBlock(part_id); //?
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
