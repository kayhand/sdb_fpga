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
#include "thread/FPGAHandler.h"

#include "util/Query.h"
#include "exec/util/WorkQueue.h"
#include "thread/Syncronizer.h"

#include "api/ScanApi.h"

class ProcessingUnit{
    std::vector<CoreHandler*> coreHandlers;
    FPGAHandler *fpgaHandler = NULL;

    int numOfComputeUnits = 1;

    WorkQueue scanQueue;
    WorkQueue joinQueue;

    WorkQueue fpgaQueue;

    ScanApi* lo_dsc_scan = NULL;
    ScanApi* lo_qty_scan = NULL;
    ScanApi* lo_odate_scan = NULL;
    ScanApi* d_scan = NULL;
    ScanApi* c_scan = NULL;

    JoinApi* join = NULL;

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

    void createProcessingUnit(Syncronizer*, PARALLELISM);

    void setScans(ScanApi *scan1, ScanApi *scan2, ScanApi *scan3, ScanApi *scan4, ScanApi *scan5){
    	this->lo_dsc_scan = scan1;
    	this->lo_qty_scan = scan2;
    	this->lo_odate_scan = scan3;
    	this->d_scan = scan4;
    	this->c_scan = scan5;
    }

    void setJoin(JoinApi *join){
    	this->join = join;
    }

    void addScanItems(int num_of_parts, JOB_TYPE j_type);
    void addJoinItems(int num_of_parts, JOB_TYPE j_type);

    void addWorkItems(ScanApi *&scanApi, WorkQueue &queue);

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
