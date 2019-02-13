/*
 * Partition.h
 *
 *  Created on: Nov 8, 2018
 *      Author: kayhan
 */

#ifndef SRC_DATA_MICROBENCH_PARTITION_H_
#define SRC_DATA_MICROBENCH_PARTITION_H_

#include <cstdint>
#include <vector>
#include <fstream>

class Partition {
private:
	int part_id;
	uint32_t start;
	uint32_t end;
	int part_size;

	uint64_t *compressed = NULL; //compressed bit vector
	int array_size = 0;

public:

	Partition(int part_id, uint32_t start, uint32_t end){
		this->part_id = part_id;
		this->start = start;
		this->end = end;

		this->part_size = this->end - this->start;
	}

	~Partition(){
		printf("Destroying partition...\n");
		if(this->compressed != NULL){
			delete[] this->compressed;
		}
	}

	void initializePartition(int bit_encoding){
		int total_bits = (part_size * bit_encoding);
		int total_bytes = total_bits / 8;

		printf("Reserving %d bytes for the bit_vector, size of the array: %d...\n", total_bytes, total_bytes / 8);

		//reserve bit_vector
		this->array_size = total_bytes / 8;
		this->compressed = new uint64_t[array_size];
	}

	void compress(std::ifstream &file, int num_of_bits){
		std::string cur_line = "";

		uint64_t newVal = 0, prevVal = 0;
		uint64_t writtenVal = 0;
		unsigned long curIndex = 0;

		int bits_remaining = 64;

		int items_read = 0;
		while(items_read < this->part_size && getline(file, cur_line)){
			newVal = atoi(cur_line.c_str());

			if (bits_remaining == 0) {
				this->compressed[curIndex] = writtenVal;
				bits_remaining = 64;
				writtenVal = 0;
				//printf("[%lu]: %lu \n", curIndex, this->compressed[curIndex]);
				curIndex++;
			}
			bits_remaining -= num_of_bits;

			//if (bits_remaining >= 0)
			writtenVal |= newVal << bits_remaining;

			prevVal = newVal;

			items_read++;
		}
		this->compressed[curIndex] = writtenVal; //? double check this
	}

	int PartSize(){
		return this->part_size;
	}

	uint64_t* Data(){
		return this->compressed;
	}

	int DataArraySize(){
		return this->array_size;
	}

};



#endif /* SRC_DATA_MICROBENCH_PARTITION_H_ */
