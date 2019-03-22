#include <stdio.h>
#include <stdlib.h>
#include <string>
#include <vector>
#include <fcntl.h>
#include <unistd.h>
#include <sys/wait.h>
#include <istream>

#include "data/Table.h"
#include "api/ScanApi.h"

#include "sched/ProcessingUnit.h"

int main(int argc, char** argv) {
	std::string data_path = argv[1]; // ~/data/ssb/
	int partition_size = atoi(argv[2]);
	int num_of_cores = atoi(argv[3]); //including the FPGA Handler

	Table customer("customer");
	customer.initializeTable(data_path + "customer/"); // ~/data/ssb/customer/
	//int num_of_partitions = customer.NumOfElements() / partition_size; //(30000 / 15000)
	//printf("Number of partitions: %d\n", num_of_partitions);

	Column *c_mktsegment = new Column("c_mktsegment", customer.NumOfElements());
	c_mktsegment->initializeColumn(customer.Path() + "c_mktsegment/"); // ~/data/ssb/customer/c_mktsegment/
	//c_mktsegment->initializePartitions(num_of_partitions, partition_size);
	int num_of_partitions = c_mktsegment->initializePageAlignedPartitions(4096);
	c_mktsegment->compressColumn();

	customer.addColumn(c_mktsegment);

	uint32_t comp_val = c_mktsegment->CompressValue("FURNITURE");
	ScanApi *scan = new ScanApi(c_mktsegment, EQ, comp_val);
	scan->initializeScanOperator(customer.NumOfElements());

	//Synchronization: Init params
	Syncronizer thr_sync;
	thr_sync.initBarriers(num_of_cores);
	thr_sync.initAggCounter(num_of_partitions);

	ProcessingUnit pu(num_of_cores);
	pu.initializeScan(scan);

	pu.createProcessingUnit(&thr_sync);
	pu.initWorkQueues(1);

	pu.startThreads(NULL);
	pu.joinThreads();

	printf("Threads returned!\n");

	thr_sync.destroyBarriers();

	return 0;
}
