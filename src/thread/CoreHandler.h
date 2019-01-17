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

class CoreHandler: public ThreadHandler {
	void siliconDB() {
		Node *work_unit;
		while (!this->thr_sync->isQueryDone()) {
			if (this->sw_queue->isNotEmpty()) {
				work_unit = this->sw_queue->nextElement();
				this->executeItem(work_unit);
			}
			else if (this->shared_queue->isNotEmpty()) {
				work_unit = this->shared_queue->nextElement();
				this->executeItem(work_unit);
			}
		}
	}

	void opAtaTime() {
		Node *work_unit;
		while (!this->thr_sync->isQueryDone()) {
			if (this->sw_queue->isNotEmpty()) {
				work_unit = this->sw_queue->nextElement();
				this->executeItem(work_unit);
			}
		}
	}

public:
	CoreHandler(Syncronizer *sync, EXEC_TYPE e_type, int thr_id) :
		ThreadHandler(sync, e_type, thr_id) {}

	void *run() {
		this->thr_sync->waitOnStartBarrier();

		if ((this->eType & SDB) == EXEC_TYPE::SDB) {
			this->siliconDB();
		} else if ((this->eType & OAT) == EXEC_TYPE::OAT) {
			this->opAtaTime();
		}
		this->thr_sync->waitOnEndBarrier();
		printf("Done...\n");
		//this->t_stream->send("", 0);
		return NULL;
	}

	inline void executeItem(Node *work_unit){
		if(work_unit == NULL){
			return;
		}
		else{
			executeScan(work_unit);
			handleJobReturn(work_unit);
		}
	}

	inline void executeScan(Node *work_unit){
		this->scanAPI->simdScan8(work_unit);
	}

	inline void handleJobReturn(Node *work_unit){
		this->thr_sync->incrementAggCounter();
		this->putFreeNode(work_unit);
	}

};

#endif

