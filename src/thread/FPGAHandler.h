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
		this->thr_sync->waitOnStartBarrier();

		/*
		//READ_PRED read_pred_op(Types::getAclId(j_type));
		READ_PRED read_pred_op;
		if(read_pred_op.isAccOK()){
			read_pred_op.writePredicate(this->scanAPI->FilterPredicate());
			read_pred_op.waitAndWriteResponse();
		}
		else{
			printf("Accelerator not found!\n");
		}*/

		//READ_BLOCK read_block_op(Types::getAclId(j_type));
		READ_BLOCK read_block_op;

		read_block_op.connectToAccelerator();
		if(!read_block_op.isAFUOK()){
			printf("Problem connecting to the AFU!\n");
		}
		else{
			read_block_op.connectToCSRManager();

			//size_t block_size;
			//void *data_block = (void*) this->scanAPI->DataBlock(0, block_size);
			int buff_size = getpagesize();

			printf("Preparing read/write buffers each having %d ... \n", buff_size);
			volatile void* read_buff;
			volatile uint64_t* write_buff;

			bool res = read_block_op.prepareReadBuffer(read_buff, buff_size);
			if(!res){
				printf("Problem with creating the read buffer!\n");
			}
			else{
				read_block_op.prepareWriteBuffer((volatile void*&) write_buff, buff_size);

				printf("Sending buffer addresses to the FPGA ...\n");
				read_block_op.shareDataBlock();

				printf("Waiting for FPGA response ...\n");
				read_block_op.waitAndWriteResponse(write_buff);
			}
		}

		/*
		//1) Connect to the accelerator and 2) csrs manager
		MEMORY_RW mem_rw_op;

		//3) Allocate a single page memory buffer
		mem_rw_op.allocateBuffer(getpagesize());
		printf("Buffer allocated!\n");
		//4) Send the address of the buffer to the accelerator over CSR
		mem_rw_op.notifyAccelerator();
		printf("Accelerator notified!\n");
		//5) Wait for the accelerator to write into the buffer
		mem_rw_op.waitAndWriteResponse();
		printf("Accelerator returned!\n");
		*/

		this->thr_sync->waitOnEndBarrier();

		return NULL;
	}

};

#endif
