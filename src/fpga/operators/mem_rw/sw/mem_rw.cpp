#include <stdint.h>
#include <stdlib.h>
#include <unistd.h>
#include <assert.h>

#include <iostream>
#include <string>

#include "mem_rw.h"

MEMORY_RW::MEMORY_RW(const char *accel_uuid){
	fpga_wrapper = new OPAE_SVC_WRAPPER(accel_uuid);
	csrs = new CSR_MGR(*fpga_wrapper);

	buff = NULL;
	buff_pa = 0;
}

MEMORY_RW::~MEMORY_RW(){
	delete csrs;
	delete fpga_wrapper;
}

void MEMORY_RW::allocateBuffer(size_t size){
	buff = (volatile char*) fpga_wrapper->allocBuffer(size, &buff_pa);

	buff[0] = 0;
}

void MEMORY_RW::notifyAccelerator(){
	//4) Send the address of the buffer to the accelerator over CSR
	csrs->writeCSR(0, buff_pa/ CL(1));
}

void MEMORY_RW::waitAndWriteResponse(){
	//5) Wait for the accelerator to write into the buffer
	while(buff[0] == 0){};

	//6) Write the response
	printf("FPGA wrote %s into the buffer!\n", buff);
}
