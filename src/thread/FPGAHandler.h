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
#include "fpga/fpga.h"

class FPGAHandler: public ThreadHandler {

	void siliconDB() {}
	void opAtaTime() {}

	FPGA fpga;
	JOB_TYPE j_type;

public:
	FPGAHandler(Syncronizer *sync, EXEC_TYPE e_type, int thr_id) :
		ThreadHandler(sync, e_type, thr_id) {
		j_type = C_SCAN;
	}

	void *run() {
		this->thr_sync->waitOnStartBarrier();

		fpga.connect(j_type);
		printf("Connected to the accelerator for scan operator!\n");

		fpga.alloc_buffer(getpagesize());

		fpga.notifyFPGA();
		fpga.waitForFPGA();

		fpga.close();

		this->thr_sync->waitOnEndBarrier();

		return NULL;
	}

};

#endif

