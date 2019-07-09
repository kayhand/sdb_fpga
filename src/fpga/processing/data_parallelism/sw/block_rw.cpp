#include <stdint.h>
#include <stdlib.h>
#include <unistd.h>
#include <assert.h>

#include <iostream>
#include <string>

#include "afu_json_info.h"

#include "block_rw.h"

BLOCK_RW::BLOCK_RW(){
	fpga_wrapper = NULL;
	csrs = NULL;

	column_part_pa = 0;
	read_buff_pa = 0;
	write_buff_pa = 0;
}

BLOCK_RW::~BLOCK_RW(){
	delete csrs;
	delete fpga_wrapper;
}

void BLOCK_RW::connectToAccelerator(){
	fpga_wrapper = new OPAE_SVC_WRAPPER(AFU_ACCEL_UUID);
}

void BLOCK_RW::connectToCSRManager(){
	csrs = new CSR_MGR(*fpga_wrapper);
}

bool BLOCK_RW::registerReadBuffer(void*& buff, size_t nBytes){
	printf("Sharing a buffer that was already created by SiliconDB!\n");

	bool isOK = fpga_wrapper->prepMPFBuffer(nBytes, buff, &column_part_pa);

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

bool BLOCK_RW::prepareReadBuffer(volatile void*& buff, void*& block, size_t nBytes){

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

void BLOCK_RW::prepareWriteBuffer(volatile void*& buff, size_t nBytes){
	buff = fpga_wrapper->allocBuffer(nBytes, &write_buff_pa);
}

void BLOCK_RW::sendQueryParams(int total_cls, uint32_t pred, int bit_encoding){
	printf("\n+++++++++++++++++++++++++++++++++++++++\n");
	printf("State of the CSRs before query start: \n");
	for(int csr_id = 0; csr_id < 8; csr_id++){
		std::cout << "CSR[" << csr_id << "]: " << csrs->readCSR(csr_id) << std::endl;
	}
	printf("\n+++++++++++++++++++++++++++++++++++++++\n");

	csrs->writeCSR(0, total_cls);
	csrs->writeCSR(1, pred);
	csrs->writeCSR(2, bit_encoding);
}

void BLOCK_RW::sendQueryParams(int total_cls, uint32_t pred){
	csrs->writeCSR(0, total_cls);
	csrs->writeCSR(1, pred);
}

void BLOCK_RW::sendQueryParams(int total_cls){
	csrs->writeCSR(0, total_cls);
}

void BLOCK_RW::registerBitMapIntoFPGA(void*& bit_map, int len){
	shareBuffVA(4, intptr_t(bit_map));

	int total_cls = len / 512; //d_year: 2556 / 512
	total_cls = total_cls + (total_cls % 512 == 0);

	while((csrs->readCSR(0) < total_cls)){

	}
	printf("All bitmap cls read by FPGA!\n");

}

void BLOCK_RW::shareBuffVA(int csr_id, intptr_t buff_va){
	csrs->writeCSR(csr_id, buff_va);
}

void BLOCK_RW::waitForProcessing(int total_cls, volatile void*& buff){
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
	printf("Partition processed!\n");

	/*while(!csrs->readCSR(2)){

	}
	printf("Last write also done!\n");*/
}

void BLOCK_RW::waitAndWriteResponse(int total_cls){
    // Spin, waiting for the value in memory to change to something non-zero.
    struct timespec pause;
    // Longer when simulating
    pause.tv_sec = (fpga_wrapper->hwIsSimulated() ? 2 : 2);
    pause.tv_nsec = 2500000;

    int prev_cl = 0;
    int cur_cl = 0;
    while (csrs->readCSR(0) == 0) // check if partition is processed
    {
    	if((cur_cl = csrs->readCSR(2)) != prev_cl){
    		cur_cl = csrs->readCSR(2);

    		printf("Bit vector for CL #%d: \n", cur_cl);

    		this->addBitResult(csrs->readCSR(3));
    		this->addBitResult(csrs->readCSR(4));

    		//this->printBitResult(csrs->readCSR(3));
    		//printf("\n");

    		prev_cl = cur_cl;
    	}
    }

    printf("Produced %d bit results in total!\n", this->totalResults());
}

void BLOCK_RW::notifyFPGA(int code){
	csrs->writeCSR(6, code);

    // Spin, waiting for the value in memory to change to something non-zero.
    struct timespec pause;
    // Longer when simulating
    pause.tv_sec = 2;
    pause.tv_nsec = 2500000;

    nanosleep(&pause, NULL);
}
