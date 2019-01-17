/*
 * Compressor.h
 *
 *  Created on: Jan 6, 2019
 *      Author: kayhan
 */

#ifndef SRC_DATA_COMPRESSOR_H_
#define SRC_DATA_COMPRESSOR_H_

#include <string>
#include <vector>
#include <map>

#include "data/Column.h"

class Compressor {
public:
	Compressor();

	Compressor(std::string path, data_type_t type){
		col_path = path;
		data_type = type;
	}

	~Compressor(){}

	void parseColumn();
	void writeCompressedValues();
	void writeMetaData();

private:
	std::string col_path;
	data_type_t data_type;

	// raw_value to compressed_value mapping
	std::map<int, uint32_t> bit_mapping_int;
	std::map<std::string, uint32_t> bit_mapping_str;

	int distinct_keys = -1;
	int bit_size = -1;
};

#endif /* SRC_DATA_COMPRESSOR_H_ */
