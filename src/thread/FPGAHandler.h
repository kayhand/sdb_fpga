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

#include "fpga/operators/read_pred/sw/read_pred.h"

class FPGAHandler: public ThreadHandler {

	void siliconDB() {}
	void opAtaTime() {}

public:
	FPGAHandler(Syncronizer *sync, EXEC_TYPE e_type, int thr_id) :
		ThreadHandler(sync, e_type, thr_id) {}

	void *run() {
		JOB_TYPE j_type = C_SCAN;
		this->thr_sync->waitOnStartBarrier();

		READ_PRED read_pred_op(Types::getAclId(j_type));

		read_pred_op.writePredicate(this->scanAPI->FilterPredicate());
		read_pred_op.waitAndWriteResponse();

		/*
		//1) Connect to the accelerator and 2) csrs manager
		MEMORY_RW mem_rw_op(Types::getAclId(j_type));

		//3) Allocate a single page memory buffer
		mem_rw_op.allocateBuffer(getpagesize());
		//4) Send the address of the buffer to the accelerator over CSR
		mem_rw_op.notifyAccelerator();
		//5) Wait for the accelerator to write into the buffer
		mem_rw_op.waitAndWriteResponse();
		*/

		this->thr_sync->waitOnEndBarrier();

		return NULL;
	}

};

#endif

