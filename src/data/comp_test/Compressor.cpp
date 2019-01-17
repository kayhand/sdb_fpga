/*
 * Compressor.cpp
 *
 *  Created on: Jan 6, 2019
 *      Author: kayhan
 */

#include <fstream>
#include <cmath>

#include "Compressor.h"

void Compressor::parseColumn(){
	std::ifstream file;

	std::string val_str;
	int val_int;

	std::string raw_path = col_path + "/base.dat";

	file.open(raw_path);
	while (getline(file, val_str)) {
		switch (data_type) {
		case INT:
			val_int = atoi(val_str.c_str());
			if (this->bit_mapping_int.find(val_int) == this->bit_mapping_int.end()) {
				this->bit_mapping_int[val_int] = -1;
				distinct_keys++;
			}
			break;
		case STRING:
			if (this->bit_mapping_str.find(val_str) == this->bit_mapping_str.end()) {
				this->bit_mapping_str[val_str] = -1;
				distinct_keys++;
			}
			break;
		}
	}
	file.close();

	//order encodings representing each raw value
	int index = 0;
	switch (data_type){
		case INT:
			for (auto curPair : this->bit_mapping_int) {
				this->bit_mapping_int[curPair.first] = index++;
			}
		break;
		case STRING:
			for (auto curPair : this->bit_mapping_str) {
				this->bit_mapping_str[curPair.first] = index++;
			}
		break;
	}
}

void Compressor::writeCompressedValues(){
	std::string val_str;
	int val_int;

	uint32_t comp_value;

	std::string raw_path = col_path + "/base.dat";
	std::string compressed_path = col_path + "/compressed.dat";

	std::ifstream in_file;
	in_file.open(raw_path);

	std::ofstream out_file;
	out_file.open(compressed_path);

	while (getline(in_file, val_str)) {
		switch (data_type) {
		case INT:
			val_int = atoi(val_str.c_str());
			comp_value = this->bit_mapping_int[val_int];
			out_file << comp_value << "\n";

			break;
		case STRING:
			comp_value = this->bit_mapping_str[val_str];
			out_file << comp_value << "\n";

			break;
		}
	}

	in_file.close();
	out_file.close();
}

void Compressor::writeMetaData(){
	if (distinct_keys == 1)
		bit_size = 1;
	else {
		int round = ceil(log2(distinct_keys));
		bit_size = ceil(log2(round));
		if (pow(2, bit_size) == round)
			bit_size += 1;
		bit_size = pow(2, bit_size) - 1;
	}

	if(bit_size < 8){
		bit_size = 7;
	}
	else if(bit_size < 16){
		bit_size = 15;
	}
	else{
		bit_size = 31;
	}

	std::string meta_path = col_path + "/meta.dat";
	std::ofstream out_file;
	out_file.open(meta_path);

	out_file << "distinct_values: " << this->distinct_keys << "\n";
	out_file << "bit_encoding: " << bit_size << "\n";
	out_file << "data_type: " << this->data_type << "\n";

}
