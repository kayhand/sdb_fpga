#ifndef __scan_api_h__
#define __scan_api_h__

#include "data/Column.h"
#include "util/Types.h"

#include "thread/Thread.h"

class ScanApi {
private:
	Column *baseColumn = NULL;
	comparison_type comparison_op = EQ;
	uint32_t scan_param = 0;

	int items_per_partition = 0;

	uint8_t *bit_result = NULL;

	int partition_input_size = 0; // compressed data buffer size
	int partition_result_size = 0; // bit_result buffer size
	std::vector<uint64_t*> partition_data;

	JOB_TYPE job_type = LO_DISC_SCAN;

public:
	ScanApi(Column *column, comparison_type comp, uint32_t param, JOB_TYPE scan_job) {
		this->baseColumn = column;
		this->comparison_op = comp;
		this->scan_param = param;
		this->job_type = scan_job;
	}

	~ScanApi() {
		delete[] bit_result;
	}

	/*
	 * 1) Reserve memory to keep the filter result
	 * 	  -- # of bytes required = # of elements (total_bits) / 8
	 * 2) Get pointers to the compressed data
	 */
	void initializeScanOperator(int num_of_elements) {
		int buffer_size = num_of_elements / 8; //30000 / 8 = 3750
		bit_result = new uint8_t[buffer_size];

		int bit_encoding = baseColumn->BitEncoding();
		this->items_per_partition = (PAGE_SIZE * 8) / bit_encoding;

		printf("-- Bit encoding: %d\n", bit_encoding); // 16
		this->partition_input_size = this->items_per_partition / (64 / bit_encoding); // 2048 / 4 = 512
		this->partition_result_size = this->items_per_partition / 8; // 2048 / 8 = 256

		for(Partition *part : this->baseColumn->Partitions()){
			partition_data.push_back(part->Data());
		}
	}

	int simdScan4(Node*);
	int simdScan8(Node*);
	int simdScan16(Node*);

	Column* BaseColumn(){
		return this->baseColumn;
	}

	uint8_t*& BitResult(){
		return this->bit_result;
	}

	JOB_TYPE &JobType(){
		return this->job_type;
	}

	void* DataBlock(int part_id, size_t &block_size){
		int num_of_bits = this->baseColumn->BitEncoding() * this->baseColumn->PartSize();
		block_size = num_of_bits / 8;

		return (void *) this->partition_data[part_id];
	}

	void* DataBlock(int part_id){
		return (void *) this->partition_data[part_id];
	}

	uint32_t& FilterPredicate(){
		return this->scan_param;
	}

	int TotalPartitions(){
		return this->partition_data.size();
	}

};

#endif
