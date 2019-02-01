#include <stdio.h>
#include <stdlib.h>
#include <string>
#include <vector>
#include <fcntl.h>
#include <unistd.h>

#include "ProcessingUnit.h"

ProcessingUnit::ProcessingUnit(int num_of_cus) {
	this->numOfComputeUnits = num_of_cus;
}

ProcessingUnit::~ProcessingUnit() {
	delete fpgaHandler;
	for (CoreHandler* curHandler : coreHandlers)
		delete curHandler;

	delete scanApi;
}

void ProcessingUnit::createProcessingUnit(Syncronizer *thr_sync) {
	fpgaHandler = new FPGAHandler(thr_sync, sched_approach, 0);
	fpgaHandler->setAPI(this->scanApi);

	for (int i = 1; i < numOfComputeUnits; i++) {
		CoreHandler *handler = new CoreHandler(thr_sync, sched_approach, i);
		handler->setQueues(&sharedQueue, &swQueue, &hwQueue);
		handler->setAPI(this->scanApi);

		coreHandlers.push_back(handler);
	}
}

void ProcessingUnit::addScanItems(int total_parts, JOB_TYPE scan_job, int sf, WorkQueue *queue) {
	printf("Adding for table (id: %d), # of parts: %d\n", scan_job, total_parts);

	for (int i = 0; i < sf; i++) {
		for (int p_id = 0; p_id < total_parts; p_id++) {
			Query item(0, p_id, scan_job); //(0: sw - 1:hw, part_id, table_id)
			Node *newNode = new Node(item);
			queue->add(newNode);
		}
	}
}

void ProcessingUnit::initWorkQueues(int sf) {
	int num_of_parts = this->scanApi->BaseColumn()->NumOfPartitions();

	this->addScanItems(num_of_parts, C_SCAN, sf, getSharedQueue());

	printf("Scan Queue\n");
	getSharedQueue()->printQueue();
}

void ProcessingUnit::startThreads(TCPStream* connection) {
	for (CoreHandler *curHandler : coreHandlers) {
		curHandler->setStream(connection);
		curHandler->start(curHandler->getId(), false);
	}
	fpgaHandler->setStream(connection);
	fpgaHandler->start(fpgaHandler->getId(), true);
}

void ProcessingUnit::joinThreads() {
	for (CoreHandler* curHandler : coreHandlers) {
		curHandler->join();
	}
	fpgaHandler->join();
}
