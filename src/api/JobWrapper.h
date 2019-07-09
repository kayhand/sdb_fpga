#ifndef __job_wrapper_h__
#define __job_wrapper_h__

#define CL_SIZE 512
#define WORD_SIZE 64

#include <bitset>
#include <math.h>

#include "data/Column.h"
#include "util/Types.h"

#include "thread/Thread.h"

class JobWrapper {
protected:

	JOB_TYPE jobType;

	Column *baseColumn;
	uint64_t *bit_result = NULL;

	// In total for the complete column
	// (partition_output_size * num_of_partitions)
	int bit_vector_size = 0;

	// Per partition
	// In terms of # of words (64-bits)
	int input_buff_len = 0;
	//int partition_output_size = 0;
	int res_buff_len = 0;

	int num_of_partitions;

public:
	JobWrapper(JOB_TYPE job_type, Column *inputColumn) {
		this->jobType = job_type;
		this->baseColumn = inputColumn;
		this->num_of_partitions = inputColumn->NumOfPartitions();
	}

	virtual ~JobWrapper() {
		delete[] bit_result;
	}

	void setNumOfPartitions(int parts){
		this->num_of_partitions = parts;
	}

	/*
	 * 1) Reserve memory to keep the filter result
	 * 	  -- # of bytes required = # of elements (total_bits) / 8
	 * 2) Get pointers to the compressed data
	 */
	void initializeOperator() {
		this->reserveResultBuffer();
	}

	void reserveResultBuffer(){
		int bit_encoding = baseColumn->BitEncoding();

		// Each partition block has 4096 * 8-bits = 32768
		// 		contains 8192 d_year items -- 32768 / 4-bits
		// 		contains 2048 lo_orderdate FK items -- 32768 / 16-bits
		int bits_per_partition = (PAGE_SIZE * 8) / bit_encoding; // 8192

		// what if the whole column can fit into a partition?
		// d_year actually requires 2556 bits instead of 8192 bits
		int total_elements = BaseColumn()->ColSize(); //d_year = 2556
		if(total_elements < bits_per_partition){
			//bits_per_partition = total_elements; // 2556
			this->res_buff_len = total_elements / 64 + 1; // uint64_t bit_res[40];
		}
		else{
			//  buffer-length required for each partition
			//	lo_orderdate join 	: 2048 / 64 (uint64_t [32])
			this->res_buff_len = bits_per_partition / 64;
		}

		this->bit_vector_size = this->res_buff_len * this->baseColumn->NumOfPartitions(); // 128 * 1 = 128
		bit_result = new uint64_t[this->bit_vector_size];

		printf("[INIT][OP] Bit Vector Length: %d to keep %d bits for %d partitions \n!",
				this->bit_vector_size, this->res_buff_len,
				this->baseColumn->NumOfPartitions());
	}

	//for lo_orderdate join result
	void copyFPGAWriteBuffer(uint32_t* write_buff, int part_id){
		int bit_encoding = baseColumn->BitEncoding(); // 16-bits
		int res_bits_per_cl = (CL_SIZE / bit_encoding); // 32-bits (32-way parallelism)
		int buff_len_per_cl = CL_SIZE / res_bits_per_cl;  // 16

		int part_offset = part_id * this->res_buff_len;
		int wr_ind = 0;

		/*printf("+++++++++++++++++++++++++++++++++++++++++\n");

		printf("Copying AFU write buffer into the bit_result vector \n");

		printf("\n");
		printf("[WRITE_BUFF (uint32_t*)] INFO:\n");
		printf("\t	Buffer length per CL: %d\n", buff_len_per_cl);
		printf("\t	Number of bits representing join result: %d\n", res_bits_per_cl);
		printf("\n");

		printf("\n");
		printf("[BIT_RESULT (uint64_t*)] INFO:\n");
		printf("\t Buffer length per partition: %d\n", this->res_buff_len);
		printf("\t Start offset for current partition: %d\n", part_offset);
		printf("\n");*/

		int result_count = 0;
		int local_count = 0;
		uint64_t temp_lower;
		uint64_t temp_higher;
		for(int ind = part_offset; ind < part_offset + this->res_buff_len; ind++){
			temp_lower = write_buff[wr_ind];
			temp_higher = write_buff[wr_ind + 16];

			bit_result[ind] = (temp_higher << 32) | (temp_lower);

			// bit_result[ind] = ((uint64_t) (write_buff[wr_ind + 16]) << 32) | write_buff[wr_ind];
			wr_ind += 32;

			std::bitset<64> bit_res(bit_result[ind]);
			local_count = bit_res.count();
			//printf("%s\n", bit_res.to_string().c_str());
			//printf("COUNT between elements %d and %d: %d\n", (ind * 64), (ind * 64 + 64), local_count);
			result_count += local_count;
		}
		//printf("[TOTAL_COUNT]: %d \n\n", result_count);
		//printf("+++++++++++++++++++++++++++++++++++++++++\n");
	}

