/*
 * Column.h
 *
 *  Created on: Nov 8, 2018
 *      Author: kayhan
 */

#ifndef SRC_DATA_MICROBENCH_COLUMN_H_
#define SRC_DATA_MICROBENCH_COLUMN_H_

#include "util/Types.h"
#include "Partition.h"

#include <unordered_map>
#include <vector>
#include <fstream>

#include <iostream>

enum data_type_t {
	INT, DOUBLE, STRING
};

class Column {
private:
	struct column_encoder {
		int num_of_bits; //c_mktsegment/meta.dat -- bit_encoding
		uint32_t distinct_values; //c_mktsegment/meta.dat -- distinct_values

		// base_value -> compressed_value
		std::unordered_map<std::string, uint32_t> dictionary;
	} c_encoder;

	// compressed_value -> base_value
	std::unordered_map<uint32_t, std::string> decoding_table;

	std::string colPath;

	COLUMN_NAME colName;

	int colSize;

	int data_type = 2; // c_mktsegment/meta.dat -- data_type
	int num_of_pages = 0; //number of memory pages required

	std::vector<Partition*> partitions;

public:
	Column(COLUMN_NAME col_name, int col_size){
		this->colName = col_name;
		this->colSize = col_size;
	}

	~Column(){
		for(Partition *partition : partitions){
			delete partition;
		}
	}

	/*
	 * Reads in some information for the corresponding column
	 *
	 * Info. about column: ~/data/ssb/customer/c_mktsegment/meta.dat
	 * Uncompressed column: ~/data/ssb/customer/c_mktsegment/base.dat
	 * Compressed column: ~/data/ssb/customer/c_mktsegment/compressed.dat
	 */
	void initializeColumn(std::string tablePath, std::string colPath){
		this->colPath = tablePath + colPath + "/";

		std::string bit_size;
		std::string distinct_keys;
		std::string data_type;

		//Scan the whole file
	    std::ifstream meta_file;
	    meta_file.open(this->colPath + "meta.dat");
	    getline(meta_file, distinct_keys);
	    getline(meta_file, bit_size);
	    getline(meta_file, data_type);
	    meta_file.close();

	    int splitPos = distinct_keys.find(':');
	    c_encoder.distinct_values = atoi(distinct_keys.substr(splitPos + 2).c_str());

		splitPos = bit_size.find(':');
		c_encoder.num_of_bits = atoi(bit_size.substr(splitPos + 2).c_str()) + 1;

		splitPos = data_type.find(':');
		this->data_type = atoi(data_type.substr(splitPos + 2).c_str());

		std::ifstream base_file;
		base_file.open(this->colPath + "base.dat");
		std::ifstream compressed_file;
		compressed_file.open(this->colPath + "compressed.dat");

		std::string base_val;
		std::string compressed_val;
		while(getline(base_file, base_val) && getline(compressed_file, compressed_val)){
			if(this->c_encoder.dictionary.find(base_val) == this->c_encoder.dictionary.end()){
				this->c_encoder.dictionary[base_val] = atoi(compressed_val.c_str());
			}
		}
		base_file.close();
		compressed_file.close();

		c_encoder.distinct_values = c_encoder.dictionary.size();

	    for(auto &curr : this->c_encoder.dictionary){
			if(this->decoding_table.find(curr.second) == this->decoding_table.end()){
				this->decoding_table[curr.second] = curr.first;
			}
	    }
	}

	/*
	 * Create partitions for the corresponding column
	 */
	void initializePartitions(int num_of_parts, int partition_size){
		for(int partId = 0; partId < num_of_parts; partId++){
			int start = partId * partition_size;
			partitions.push_back(new Partition(partId, start, start + partition_size));
		}
	}

	/*
	 * Create a partition out of each page
	 */
	int initializePageAlignedPartitions(){
		int num_of_pages = NumOfPagesRequired(PAGE_SIZE);
		int partition_size = (PAGE_SIZE * 8) / this->c_encoder.num_of_bits;

		int partId = 0;
		for(; partId < num_of_pages; partId++){
			int start = partId * partition_size;
			partitions.push_back(new Partition(partId, start, start + partition_size));
		}

		//int start = partId * partition_size;
		//int end = this->colSize - 1;
		//partitions.push_back(new Partition(partId, start, end));

		return num_of_pages;
	}

	/*
	 * Create compressed bit vectors for each partition
	 */
	void compressColumn(){
		std::ifstream compressed_file;
		compressed_file.open(this->colPath + "compressed.dat");

		//printf("Reading column from path %s\n", this->colPath.c_str());

		for(Partition *curPart : partitions){
			curPart->initializePageAlignedPartition(c_encoder.num_of_bits);
			curPart->compress(compressed_file, c_encoder.num_of_bits);
		}

		compressed_file.close();
	}

	COLUMN_NAME& ColName(){
		return this->colName;
	}

	std::string ColPath(){
		return this->colPath;
	}

	int NumOfPartitions(){
		return this->partitions.size();
	}

	int PartSize(){
		return this->partitions[0]->PartSize();
	}

	int &ColSize(){
		return this->colSize;
	}

	int &BitEncoding(){
		return this->c_encoder.num_of_bits;
	}

	uint64_t* PartData(int part_id){
		return partitions[part_id]->Data();
	}

	int InputBufferLength(int part_id){
		return partitions[part_id]->DataBufferSize();
	}

	std::vector<Partition*> Partitions(){
		return this->partitions;
	}

	uint32_t CompressValue(std::string uncompressed){
		return this->c_encoder.dictionary[uncompressed];
	}

	std::string DecompressValue(uint32_t compressed){
		return this->decoding_table[compressed];
	}

	int NumOfPagesRequired(int p_size){
		int totalSize = (this->c_encoder.num_of_bits * this->colSize) / 8;

		this->num_of_pages = totalSize / p_size;
		if(totalSize % p_size > 0)
			this->num_of_pages++;

		return this->num_of_pages;
	}

};


#endif /* SRC_DATA_MICROBENCH_COLUMN_H_ */
