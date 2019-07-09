#ifndef __processing_unit_h__
#define __processing_unit_h__

#include <stdio.h>
#include <stdlib.h>
#include <string>
#include <vector>
#include <fcntl.h>
#include <unistd.h>

#include "thread/Thread.h"
#include "thread/ThreadHandler.h"
#include "thread/CoreHandler.h"

#ifdef __FPGA__
#include "thread/FPGAHandler.h"
#endif

#include "util/Query.h"
#include "exec/util/WorkQueue.h"
#include "thread/Syncronizer.h"

#include "api/ScanApi.h"

class ProcessingUnit{
    std::vector<CoreHandler*> coreHandlers;

#ifdef __FPGA__
    FPGAHandler *fpgaHandler = NULL;
#endif

    int numOfComputeUnits = 1;

    WorkQueue scanQueue;
    WorkQueue joinQueue;

    WorkQueue fpgaQueue;

    ScanApi* lo_dsc_scan = NULL;
    ScanApi* lo_qty_scan = NULL;
    ScanApi* lo_odate_scan = NULL;
    ScanApi* d_scan = NULL;
    ScanApi* c_scan = NULL;

    JoinApi* lo_date_join = NULL;

    EXEC_TYPE sched_approach = EXEC_TYPE::SDB;

    public: 
        ProcessingUnit(int);
        ~ProcessingUnit();

    WorkQueue &ScanQueue(){
    	return this->scanQueue;
    }

    WorkQueue &FPGAQueue(){
    	return this->fpgaQueue;
    }

    void createProcessingUnit(Syncronizer*);

    void createProcessingUnit(Syncronizer*, PARALLELISM);

    void createColumnParser(RawScan *rawScan){
    	for(CoreHandler *c_handler : coreHandlers){
    		c_handler->setRawScan(rawScan);
    	}
    }

    void createColumnScan(Column *scanColumn){
    	if(scanColumn->ColName() == COLUMN_NAME::LO_DISCOUNT){
    		uint32_t lo_disc_pred1 = scanColumn->CompressValue("1");
    		uint32_t lo_disc_pred2 = scanColumn->CompressValue("3");
    		lo_dsc_scan = new ScanApi(JOB_TYPE::LO_DISC_SCAN, scanColumn, GE_LE, lo_disc_pred1);
    		lo_dsc_scan->setUpperParam(lo_disc_pred2);
    		lo_dsc_scan->initializeScanOperator();
    	}
    	else if(scanColumn->ColName() == COLUMN_NAME::LO_QUANTITY){
    		uint32_t lo_qty_pred = scanColumn->CompressValue("24");
    		lo_qty_scan = new ScanApi(JOB_TYPE::LO_QUANTITY_SCAN, scanColumn, LE, lo_qty_pred);
    		lo_qty_scan->initializeScanOperator();
    	}
    	else if(scanColumn->ColName() == COLUMN_NAME::D_YEAR){
    		uint32_t d_pred = scanColumn->CompressValue("1993");
    		d_scan = new ScanApi(JOB_TYPE::D_YEAR_SCAN, scanColumn, EQ, d_pred);
    		d_scan->initializeScanOperator();
    	}
    }

    void createSemiJoin(Column *fkColumn, uint64_t** bit_map){
    	lo_date_join = new JoinApi(JOB_TYPE::LO_DATE_JOIN, fkColumn, bit_map,
    			this->d_scan->BaseColumn()->ColSize());
    	lo_date_join->initializeJoinOperator();
    }

    uint64_t** getScanResult(JOB_TYPE scan_job){
    	if(scan_job == D_YEAR_SCAN)
    		return this->d_scan->BitResult();
    	else
    		return NULL;
    }

    void addScanItems(int num_of_parts, JOB_TYPE j_type);
    void addJoinItems(int num_of_parts, JOB_TYPE j_type);

    void addWorkItems(ScanApi *&scanApi, WorkQueue &queue);

    void addWorkItems(Column *scanColumn, JOB_TYPE j_type, WorkQueue &queue){
    	//for(int p_id = 0; p_id < 1; p_id++){
    	for(int p_id = 0; p_id < scanColumn->NumOfPartitions() - 1; p_id++){
    		Query item(0, p_id, j_type);
    		Node *newNode = new Node(item);
    		queue.add(newNode);
    	}

    }

    void initWorkQueues(int, JOB_TYPE);

    void printWorkQueue(WorkQueue &queue){
    	queue.printQueue();
    }

    void printJoinQueue(){
    	this->joinQueue.printQueue();
    }

    void startThreads(TCPStream*);
    void joinThreads();

};

#endif
