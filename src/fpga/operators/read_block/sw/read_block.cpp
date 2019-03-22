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

	column_part_pa = 0;
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

bool READ_BLOCK::registerReadBuffer(void*& buff, size_t nBytes){
	printf("Sharing a buffer that was already created by SiliconDB!\n");

	bool isOK;

	if(mpfVtpIsAvailable(fpga_wrapper->mpf_handle)){
		printf("MPF VTP is available!\n");
		isOK = fpga_wrapper->prepMPFBuffer(nBytes, buff, &column_part_pa);
	}
	else{
		isOK = fpga_wrapper->prepBuffer(nBytes, buff, &column_part_pa);
	}

	if(isOK){
		printf("First partition succesfully registered and ready to share with FPGA!\n");
		for(int i = 0; i < 10; i++){
			printf("buff''[%d]: %lu\n", i, ((volatile uint64_t*) buff)[i]);
		}
		printf("---------------------------\n");
		for(int i = 10; i < 20; i++){
			printf("buff''[%d]: %lu\n", i, ((volatile uint64_t*) buff)[i]);
		}
		printf("---------------------------\n");
		for(int i = 20; i < 30; i++){
			printf("buff''[%d]: %lu\n", i, ((volatile uint64_t*) buff)[i]);
		}

		return true;
	}
	else{
		return false;
	}
}

bool READ_BLOCK::prepareReadBuffer(volatile void*& buff, void*& block, size_t nBytes){

	buff = fpga_wrapper->allocBuffer(nBytes, &read_buff_pa);
	memcpy((void *) buff, (const void*) block, nBytes);

	if(read_buff_pa == 0){
		printf("Problem with creating the buffer!\n");
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

void READ_BLOCK::prepareWriteBuffer(volatile void*& buff, size_t nBytes){
	buff = fpga_wrapper->allocBuffer(nBytes, &write_buff_pa);
}

void READ_BLOCK::sendQueryParams(int total_cls, uint32_t pred){
	//csrs->writeCSR(0, write_buff_pa / CL(1));
	//csrs->writeCSR(1, read_buff_pa);
	//csrs->writeCSR(1, column_part_pa / CL(1));

	csrs->writeCSR(0, total_cls);
	csrs->writeCSR(1, pred);
}

void READ_BLOCK::shareBuffVA(int csr_id, intptr_t buff_va){
	csrs->writeCSR(csr_id, buff_va);
}

void READ_BLOCK::waitAndWriteResponse(int total_cls, volatile uint64_t*& buff){
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
	pause.tv_nsec = 20000000;

	while(csrs->readCSR(2) == 0){
		printf("Waiting for the final write to be processed!\n");
		nanosleep(&pause, NULL);
	}

	nanosleep(&pause, NULL);
	printf("\n++++++++++++++++++\n\n");
	printFilterResults(buff, total_cls);
	printf("\n++++++++++++++++++\n\n");

}

void READ_BLOCK::notifyFPGA(int code){
	csrs->writeCSR(4, code);
}
