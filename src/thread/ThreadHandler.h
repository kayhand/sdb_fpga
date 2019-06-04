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
#include "api/JoinApi.h"

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

	WorkQueue* scan_queue = NULL;
	WorkQueue* join_queue = NULL;

	WorkQueue* fpga_queue = NULL;

	TCPStream* t_stream = NULL;

	ScanApi *lo_discount = NULL;
	ScanApi *lo_quantity = NULL;
	ScanApi *lo_orderdate = NULL;
	ScanApi *d_year = NULL;
	ScanApi *c_mktsegment = NULL;

	JoinApi *lineorder_date = NULL;

	virtual void scanPipeline() = 0;
	virtual void joinPipeline() = 0;

	virtual void siliconDB(ScanApi *&) = 0;

	vector<volatile void*> read_buffers;
	vector<volatile void*> write_buffers;

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

	void setQueues(WorkQueue *queue1, WorkQueue *queue2) {
		this->scan_queue = queue1;
		this->join_queue = queue2;
	}

	void setFPGAQueue(WorkQueue *queue){
		this->fpga_queue = queue;
	}

	void setScanAPIs(ScanApi* scan1, ScanApi* scan2, ScanApi* scan3, ScanApi* scan4, ScanApi* scan5) {
		this->lo_discount = scan1;
		this->lo_quantity = scan2;
		this->lo_orderdate = scan3;
		this->d_year = scan4;
		this->c_mktsegment = scan5;
	}

	void setJoinAPI(JoinApi* join){
		this->lineorder_date = join;
	}

};

#endif
