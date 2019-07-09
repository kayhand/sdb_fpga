#ifndef __join_api_h__
#define __join_api_h__

#include "JobWrapper.h"

#include "data/Column.h"
#include "util/Types.h"

#include "thread/Thread.h"

class JoinApi : public JobWrapper {

	uint64_t** bit_map;
	int bitmap_size;

public:
	JoinApi(JOB_TYPE join_job, Column *fkColumn, uint64_t **bit_map, int bitmap_size) :
		JobWrapper(join_job, fkColumn){
		this->bit_map = bit_map;
		this->bitmap_size = bitmap_size;
	}

	~JoinApi() {
	}

	void initializeJoinOperator() {
		printf("[INIT][JOIN_OPERATOR]\n");
		this->initializeOperator();
	}

	Column*& FKColumn(){
		return this->BaseColumn();
	}

	//FIX THIS
	uint64_t**& BitMap(){
		return this->bit_map;
	}

	int BitMapSize(){
		return this->bitmap_size;
	}

	void countBitmapResult(int size){
		printf("\n ===================== \n");
		printf("Bitmap size: %d \n", size);

		int word_id = 0;
		int filter_count = 0;
		int remaining = size;
		while(remaining > 0){
			std::bitset<64> bit_res((*(bit_map))[word_id]);
			filter_count += bit_res.count();
			word_id++;
			remaining -= 64;
		}

		printf("\n");
		printf("=====================\n");
		printf("\n[FH][BITMAP_COUNT] \t || Bitmap Count: %d || \n\n", filter_count);
 	}

};

#endif
