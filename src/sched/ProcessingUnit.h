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

    WorkQueue sharedQueue;
    WorkQueue swQueue;
    WorkQueue hwQueue;

    ScanApi* scanApi = NULL;

    EXEC_TYPE sched_approach = EXEC_TYPE::SDB;

    public: 
        ProcessingUnit(int);
        ~ProcessingUnit();

    void createProcessingUnit(Syncronizer*);


    void initializeScan(ScanApi *scan){
    	this->scanApi = scan;
    }

    void addScanItems(int, JOB_TYPE, int, WorkQueue*);
    void initWorkQueues(int);

    void startThreads(TCPStream*);
    void joinThreads();

    WorkQueue* getSharedQueue(){
        return &sharedQueue;
    }

    WorkQueue* getSWQueue(){
        return &swQueue;
    }

    WorkQueue* getHWQueue(){
        return &hwQueue;
    }
};

#endif
