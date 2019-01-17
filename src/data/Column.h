/*
 * Column.h
 *
 *  Created on: Nov 8, 2018
 *      Author: kayhan
 */

#ifndef SRC_DATA_MICROBENCH_COLUMN_H_
#define SRC_DATA_MICROBENCH_COLUMN_H_

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

		std::unordered_map<std::string, uint32_t> dictionary;
	} c_encoder;

	std::string colPath;
	std::string colName;

	int data_type = 2; // c_mktsegment/meta.dat -- data_type
	std::vector<Partition*> partitions;

public:
	Column(std::string col_name){
		this->colName = col_name;
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
	void initializeColumn(std::string colPath){
		this->colPath = colPath;

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
	    std::cout << c_encoder.num_of_bits << " bits and " << c_encoder.distinct_values << " keys " << std::endl;
	    for(auto &curr : this->c_encoder.dictionary){
	    	std::cout << curr.first << " -> " << curr.second << std::endl;
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
	 * Create compressed bit vectors for each partition
	 */
	void compressColumn(){
		std::ifstream compressed_file;
		compressed_file.open(this->colPath + "compressed.dat");

		for(Partition *curPart : partitions){
			curPart->initializePartition(c_encoder.num_of_bits);
			curPart->compress(compressed_file, c_encoder.num_of_bits);
		}

		compressed_file.close();
	}

	int NumOfElements(){
		int total = 0;
		for(Partition *part : partitions)
			total += part->PartSize();
		return total;
	}

	int NumOfPartitions(){
		return this->partitions.size();
	}

	int PartSize(){
		return this->partitions[0]->PartSize();
	}

	int BitEncoding(){
		return this->c_encoder.num_of_bits;
	}

	uint64_t* PartData(int part_id){
		return partitions[part_id]->Data();
	}

	std::vector<Partition*> Partitions(){
		return this->partitions;
	}

	uint32_t CompressValue(std::string uncompressed){
		return this->c_encoder.dictionary[uncompressed];
	}

};


#endif /* SRC_DATA_MICROBENCH_COLUMN_H_ */
