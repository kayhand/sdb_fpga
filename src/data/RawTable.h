/*
 * Table.h
 *
 *  Created on: Nov 8, 2018
 *      Author: kayhan
 */

#ifndef SRC_DATA_MICROBENCH_RAWTABLE_H_
#define SRC_DATA_MICROBENCH_RAWTABLE_H_

#include "Column.h"
#include <sstream>
#include <sys/mman.h>

class RawTable {
private:
	std::string tableName;
	std::string tablePath;

	std::unordered_map<int, Column*> columns;

	int num_of_elements = 0;
	int file_size = 0;

	int total_chunks = -1;
	int next_chunk = 0;

	std::vector<void*> raw_buffers;
	char* mapped_chunk = NULL;

public:
	RawTable(std::string table_name){
		tableName = table_name;
	}

	~RawTable(){
		for(auto &entry : columns){
			delete entry.second;
		}
	}

	/*
	 * Read in metadata information for the corresponding relation
	 */

	// "~/data/ssb/"
	void initializeTable(std::string filePath){
		// "~/data/ssb_data/" + "date" + ".tbl"
		this->tablePath = filePath;
		int fp = open(this->tablePath.c_str(), O_RDONLY);
		if(fp < 0){
			printf("Error accessing raw data!\n");
			return;
		}

		int page_size = getpagesize();
		auto data_size = lseek(fp, 0, SEEK_END);
		int total_pages = data_size / page_size + 1;

		lseek(fp, 0, SEEK_SET);

		int offset = 0;

		for(int chunk_id = 0; chunk_id < 1; chunk_id++){
		//	printf("Chunk %d: \n", chunk_id);

			void *raw_buffer =
				mmap(NULL, page_size, PROT_READ, MAP_SHARED, fp, offset);

			raw_buffers.push_back(raw_buffer);

			offset += page_size;
			total_chunks++;
		}

		//std::cout << "Total file size: " << data_size << " bytes" << std::endl;
		//std::cout << "Total number of pages (buffers): " << total_pages
		//		<< " (each page is " << getpagesize() << " bytes)" << std::endl;


		close(fp);
	}

	bool moreChunks(){
		return (next_chunk == total_chunks);
	}

	void mapNextChunk(){
		mapped_chunk = reinterpret_cast<char*>(raw_buffers[next_chunk]);
		next_chunk++;
	}

	char* readNextCL(int cl_id){
		return &(mapped_chunk[cl_id * 64]);
		//for(int byte_id = 0; byte_id < 64; byte_id++){
		//	std::cout << last_chunk[cl_id * 64 + byte_id];
		//}
	}

	void releaseMappedChunk(){
		munmap(mapped_chunk, getpagesize());
	}

	void mapToMemory(){

	}


};

#endif /* SRC_DATA_MICROBENCH_TABLE_H_ */
