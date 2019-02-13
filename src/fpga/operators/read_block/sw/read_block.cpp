#include "read_block.h"

#include <stdint.h>
#include <stdlib.h>
#include <unistd.h>
#include <assert.h>

#include <iostream>
#include <string>

#include "afu_json_info.h"

READ_BLOCK::READ_BLOCK(){
	fpga_wrapper = NULL;
	csrs = NULL;

	read_buff_pa = 0;
	write_buff_pa = 0;
}

READ_BLOCK::~READ_BLOCK(){
	delete csrs;
	delete fpga_wrapper;
}

void READ_BLOCK::connectToAccelerator(){
	fpga_wrapper = new OPAE_SVC_WRAPPER(AFU_ACCEL_UUID);
}

void READ_BLOCK::connectToCSRManager(){
	csrs = new CSR_MGR(*fpga_wrapper);
}

bool READ_BLOCK::prepareReadBuffer(volatile void*& buff, size_t nBytes){
	buff = fpga_wrapper->allocBuffer(nBytes, &read_buff_pa);

	((volatile uint64_t*) buff)[0] = 1234;
	((volatile uint64_t*) buff)[1] = 2986;
	((volatile uint64_t*) buff)[2] = 4867;
	((volatile uint64_t*) buff)[3] = 9856;
	((volatile uint64_t*) buff)[4] = 234;
	((volatile uint64_t*) buff)[5] = 986;
	((volatile uint64_t*) buff)[6] = 867;
	((volatile uint64_t*) buff)[7] = 856;

	if(read_buff_pa == 0){
		printf("Problem with creating the buffer!\n");
		return false;
	}
	else{
		//((volatile char *) buff)[0] = 0;
		return true;
	}
}

void READ_BLOCK::prepareWriteBuffer(volatile void*& buff, size_t nBytes){
	buff = fpga_wrapper->allocBuffer(nBytes, &write_buff_pa);
	((volatile uint64_t *) buff)[0] = 9999;
}

void READ_BLOCK::shareDataBlock(){
	csrs->writeCSR(0, write_buff_pa / CL(1));
	csrs->writeCSR(1, read_buff_pa / CL(1));
}

void READ_BLOCK::waitAndWriteResponse(volatile uint64_t*& buff){
	struct timespec pause;
	pause.tv_sec = (fpga_wrapper->hwIsSimulated() ? 1 : 0);
	pause.tv_nsec = 2500000;

	while(csrs->readCSR(0) == 0){
		printf("sleep...\n");
		nanosleep(&pause, NULL);
	}
	printf("AFU wrote %lu into CSR[1]!\n", csrs->readCSR(1));

	nanosleep(&pause, NULL);
}
