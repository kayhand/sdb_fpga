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
	std::vector<Column*> columns;

	int num_of_elements = 0;

public:
	Table(std::string table_name){
		tableName = table_name;
	}

	~Table(){
		for(Column *column : columns){
			delete column;
		}
	}

	/* Read in metadata information for the corresponding relation
	 */
	void initializeTable(std::string path){
		this->tablePath = path;
	    std::ifstream file;
	    file.open(this->tablePath + "meta.dat");
	    std::string num_of_vals;
	    getline(file, num_of_vals);
	    file.close();

		num_of_elements = atoi(num_of_vals.c_str());
	}

	void addColumn(Column *col){
		columns.push_back(col);
	}

	int NumOfElements(){
		return num_of_elements;
	}

	std::string Path(){
		return this->tablePath;
	}
};


#endif /* SRC_DATA_MICROBENCH_TABLE_H_ */
