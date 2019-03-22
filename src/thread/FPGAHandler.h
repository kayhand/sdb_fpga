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

#include "fpga/operators/mem_rw/sw/mem_rw.h"
#include "fpga/operators/read_pred/sw/read_pred.h"
#include "fpga/operators/read_block/sw/read_block.h"

class FPGAHandler: public ThreadHandler {

	void siliconDB() {}
	void opAtaTime() {}

public:
	FPGAHandler(Syncronizer *sync, EXEC_TYPE e_type, int thr_id) :
		ThreadHandler(sync, e_type, thr_id) {}

	void *run() {
		JOB_TYPE j_type = C_SCAN;
		uint32_t filter_pred = this->scanAPI->FilterPredicate();

		this->thr_sync->waitOnStartBarrier();

		READ_BLOCK read_block_op;
		read_block_op.connectToAccelerator();
		if(!read_block_op.isAFUOK()){
			printf("Problem connecting to the AFU!\n");
		}
		else{
			read_block_op.connectToCSRManager();

			for(int part_id = 0; part_id < 1; part_id++){

				printf("Preparing read/write buffers for partition %d ...\n", part_id);

				size_t block_size;
				void* data_block = initializeBuffers(part_id, data_block, block_size);

				//size_t wr_buff_size = block_size / 8; //need block_size bits
				size_t wr_buff_size = block_size; //need block_size bits

				printf("SDB read block size: %d", (int) block_size);
				printf(" and write block size: %d\n", (int) wr_buff_size);

				volatile void* read_buff;
				volatile uint64_t* write_buff;

				//bool isBuffReady = read_block_op.registerReadBuffer(data_block, block_size);
				bool isBuffReady = read_block_op.prepareReadBuffer(read_buff, data_block, block_size);

				if(!isBuffReady){
					printf("Problem with using an already created buffer!\n");
				}
				else{
					printf("Column partition %d ready for FPGA!\n", part_id);

					read_block_op.prepareWriteBuffer((volatile void*&) write_buff, wr_buff_size);

					printf("Sending buffer addresses to the FPGA ...\n");
					int total_cls = block_size / 64;
					read_block_op.sendQueryParams(total_cls , filter_pred);

					read_block_op.shareBuffVA(2, intptr_t(read_buff));
					read_block_op.shareBuffVA(3, intptr_t(write_buff));

					printf("Waiting for FPGA response ...\n");
					read_block_op.waitAndWriteResponse(total_cls, write_buff);

					read_block_op.printVTPStats();

					read_block_op.freeBuffer((void *&) read_buff);
					read_block_op.freeBuffer((void *&) write_buff);
				}
			}
			read_block_op.notifyFPGA(1);
		}

		this->thr_sync->waitOnEndBarrier();

		return NULL;
	}

	void* initializeBuffers(int part_id, void *& partition_block, size_t &block_size){
		return this->scanAPI->DataBlock(part_id, block_size);
	}

};

#endif
