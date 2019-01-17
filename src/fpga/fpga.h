/*
 * fgpa.h
 *
 *  Created on: Jan 17, 2019
 *      Author: kayhan
 */

#ifndef SRC_FPGA_FPGA_H_
#define SRC_FPGA_FPGA_H_

#include <opae/fpga.h>
#include <uuid/uuid.h>
#include <assert.h>

#include "util/Types.h"

#define CACHELINE_BYTES 64
#define CL(x) ((x) * CACHELINE_BYTES)

class FPGA {

private:
	fpga_handle x_handle = NULL;
	volatile char *buffer;
	uint64_t wsid;
	uint64_t buff_pa;

public:
	fpga_handle* connect(JOB_TYPE &j_type){
		const char* acc_id = Types::getAclId(j_type);

		fpga_properties filter = NULL;
		fpga_guid guid;
		fpga_token accel_token;

		fpgaGetProperties(NULL, &filter);
		fpgaPropertiesSetObjectType(filter, FPGA_ACCELERATOR);

		uuid_parse(acc_id, guid);
		fpgaPropertiesSetGUID(filter, guid);

		uint32_t num_matches = 1;
		fpgaEnumerate(&filter, 1, &accel_token, 1, &num_matches);

		fpgaDestroyProperties(&filter);

		if(num_matches < 1){
			fprintf(stderr, "Accelerator %s not found!\n", acc_id);
			return 0;
		}

		assert(FPGA_OK == fpgaOpen(accel_token, &x_handle, 0));

		fpgaDestroyToken(&accel_token);

		return &x_handle;
	}

	void alloc_buffer(ssize_t size){
		assert(x_handle != NULL);

		fpga_result r;
		r = fpgaPrepareBuffer(x_handle, size, (void**) &buffer, &wsid, 0);
		assert(r == FPGA_OK);

		r = fpgaGetIOAddress(x_handle, wsid, &buff_pa);
		assert(r == FPGA_OK);
	}

	void notifyFPGA(){
		assert(buffer != NULL);
		buffer[0] = 0;

		fpgaWriteMMIO64(x_handle, 0, 0, buff_pa / CL(1));
	}

	void waitForFPGA(){
		assert(buffer != NULL);
		while(buffer[0] == 0){

		};

		printf("FPGA wrote %s into the buffer!\n", buffer);
		fpgaReleaseBuffer(x_handle, wsid);
	}

	void close(){
		assert(x_handle != NULL);

		fpgaClose(x_handle);
	}

};


#endif /* SRC_FPGA_FPGA_H_ */
