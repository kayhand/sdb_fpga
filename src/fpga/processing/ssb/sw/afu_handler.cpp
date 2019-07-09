#include <stdint.h>
#include <stdlib.h>
#include <unistd.h>
#include <assert.h>

#include <iostream>
#include <string>

#include "afu_handler.h"
#include "afu_json_info.h"

AFU_HANDLER::AFU_HANDLER(){
	fpga_wrapper = NULL;
	csrs = NULL;

	column_part_pa = 0;
	read_buff_pa = 0;
	write_buff_pa = 0;
}

AFU_HANDLER::~AFU_HANDLER(){
	delete csrs;
	delete fpga_wrapper;
}

void AFU_HANDLER::connectToAccelerator(){
	fpga_wrapper = new OPAE_SVC_WRAPPER(AFU_ACCEL_UUID);
}

void AFU_HANDLER::connectToCSRManager(){
	csrs = new CSR_MGR(*fpga_wrapper);
}

bool AFU_HANDLER::prepareReadBuffer(volatile void*& buff, void*& block, size_t nBytes){

	buff = fpga_wrapper->allocBuffer(nBytes, &read_buff_pa);

	memcpy((void *) buff, (const void*) block, nBytes);

	if(read_buff_pa == 0){
		printf("Problem with creating the buffer!\n");
		return false;
	}
	else{
		//printf("Column partition copied into the new buffer succesfully!\n");
		/*printf("First 5 words contain the values...\n");
		for(int i = 0; i < 5; i++){
			printf("[%i]: %lu into %lu \n", i, ((uint64_t*) block)[i], ((volatile uint64_t*) buff)[i]);
		}*/
		return true;
	}
}

void AFU_HANDLER::prepareWriteBuffer(volatile void*& buff, size_t nBytes){
	buff = fpga_wrapper->allocBuffer(nBytes, &write_buff_pa);
}

void AFU_HANDLER::waitForProcessing(int total_cls, volatile void*& buff){
	int cur_cl;
	int last_cl = -1;
	/*while((cur_cl = csrs->readCSR(0)) < total_cls){
		if(cur_cl != last_cl){
			printf("Last cl processed: %d\n", cur_cl);
			last_cl = cur_cl;
			if(csrs->readCSR(1)){
				printf("Partition processed!\n");
				break;
			}
		}
	}*/

	while(!csrs->readCSR(1)){

	}
	//printf("[FH][AFU][INFO] Partition processed!\n");

	//while(!csrs->readCSR(2)){

	//}
	//printf("Last write also done!\n");
}

void AFU_HANDLER::waitForBitMapProcessing(){

	while(!csrs->readCSR(5)){

	}
	printf("[FH][AFU][INFO] All CLs for the bitmap received!\n");
}

void AFU_HANDLER::waitForJoinProcessing(){

	while(!csrs->readCSR(5)){

	}
	printf("[FH][AFU][INFO] All CLs for the FK partition received!\n");
}

void AFU_HANDLER::notifyFPGA(QUERY_STATE state){
	csrs->writeCSR(CSRS_TYPE::query_state, (int) state);

	if(state == QUERY_STATE::QUERY_DONE){
		// Spin, waiting for the value in memory to change to something non-zero.
		struct timespec pause;
		pause.tv_sec = 2;
		pause.tv_nsec = 2500000;

	    nanosleep(&pause, NULL);
	}

}
