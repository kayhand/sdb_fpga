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
#include "api/JoinApi.h"

#include "sched/ProcessingUnit.h"

void SSBQ1(char **argv){
	std::string data_path = argv[1]; // ~/data/ssb/
	int num_of_cores = atoi(argv[2]); //including the FPGA Handler

	//0: 128-way, 1: 64-way, 2: 32-way, 3: 16-way
	//4: 8-way, 5: 4-way, 6: 2-way, 7: 1-way
	int fpga_parallelism = atoi(argv[3]);

	std::cout << "Data Path: " << data_path << std::endl;
	std::cout << "# of cores: " << num_of_cores << std::endl;
	std::cout << "Parallelism: " << fpga_parallelism << std::endl;

	/*
	 * LINEORDER
	 */
	Table lineorder("lineorder");
	lineorder.initializeTable(data_path + "lineorder/");

	Column *lo_discount = new Column("lo_discount", lineorder.NumOfElements());
	lo_discount->initializeColumn(lineorder.Path() + "lo_discount/");
	int num_of_partitions = lo_discount->initializePageAlignedPartitions();
	lo_discount->compressColumn();

	Column *lo_quantity = new Column("lo_quantity", lineorder.NumOfElements());
	lo_quantity->initializeColumn(lineorder.Path() + "lo_quantity/");
	num_of_partitions = lo_quantity->initializePageAlignedPartitions();
	lo_quantity->compressColumn();

	Column *lo_orderdate = new Column("lo_orderdate", lineorder.NumOfElements());
	lo_orderdate->initializeColumn(lineorder.Path() + "lo_orderdate/");
	num_of_partitions = lo_orderdate->initializePageAlignedPartitions();
	lo_orderdate->compressColumn();

	lineorder.addColumn(lo_discount);
	lineorder.addColumn(lo_quantity);
	lineorder.addColumn(lo_orderdate);

	printf("[M] # of lo_discount partitions: %d\n", lo_discount->NumOfPartitions());
	printf("[M] # of lo_quantity partitions: %d\n", lo_quantity->NumOfPartitions());
	printf("[M] # of lo_orderdate partitions: %d\n", lo_orderdate->NumOfPartitions());

	/*
	 * DATE
	 */
	Table date("date");
	date.initializeTable(data_path + "date/");

	Column *d_year = new Column("d_year", date.NumOfElements());
	d_year->initializeColumn(date.Path() + "d_year/");
	num_of_partitions = d_year->initializePageAlignedPartitions();
	d_year->compressColumn();

	date.addColumn(d_year);

	printf("[M] # of d_year partitions: %d\n", d_year->NumOfPartitions());

	/*
	 * CUSTOMER
	 */
	Table customer("customer");
	customer.initializeTable(data_path + "customer/");

	Column *c_mktsegment = new Column("c_mktsegment", customer.NumOfElements());
	c_mktsegment->initializeColumn(customer.Path() + "c_mktsegment/");
	num_of_partitions = c_mktsegment->initializePageAlignedPartitions();
	c_mktsegment->compressColumn();

	customer.addColumn(c_mktsegment);

	printf("[M] # of c_mktsegment partitions: %d\n", c_mktsegment->NumOfPartitions());

	/*
	 * CREATE SCAN PIPELINES
	 */

	//lo_discount <= 3
	uint32_t lo_pred1 = lo_discount->CompressValue("3");
	ScanApi *lo_scan1 = new ScanApi(lo_discount, LE, lo_pred1, LO_DISC_SCAN);
	lo_scan1->initializeScanOperator(lineorder.NumOfElements());

	//lo_quantity <= 24
	uint32_t lo_pred2 = lo_quantity->CompressValue("24");
	ScanApi *lo_scan2 = new ScanApi(lo_quantity, LE, lo_pred2, LO_QUANTITY_SCAN);
	lo_scan2->initializeScanOperator(lineorder.NumOfElements());

	//lo_orderdate <= "19960101"
	uint32_t lo_pred3 = lo_orderdate->CompressValue("19960101");
	ScanApi *lo_scan3 = new ScanApi(lo_orderdate, LE, lo_pred3, LO_ORDERDATE_SCAN);
	lo_scan3->initializeScanOperator(lineorder.NumOfElements());

	//d_year = 1993
	uint32_t d_pred = d_year->CompressValue("1993");
	ScanApi *d_scan = new ScanApi(d_year, EQ, d_pred, D_YEAR_SCAN);
	d_scan->initializeScanOperator(date.NumOfElements());

	//c_mktsegment = BUILDING
	uint32_t c_pred = c_mktsegment->CompressValue("BUILDING");
	ScanApi *c_scan = new ScanApi(c_mktsegment, EQ, c_pred, C_MKTSEGMENT_SCAN);
	c_scan->initializeScanOperator(customer.NumOfElements());

	/*
	 * CREATE THE JOIN PIPELINE
	 */

	uint8_t *bit_map = d_scan->BitResult();
	JoinApi *lo_d_join = new JoinApi(lo_orderdate, bit_map);
	lo_d_join->initializeOperator(lineorder.NumOfElements());

	//Synchronization: init params
	Syncronizer thr_sync;

	thr_sync.initBarriers(num_of_cores);

	//thr_sync.initAggCounter(lo_discount->NumOfPartitions() + c_mktsegment->NumOfPartitions());
	//thr_sync.initAggCounter(lo_quantity->NumOfPartitions());
	//thr_sync.initAggCounter(d_year->NumOfPartitions() + c_mktsegment->NumOfPartitions());

	ProcessingUnit pu(num_of_cores);
	pu.setScans(lo_scan1, lo_scan2, lo_scan3, d_scan, c_scan);
	pu.setJoin(lo_d_join);
	pu.createProcessingUnit(&thr_sync, (PARALLELISM) fpga_parallelism);

	//pu.addScanItems(lo_discount->NumOfPartitions(), JOB_TYPE::LO_DISC_SCAN);
	//pu.addScanItems(lo_quantity->NumOfPartitions(), JOB_TYPE::LO_QUANTITY_SCAN);

	//pu.addWorkItems(c_scan, pu.ScanQueue());
	//pu.addWorkItems(lo_scan3, pu.ScanQueue());

	//pu.addWorkItems(lo_scan3, pu.FPGAQueue());
	pu.addWorkItems(c_scan, pu.FPGAQueue());

	printf("\n[M] FPGA Queue Ready!\n");
	//pu.printWorkQueue(pu.FPGAQueue());

	printf("[M] Join Queue Ready!\n");
	//pu.printJoinQueue();

	pu.startThreads(NULL);
	pu.joinThreads();

	printf("[M] Threads returned!\n");

	thr_sync.destroyBarriers();
}

int main(int argc, char** argv) {
	SSBQ1(argv);

	return 0;
}
