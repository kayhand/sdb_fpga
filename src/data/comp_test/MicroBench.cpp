#include <string>
#include <iostream>

#include "Compressor.h"

#include "data/Table.h"
#include "api/ScanApi.h"

int main(int argc, char** argv) {
	std::string data_path = argv[1]; // ~/data/ssb/
	int partition_size = atoi(argv[2]);

	Table customer("customer");
	customer.initializeTable(data_path + "customer/"); // ~/data/ssb/customer/
	int num_of_partitions = customer.NumOfElements() / partition_size; //(30000 / 15000)
	printf("Number of partitions: %d\n", num_of_partitions);

	Column *c_mktsegment = new Column("c_mktsegment");
	c_mktsegment->initializeColumn(customer.Path() + "c_mktsegment/"); // ~/data/ssb/customer/c_mktsegment/
	c_mktsegment->initializePartitions(num_of_partitions, partition_size);
	c_mktsegment->compressColumn();

	customer.addColumn(c_mktsegment);

	ScanApi *scan = new ScanApi(c_mktsegment, EQ, 3);
	delete scan;

	return 0;
}


/*
int main(int argc, char** argv) {
	std::string col_path = argv[1];
	std::string data_type = argv[2];

	data_type_t base_type = data_type_t::STRING;
	if(data_type == "INT")
		base_type = data_type_t::INT;

	Compressor comp(col_path, base_type);
	comp.parseColumn();
	comp.writeCompressedValues();
	comp.writeMetaData();

	return 0;
}
*/
