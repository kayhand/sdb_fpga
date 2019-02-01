#include "read_pred.h"

#include <stdint.h>
#include <stdlib.h>
#include <unistd.h>
#include <assert.h>

#include <iostream>
#include <string>


READ_PRED::READ_PRED(const char *accel_uuid){
	fpga_wrapper = new OPAE_SVC_WRAPPER(accel_uuid);
	csrs = new CSR_MGR(*fpga_wrapper);
}

READ_PRED::~READ_PRED(){
	delete csrs;
	delete fpga_wrapper;
}

void READ_PRED::writePredicate(uint64_t predicate){
	//4) Send the address of the buffer to the accelerator over CSR
	csrs->writeCSR(0, 999);
	csrs->writeCSR(1, predicate);
}

void READ_PRED::waitAndWriteResponse(){
	//5) Wait for the accelerator to write into the buffer
	while(csrs->readCSR(0) == 999){};

	//6) Write the response
	printf("FPGA wrote %lu into the register!\n", csrs->readCSR(0));
}
