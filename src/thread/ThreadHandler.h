#ifndef __threadhandler_h__
#define __threadhandler_h__

#include <pthread.h>
#include <vector>
#include <atomic>

#include "Thread.h"
#include "Syncronizer.h"

#include "exec/util/WorkQueue.h"
#include "network/server/TCPAcceptor.h"

#include "api/ScanApi.h"

enum EXEC_TYPE {
	SDB = 1,
	OAT,
	DD ,

	JOIN_RW,
	AGG_RW,

	QT_MICRO
};

class ThreadHandler : public Thread {
protected:
	Syncronizer* thr_sync;
	EXEC_TYPE eType;
	int thr_id = -1;

	WorkQueue* shared_queue = NULL;
	WorkQueue* hw_queue = NULL;
	WorkQueue* sw_queue = NULL;

	TCPStream* t_stream = NULL;

	ScanApi *scanAPI = NULL;

	virtual void siliconDB() = 0;
	virtual void opAtaTime() = 0;

public:
	ThreadHandler(Syncronizer *sync, EXEC_TYPE e_type, int thr_id) {
		this->thr_sync = sync;
		this->eType = e_type;
		this->thr_id = thr_id;

	}

	int getId() {
		return this->thr_id;
	}

	void addNewJob(int r_id, int p_id, JOB_TYPE j_type, WorkQueue *queue) {
		Node *newNode = this->returnNextNode(r_id, p_id, j_type);
		queue->add(newNode);
	}

	void setStream(TCPStream *stream) {
		t_stream = stream;
	}

	void setQueues(WorkQueue *shared_queue, WorkQueue *sw_queue, WorkQueue *hw_queue) {
		this->shared_queue = shared_queue;
		this->sw_queue = sw_queue;
		this->hw_queue = hw_queue;
	}

	void setAPI(ScanApi* scanAPI) {
		this->scanAPI = scanAPI;
	}

};

#endif
