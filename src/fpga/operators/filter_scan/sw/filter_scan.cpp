#include "filter_scan.h"

#include <stdint.h>
#include <stdlib.h>
#include <unistd.h>
#include <assert.h>

#include <iostream>
#include <string>

#include "afu_json_info.h"

FPGA_SCAN::FPGA_SCAN(){
	fpga_wrapper = NULL;
	csrs = NULL;

	read_buff_pa = 0;
	write_buff_pa = 0;
}

FPGA_SCAN::~FPGA_SCAN(){
	delete csrs;
	delete fpga_wrapper;
}

void FPGA_SCAN::connectToAccelerator(){
	fpga_wrapper = new OPAE_SVC_WRAPPER(AFU_ACCEL_UUID);
}

void FPGA_SCAN::connectToCSRManager(){
	csrs = new CSR_MGR(*fpga_wrapper);
}

bool FPGA_SCAN::prepareReadBuffer(volatile void*& buff, void*& block, size_t nBytes){

	buff = fpga_wrapper->allocBuffer(nBytes, &read_buff_pa);
	memcpy((void *) buff, (const void*) block, nBytes);

	if(read_buff_pa == 0){
		printf("Problem with preparing the read buffer!\n");
		return false;
	}
	else{
		printf("Column partition copied into the new buffer succesfully!\n");
		printf("First 5 words contain the values...\n");
		for(int i = 0; i < 5; i++){
			printf("[%i]: %lu into %lu \n", i, ((uint64_t*) block)[i], ((volatile uint64_t*) buff)[i]);
		}
		return true;
	}
}

void FPGA_SCAN::prepareWriteBuffer(volatile void*& buff, size_t nBytes){
	buff = fpga_wrapper->allocBuffer(nBytes, &write_buff_pa);
}

void FPGA_SCAN::sendQueryParams(int total_cls, uint32_t pred){
	csrs->writeCSR(2, total_cls);
	csrs->writeCSR(3, pred);
}

void FPGA_SCAN::shareBuffVA(int csr_id, intptr_t buff_va){
	csrs->writeCSR(csr_id, buff_va);
}

void FPGA_SCAN::waitAndWriteResponse(int total_cls, volatile uint64_t*& buff){
	int curr_bit_res = 0;
	int last_bit_res = 0;

	int curr_cl = 0;
	while((curr_cl = csrs->readCSR(0)) < total_cls){
		curr_bit_res = csrs->readCSR(1);
		if(curr_bit_res > last_bit_res){ //there is a new result
			last_bit_res = curr_bit_res;

			printf("Last bit result generated: %lu\n", curr_bit_res);
			printf("Last cache processed: %lu\n", curr_cl);
		}
	}

	struct timespec pause;
	pause.tv_sec = (fpga_wrapper->hwIsSimulated() ? 1 : 0);
	pause.tv_nsec = 10000000;

	while(csrs->readCSR(2) == 0){
		printf("Waiting for the final write to be processed!\n");
		nanosleep(&pause, NULL);
	}

	printf("++++++++++++++++++\n");
	printf("Scan results: \n");

	printFilterResults(buff, total_cls);

	printf("++++++++++++++++++\n");
}

void FPGA_SCAN::notifyFPGA(int code){
	csrs->writeCSR(5, code);
}
