/*
 * Table.h
 *
 *  Created on: Nov 8, 2018
 *      Author: kayhan
 */

#ifndef SRC_DATA_MICROBENCH_TABLE_H_
#define SRC_DATA_MICROBENCH_TABLE_H_

#include "Column.h"
#include <sstream>

class Table {
private:
	std::string tableName;
	std::string tablePath;

	std::unordered_map<int, Column*> columns;

	int num_of_elements = 0;

public:
	Table(std::string table_name){
		tableName = table_name;
	}

	~Table(){
		for(auto &entry : columns){
			delete entry.second;
		}
	}

	/*
	 * Read in metadata information for the corresponding relation
	 */

	// "~/data/ssb/"
	void initializeTable(std::string basePath){
		this->tablePath = basePath + this->tableName + "/"; // "~/data/ssb/" + "lineorder" + "/"
	    std::ifstream file;
	    file.open(this->tablePath + "meta.dat");
	    std::string num_of_vals;
	    getline(file, num_of_vals);
	    file.close();

		num_of_elements = atoi(num_of_vals.c_str());
	}

	// Enum to int casting for parameter
	Column*& getColumn(int colId){
		return columns.at(colId);
	}

	// "lo_discount"
	void createColumn(std::string columnFile, COLUMN_NAME columnName){
		Column *column = new Column(columnName, this->NumOfElements());
		column->initializeColumn(this->Path(), columnFile);
		int num_of_partitions = column->initializePageAlignedPartitions();
		column->compressColumn();

		columns.insert({columnName, column});

		printf("\n");
		std::cout << "[M] Column " << columnFile << " info: " << std::endl;
		std::cout << "           Path: " << column->ColPath() << std::endl;
		std::cout << "           Encoding: " << column->BitEncoding() << "-bits" << std::endl;
		std::cout << "           # of parts: " << column->NumOfPartitions() << std::endl;

	}

	int NumOfElements(){
		return num_of_elements;
	}

	std::string Path(){
		return this->tablePath;
	}
};

#endif /* SRC_DATA_MICROBENCH_TABLE_H_ */
