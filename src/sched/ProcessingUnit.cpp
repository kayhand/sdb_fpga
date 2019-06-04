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
	for (CoreHandler* curHandler : coreHandlers)
		delete curHandler;
	delete fpgaHandler;

	//delete scanQueue.getHead();
	//delete joinQueue.getHead();

	delete lo_dsc_scan;
	delete lo_qty_scan;
	delete d_scan;
	delete c_scan;

	delete join;
}

void ProcessingUnit::createProcessingUnit(Syncronizer *thr_sync, PARALLELISM parallel_units){
	fpgaHandler = new FPGAHandler(thr_sync, sched_approach, 0, parallel_units);

	fpgaHandler->setQueues(&scanQueue, &joinQueue);
	fpgaHandler->setFPGAQueue(&fpgaQueue);

	fpgaHandler->setScanAPIs(lo_dsc_scan, lo_qty_scan, lo_odate_scan, d_scan, c_scan);
	fpgaHandler->setJoinAPI(join);

	for (int i = 1; i < numOfComputeUnits; i++) {
		CoreHandler *handler = new CoreHandler(thr_sync, sched_approach, i);

		handler->setQueues(&scanQueue, &joinQueue);

		handler->setScanAPIs(lo_dsc_scan, lo_qty_scan, lo_odate_scan, d_scan, c_scan);
		handler->setJoinAPI(join);

		coreHandlers.push_back(handler);
	}
}

void ProcessingUnit::addScanItems(int num_of_parts, JOB_TYPE scan_job){
	for (int p_id = 0; p_id < num_of_parts; p_id++) {
		Query item(0, p_id, scan_job); //(0: sw - 1:hw, part_id, table_id)
		Node *newNode = new Node(item);
		scanQueue.add(newNode);
	}
}

void ProcessingUnit::addJoinItems(int num_of_parts, JOB_TYPE join_job){
	for (int p_id = 0; p_id < num_of_parts; p_id++) {
		Query item(0, p_id, join_job); //(0: sw - 1:hw, part_id, table_id)
		Node *newNode = new Node(item);
		joinQueue.add(newNode);
	}
}

void ProcessingUnit::addWorkItems(ScanApi *&baseScan, WorkQueue &queue){
	for (int p_id = 0; p_id < baseScan->TotalPartitions(); p_id++) {
	//for (int p_id = 0; p_id < 1; p_id++) {
		Query item(0, p_id, baseScan->JobType());
		Node *newNode = new Node(item);
		queue.add(newNode);
	}
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