	void copyFPGAWriteBuffer(uint64_t* write_buff, int part_id, int total_cls){
		int bit_encoding = baseColumn->BitEncoding(); // 4-bits

		// 512 / 64 = 8
		int words_per_cl = CL_SIZE / WORD_SIZE; // 8 slots in (uint64*_t) write_buff
		// in each cache-line result (512-bits), only first "res_buff_len" bits keeps results

		// d_year scan result: (512 / 4) / 64 = 2 slots contain actual result data
		// lo_orderdate join result: (512 / 16) / 64 =  0.5 slots (32-bits)

		int res_words_per_cl = (CL_SIZE / bit_encoding) / WORD_SIZE;

		int part_offset = part_id * this->res_buff_len;
		int cl_offset = 0;
		for(int cur_cl = 0; cur_cl < total_cls; cur_cl++){ // < 20
			cl_offset = cur_cl * words_per_cl;
			for(int word_id = 0; word_id < res_words_per_cl; word_id++){
				bit_result[part_offset++] =  write_buff[cl_offset + word_id];
			}
		}
//		this->res_buff_len = part_offset - part_id * res_buff_len;

	//	printf("Reserved %d 64-bit slots for partition output!\n", this->res_buff_len);
	//	printf("Copied bit results into bit_vector from index %d to %d!\n", part_id * res_buff_len, part_offset);
	//	printf("Actual usage for partition output: %d !\n", this->res_buff_len);
	}

	void countBitResults(){
		//printf("|| Result Buffer Length (per partition): %d || \n", this->res_buff_len);

		int total_count = 0;
		for(int part_id = 0;  part_id < this->num_of_partitions; part_id++){
			int part_offset = part_id * this->res_buff_len;
			int part_count = 0;
			for(int ind = part_offset; ind < part_offset + this->res_buff_len; ind++){
				std::bitset<64> bit_res(bit_result[ind]);
				int count_per_word = bit_res.count();
				//printf("|| Count [%d]: %d\n", ind, count_per_word);
				part_count += count_per_word;
			}
			//printf("|| Part %d count: %d || \n", part_id, part_count);
			total_count += part_count;
		}
		printf("|| Total Count: %d || \n", total_count);
 	}

	Column*& BaseColumn(){
		return this->baseColumn;
	}

	uint64_t** BitResult(){
		return &(this->bit_result);
	}

	JOB_TYPE &JobType(){
		return this->jobType;
	}

	void* DataBlock(int part_id){
		return (void *) (this->baseColumn->PartData)(part_id);
	}

	int TotalPartitions(){
		return this->num_of_partitions;
	}

	int& TotalElements(){
		return baseColumn->ColSize();
	}

	int& BitEncoding(){
		return baseColumn->BitEncoding();
	}

	int& ResBuffLen(){
		return this->res_buff_len;
	}

	void PrintBitResultByItem(){
		printf("++++++++++++++++++++++++");
		printf("\n [TESTING BIT RESULT]\n");
		printf("d_year bit_vector len: %d\n", bit_vector_size);
		printf("\titem_id, \t bit_result\n");

		int item_id = 0;
		bool res;
		int count = 0;
		for(int buff_id = 0; buff_id < bit_vector_size; buff_id++){
			uint64_t curr_word = bit_result[buff_id];
			for(int id = 0; id < 64; id++){
				res = ((curr_word >> id) & 1);
				printf("\t%d, \t %d\n", item_id, res);
				count += res;
				item_id++;
			}
		}
		printf("\n Count: %d\n", count);
		printf("++++++++++++++++++++++++\n");
	}

	void PrintInputBlock(int part_id, bool isDate){
		printf("++++++++++++++++++++++++");
		printf("\n [TESTING INPUT BLOCK]\n");

		int buffer_length = this->baseColumn->InputBufferLength(part_id);
		uint64_t* input_buffer = (uint64_t*) (DataBlock(part_id));
		int bit_encoding = this->BitEncoding();

		int buff_length;
		if(isDate){
			int total_elements = 2560;
			int total_bits = total_elements * bit_encoding; // 10240
			buff_length = total_bits / 64; //  160

			printf("d_year input buffer len: %d\n", buffer_length);
			printf("d_year input buffer len with data: %d\n", buff_length);

			printf("\t date_id, \t d_year(comp), \t d_year(base)\n");

		}
		else{
			buff_length = buffer_length;

			printf("lo_orderdate input buffer len: %d\n", buffer_length);

			printf("\t lo_id, \t lo_orderdate(comp), \t lo_orderdate(base)\n");
		}

		int bit_mask = pow(2, bit_encoding) - 1; // (2 ^ 4 - 1) = (15) 1111
		int item_id = 0;
		int value;
		std::string base_val;
		for(int buff_id = 0; buff_id < buff_length; buff_id++){
			uint64_t curr_word = input_buffer[buff_id];
			for(int id = 0; id < 64 / bit_encoding; id++){
				value = ((curr_word >> (id * bit_encoding)) & bit_mask);
				printf("\t %d, \t %d, \t %s\n", item_id, value, BaseColumn()->DecompressValue(value).c_str());
				item_id++;
			}
 		}

		printf("++++++++++++++++++++++++\n");
	}

};

#endif
