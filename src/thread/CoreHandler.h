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
#include "api/RawScan.h"

#include "data/RawTable.h"

class CoreHandler : public ThreadHandler {

	void scanAtATime(ScanApi *&scanJob) {
		std::cout << scanJob->FilterPredicate() << std::endl;

		int part_id = 0;
		hrtime_t start = gethrtime();
		while(this->scan_queue->isNotEmpty()){
			Node *work_unit = this->scan_queue->nextElement();
			lo_qty_count += scanJob->simdScan8(part_id);
			this->putFreeNode(work_unit);
			part_id++;
		}
		hrtime_t end = gethrtime();

		double micro_secs = (double) (end - start) / 1000.0;
		std::cout << "Took " << micro_secs << " microseconds " << std::endl;
	}

	void joinAtATime(JoinApi *&joinJob) {}


	void processAtt(char *input_cl, int start, int end){
		for(int char_id = start; char_id < end; char_id++){
			printf("%c", input_cl[char_id]);
		}
		printf("\n");
	}

	void processTuple(char *input_cl, int start, int end){
		int att_id = 0;
		int att_start = start;
		int att_end = start;

		for(int char_id = start; char_id < end; char_id++){
			printf("%c", input_cl[char_id]);
		}
		printf("\n\n");

		for(int char_id = start; char_id < end; char_id++){
			if(input_cl[char_id] == '|'){
				att_end = char_id;

				printf("        Att %d: (%d - %d) ", att_id++,
						att_start, att_end);
				processAtt(input_cl, att_start, att_end);
				att_start = att_end + 1;
			}
		}

		std::cout << "" << std::endl;
	}

	void processRawData(){
		int total_cls = 1;
		RawTable *rawTable = rawScan->RawInput();
		while(rawTable->moreChunks()){
			rawTable->mapNextChunk();

			rawScan->processChunk(total_cls);

			rawTable->releaseMappedChunk();
		}
	}

	int lo_dsc_count = 0;
	int lo_qty_count = 0;
	int lo_odate_count = 0;
	int d_year_count = 0;
	int c_mktsegment_count = 0;

	RawScan *rawScan = NULL;

public:
	CoreHandler(Syncronizer *sync, EXEC_TYPE e_type, int thr_id) :
		ThreadHandler(sync, e_type, thr_id) {}

	void setRawScan(RawScan *raw_scan){
		this->rawScan = raw_scan;
	}

	void *run() {
		this->thr_sync->waitOnStartBarrier();

		if(thr_id == 0)
			this->processRawData();

		//this->scanAtATime(lo_quantity);

		//printf("[CH] \nDate Year Count: %d\n", d_year_count);
		//printf("[CH] Customer Segment Count: %d\n\n", c_mktsegment_count);
		//printf("[CH] Lineorder Discount Count: %d\n\n", lo_dsc_count)
		printf("[CH] Lineorder Quantity Count: %d\n\n", lo_qty_count);

		printf("[CH] CPU Thread waiting on FPGA barrier!\n");
		this->thr_sync->waitOnFPGABarrier();

		printf("[CH] CPU Thread waiting on end barrier!\n");
		this->thr_sync->waitOnEndBarrier();
		printf("[CH] CPU Thread Done!\n");

		return NULL;
	}

	/*
	inline void executeItem(Node *work_unit){
		if(work_unit == NULL){
			return;
		}
		else{
			if(work_unit->value.getJobType() == JOB_TYPE::D_YEAR_SCAN){
				d_year_count += this->d_year->simdScan8(work_unit);
			}
			else if(work_unit->value.getJobType() == JOB_TYPE::C_MKTSEGMENT_SCAN){
				//c_mktsegment_count += this->c_mktsegment->simdScan4(work_unit);
			}
			else if(work_unit->value.getJobType() == JOB_TYPE::LO_DISC_SCAN){
				lo_dsc_count += this->lo_discount->simdScan8(work_unit);
			}
			else if(work_unit->value.getJobType() == JOB_TYPE::LO_DATE_JOIN){
				//lo_odate_count += this->lo_orderdate->simdScan16(work_unit);
			}
			handleJobReturn(work_unit);

			//this->putFreeNode(work_unit);

			//executeDateScan(work_unit);
			//handleJobReturn(work_unit);
		}
	}
	*/

	/*inline void executeLODiscScan(Node *work_unit){
		this->lo_discount->simdScan8(work_unit);
	}

	inline void executeLOQtyScan(Node *work_unit){
		this->lo_quantity->simdScan8(work_unit);
	}

	inline void executeDateScan(Node *work_unit){
		this->d_year->simdScan8(work_unit);
	}*/

	inline void handleJobReturn(Node *work_unit){
		//this->thr_sync->decrementAggCounter();
		this->putFreeNode(work_unit);
	}

};

#endif
