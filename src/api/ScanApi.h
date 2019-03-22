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

	uint8_t *bit_result = NULL;
	int slots_per_partition = 0;
	std::vector<uint64_t*> partition_data;

public:
	ScanApi(Column *column, comparison_type comp, uint32_t param) {
		this->baseColumn = column;
		this->comparison_op = comp;
		this->scan_param = param;
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
		int num_of_bytes = num_of_elements / 8; //30000 / 8 = 3750
		bit_result = new uint8_t[num_of_bytes];

		this->slots_per_partition = num_of_bytes / this->baseColumn->NumOfPartitions(); // 1875

		for(Partition *part : this->baseColumn->Partitions()){
			partition_data.push_back(part->Data());
		}
	}

	void simdScan8(Node*);

	Column* BaseColumn(){
		return this->baseColumn;
	}

	void* DataBlock(int part_id, size_t &block_size){
		int num_of_bits = this->baseColumn->BitEncoding() * this->baseColumn->PartSize();
		block_size = num_of_bits / 8;

		return (void *) this->partition_data[part_id];
	}

	uint32_t& FilterPredicate(){
		return this->scan_param;
	}

};

#endif
