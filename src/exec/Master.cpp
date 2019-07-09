#include <stdio.h>
#include <stdlib.h>
#include <string>
#include <vector>
#include <fcntl.h>
#include <unistd.h>
#include <sys/wait.h>
#include <istream>

#include "data/Table.h"
#include "data/RawTable.h"

#include "api/ScanApi.h"
#include "api/JoinApi.h"

#include "sched/ProcessingUnit.h"

void SSBQ1(char **argv){
	std::string data_path = argv[1]; // ~/data/ssb/
	int num_of_cus = atoi(argv[2]); //including the FPGA Handler

	std::cout << "Data Path: " << data_path << std::endl;
	std::cout << "# of compute units: " << num_of_cus << std::endl;

	/*
	 * LINEORDER
	 */
	Table lineorder("lineorder");
	lineorder.initializeTable(data_path); // ~/data/ssb/

	lineorder.createColumn("lo_discount", COLUMN_NAME::LO_DISCOUNT);
	lineorder.createColumn("lo_quantity", COLUMN_NAME::LO_QUANTITY);
	lineorder.createColumn("lo_orderdate", COLUMN_NAME::LO_ORDERDATE);

	/*
	 * DATE
	 */
	Table date("date");
	date.initializeTable(data_path);
	date.createColumn("d_year", COLUMN_NAME::D_YEAR);

	/*
	 * CREATE THE JOIN PIPELINE
	 */
	//uint8_t *bit_map = d_scan->BitResult();
	//JoinApi *lo_d_join = new JoinApi(lo_orderdate, bit_map);
	//lo_d_join->initializeOperator(lineorder.NumOfElements());

	//thr_sync.initAggCounter(lo_discount->NumOfPartitions() + c_mktsegment->NumOfPartitions());
	//thr_sync.initAggCounter(lo_quantity->NumOfPartitions());
	//thr_sync.initAggCounter(d_year->NumOfPartitions() + c_mktsegment->NumOfPartitions());

	ProcessingUnit pu(num_of_cus);
	pu.createColumnScan(date.getColumn(COLUMN_NAME::D_YEAR));
	pu.createColumnScan(lineorder.getColumn(COLUMN_NAME::LO_DISCOUNT));
	pu.createColumnScan(lineorder.getColumn(COLUMN_NAME::LO_QUANTITY));

	pu.createSemiJoin(lineorder.getColumn(COLUMN_NAME::LO_ORDERDATE),
			pu.getScanResult(D_YEAR_SCAN));

	//Synchronization: init params
	Syncronizer thr_sync (num_of_cus);
	pu.createProcessingUnit(&thr_sync);

	//pu.addWorkItems(lineorder.getColumn(LO_DISCOUNT), LO_DISC_SCAN, pu.FPGAQueue());
	//pu.addWorkItems(lineorder.getColumn(LO_QUANTITY), LO_QUANTITY_SCAN, pu.FPGAQueue());

	pu.addWorkItems(date.getColumn(D_YEAR), D_YEAR_SCAN, pu.FPGAQueue());
	pu.addWorkItems(lineorder.getColumn(LO_QUANTITY), LO_QUANTITY_SCAN, pu.ScanQueue());

	//printf("\n[M] FPGA Queue Ready!\n");
	//pu.printWorkQueue(pu.FPGAQueue());

	//printf("[M] Join Queue Ready!\n");
	//pu.printJoinQueue();

	pu.startThreads(NULL);
	pu.joinThreads();

	printf("[M] Threads returned!\n");

	thr_sync.destroyBarriers();
}

void RawDataProcessing(char **argv){
	std::string data_path = argv[1]; // ~/data/ssb/date.tbl
	int num_of_cus = atoi(argv[2]); //just cores in this case

	std::cout << "Data Path: " << data_path << std::endl;
	std::cout << "# of cores: " << num_of_cus << std::endl;

	/*
	 * DATE
	 */
	RawTable date("date");
	date.initializeTable(data_path);

	RawScan dateFileScan(&date);

	ProcessingUnit pu(num_of_cus);

	//Synchronization: init params
	Syncronizer thr_sync (num_of_cus);
	pu.createProcessingUnit(&thr_sync);

	pu.createColumnParser(&dateFileScan);

	//pu.addWorkItems(date.getColumn(D_YEAR), D_YEAR_SCAN, pu.FPGAQueue());

	pu.startThreads(NULL);
	pu.joinThreads();

	printf("[M] Threads returned!\n");

	thr_sync.destroyBarriers();
}

int main(int argc, char** argv) {
	int processing_mode = atoi(argv[3]); //0: SSB, 1: RawData

	if(processing_mode == 0){
		SSBQ1(argv);
	}
	else if(processing_mode == 1){
		RawDataProcessing(argv);
	}
	else{
		printf("Processing Mode undefined!\n");
	}



	return 0;
}
