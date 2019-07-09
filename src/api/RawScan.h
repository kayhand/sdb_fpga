#ifndef __raw_scan_h__
#define __raw_scan_h__

#include <cstring> // for memcpy

#include "JobWrapper.h"

#include "data/Column.h"
#include "data/RawTable.h"

#include "util/Types.h"

#include "thread/Thread.h"

class RawScan{

private:
	int total_cls;
	int cls_processed = 0;

	RawTable* rawTable = NULL;

public:

	RawScan(RawTable* input){
		total_cls = 64;
		this->rawTable = input;
	}

	~RawScan() {
	}

	void compressAttributes(){

	}

	void filterAttributes(){

	}

	void writeAttribute(char* att_stream, int att_len){
		for(int byte_id = 0; byte_id < att_len; byte_id++){
			printf("%c", att_stream[byte_id]);
		}
		printf("\n");
	}

	void extractAttributes(char* tuple_stream, int length){
		for(int byte_id = 0; byte_id <= length; byte_id++){
			printf("%c", tuple_stream[byte_id]);
		}
		printf("\n");

		int att_start = 0;
		int att_id = 0;
		int att_end = 0;
		for(int byte_id = 0; byte_id < length; byte_id++){
			if(tuple_stream[byte_id] == '|'){
				att_end = byte_id;

				printf("        Att %d (%d - %d): ", att_id++,
						att_start, att_end);
				this->writeAttribute(&(tuple_stream[att_start]),
						att_end - att_start);
				att_start = att_end + 1;
			}
		}
	}

	void extractTuples(char*& input_cl){
		int tuple_id = 0;
		int tuple_start = 0;
		int tuple_end = 0;

		for(int byte_id = 0; byte_id < 64; byte_id++){
			if(input_cl[byte_id] == '\n' || byte_id == 63){
				tuple_end = byte_id;
				printf("\n    Tuple %d (%d - %d): ", tuple_id++,
						tuple_start, tuple_end);
				this->extractAttributes(&(input_cl[tuple_start]),
						tuple_end - tuple_start);
				tuple_start = tuple_end + 1;
			}

		}
		printf("\n");
	}

	void processChunk(int total_cls){
		for(int cl_id = 0; cl_id < total_cls; cl_id++){
			char *input_cl = rawTable->readNextCL(cl_id);
			printf("CL %d: \n", cl_id);
			this->extractTuples(input_cl); // 64 Bytes of cache_line stream
		}
	}

	RawTable*& RawInput(){
		return this->rawTable;
	}


};

#endif
