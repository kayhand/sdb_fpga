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

#define PAGE_SIZE 4096

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
		if(this->compressed != NULL){
			delete[] this->compressed;
		}
	}

	void initializePageAlignedPartition(int bit_encoding){
		int vals_per_word = 64 / bit_encoding; // 64 / 16 = 4
		int total_words = this->part_size / vals_per_word; // 2048 / 4 = 512

		if(this->part_size % vals_per_word > 0)
			total_words++;

		//printf("Partition Size: %d (bit-encoding: %d)\n", this->part_size,  bit_encoding);
		//printf("Input buffer length: %d\n", total_words);

		//reserve bit_vector
		this->compressed = new uint64_t[total_words];
		this->array_size = total_words;
	}

	void compress(std::ifstream &file, int bit_encoding){
		std::string cur_line = "";

		uint64_t newVal = 0, prevVal = 0;
		uint64_t writtenVal = 0;
		unsigned long curIndex = 0;

		int shift_amount = 0;
		int bits_remaining = 64;

		int items_read = 0;
		while(items_read < this->part_size && getline(file, cur_line)){
			newVal = atoi(cur_line.c_str());

			if (bits_remaining == 0) {
				this->compressed[curIndex] = writtenVal;
				bits_remaining = 64;
				shift_amount = 0;
				writtenVal = 0;
				//printf("[%lu]: %lu \n", curIndex, this->compressed[curIndex]);
				curIndex++;
			}
			bits_remaining -= bit_encoding;
			//writtenVal |= newVal << bits_remaining;

			writtenVal |= newVal << shift_amount;
			shift_amount += bit_encoding;

			// with bits_remaining:
			//	 val1: << 48
			//	 val2: << 32
			//	 val3: << 16
			//	 val4: << 0

			// with shift_amount:
			//	 val1: << 0
			//	 val2: << 16
			//	 val3: << 32
			//	 val4: << 48

			prevVal = newVal;

			items_read++;
		}

		this->compressed[curIndex] = writtenVal; //? double check this

		/*if(part_id == 0){
			for(int i = 0; i < 16; i++){
				printf("[%d]: %lu\n", i, this->compressed[i]);
			}
		}*/
	}

	int PartSize(){
		return this->part_size;
	}

	uint64_t* Data(){
		return this->compressed;
	}

	int DataBufferSize(){
		return this->array_size;
	}

};



#endif /* SRC_DATA_MICROBENCH_PARTITION_H_ */
