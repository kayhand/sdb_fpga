#ifndef __core_handler_h__
#define __core_handler_h__

#include <pthread.h>
#include <vector>
#include <atomic>

#include "Thread.h"
#include "ThreadHandler.h"
#include "Syncronizer.h"

#include "exec/util/WorkQueue.h"
#include "network/server/TCPAcceptor.h"

#include "api/ScanApi.h"

class CoreHandler : public ThreadHandler {

	void scanPipeline() {
		printf("[CH] CPU CORE starting to process scan items!\n");

		Node *work_unit;
		int part_id;
		//while (!this->thr_sync->isQueryDone()) {
			while(this->scan_queue->isNotEmpty()){
				work_unit = this->scan_queue->nextElement();
				executeItem(work_unit);
			}
		//}

		printf("[CH] CPU CORE finished processing the date year pipeline!\n");
	}

	void joinPipeline() {}

	void siliconDB(ScanApi *&scanJob) {}

	int lo_dsc_count = 0;
	int lo_qty_count = 0;
	int lo_odate_count = 0;
	int d_year_count = 0;
	int c_mktsegment_count = 0;

public:
	CoreHandler(Syncronizer *sync, EXEC_TYPE e_type, int thr_id) :
		ThreadHandler(sync, e_type, thr_id) {}

	void *run() {
		this->thr_sync->waitOnStartBarrier();

		this->scanPipeline();

		//printf("[CH] \nDate Year Count: %d\n", d_year_count);
		printf("[CH] Customer Segment Count: %d\n\n", c_mktsegment_count);
		//printf("[CH] Lineorder Discount Count: %d\n\n", lo_dsc_count)
		//printf("[CH] Lineorder Discount Count: %d\n\n", lo_odate_count);

		printf("[CH] CPU Thread waiting on FPGA barrier!\n");
		this->thr_sync->waitOnFPGABarrier();

		printf("[CH] CPU Thread waiting on end barrier!\n");
		this->thr_sync->waitOnEndBarrier();
		printf("[CH] CPU Thread Done!\n");

		return NULL;
	}

	inline void executeItem(Node *work_unit){
		if(work_unit == NULL){
			return;
		}
		else{
			if(work_unit->value.getJobType() == JOB_TYPE::D_YEAR_SCAN){
				d_year_count += this->d_year->simdScan8(work_unit);
			}
			else if(work_unit->value.getJobType() == JOB_TYPE::C_MKTSEGMENT_SCAN){
				c_mktsegment_count += this->c_mktsegment->simdScan4(work_unit);
			}
			else if(work_unit->value.getJobType() == JOB_TYPE::LO_DISC_SCAN){
				lo_dsc_count += this->lo_discount->simdScan8(work_unit);
			}
			else if(work_unit->value.getJobType() == JOB_TYPE::LO_ORDERDATE_SCAN){
				lo_odate_count += this->lo_orderdate->simdScan16(work_unit);
			}
			handleJobReturn(work_unit);

			//this->putFreeNode(work_unit);

			//executeDateScan(work_unit);
			//handleJobReturn(work_unit);
		}
	}

	inline void executeLODiscScan(Node *work_unit){
		this->lo_discount->simdScan8(work_unit);
	}

	inline void executeLOQtyScan(Node *work_unit){
		this->lo_quantity->simdScan8(work_unit);
	}

	inline void executeDateScan(Node *work_unit){
		this->d_year->simdScan8(work_unit);
	}

	inline void handleJobReturn(Node *work_unit){
		//this->thr_sync->decrementAggCounter();
		this->putFreeNode(work_unit);
	}

};

#endif
