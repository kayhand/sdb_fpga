#ifndef __types_h__
#define __types_h__

#define NANOSEC 1000000000

#include <stdlib.h>
#include <stdio.h>
#include <time.h>
#include <sys/time.h>

typedef int v2si __attribute__ ((vector_size (8))); //2 of 32 bit units -- in total 8 bytes
typedef short v4hi __attribute__ ((vector_size (8))); //4 of 16 bit units -- in total 8 bytes
typedef unsigned short v4qi __attribute__ ((vector_size (8))); //4 of 16 bit units -- in total 8 bytes
typedef char v8qi __attribute__ ((vector_size (8))); //8 of 8 bit units -- in total 8 bytes

enum COLUMN_NAME{
	LO_DISCOUNT,
	LO_QUANTITY,
	LO_ORDERDATE,

	D_YEAR
};

enum JOB_TYPE{
	D_YEAR_SCAN = 0,
	LO_DISC_SCAN = 1,
	LO_QUANTITY_SCAN = 2,

	C_MKTSEGMENT_SCAN = 3,

	LO_DATE_JOIN = 4
};

typedef enum {
	EQ = 0, // == pred -- 000
	NE = 2, // != pred -- 010
	GE = 1, // >= pred -- 001
	LT = 3, // <  pred -- 011
	LE = 5, // <= pred -- 101
	GT = 7, // >  pred -- 111
	GE_LE = 4, // pred1 <= value <= pred2 -- 111
} comparison_type;


enum BIT_ENCODING {
	_4_BITS = 0,
	_8_BITS = 1,
	_16_BITS = 2,
	_32_BITS = 3
};

enum PARALLELISM {
	_128_WAY = 0,
	_64_WAY = 1,
	_32_WAY = 2,
	_16_WAY = 3,
	_8_WAY = 4,
	_4_WAY = 5,
	_2_WAY = 6,
	_1_WAY = 7
};

enum CSRS_TYPE {
	total_cls = 0,
	filter_predicate = 1,
	job_type = 2,

	column_address = 4,
	result_address = 5,

	bitmap_state = 6,
	query_state = 7

};

enum QUERY_STATE {
	SCAN_PROCESSING = 0,
	JOIN_PROCESSING = 1,
	AGG_PROCESSING = 2,

	QUERY_DONE = 5

};

typedef unsigned long hrtime_t;
static unsigned long gethrtime(void) {
	struct timespec ts;

	if (clock_gettime(CLOCK_MONOTONIC_RAW, &ts) != 0) {
		return (-1);
	}

	return ((ts.tv_sec * NANOSEC) + ts.tv_nsec);
}

class Types{

public:

	static const char* getAclId(JOB_TYPE j_type){
		if (j_type == LO_QUANTITY_SCAN){
			return "1cddcf01-c266-44de-af63-9d09858310e5";
		}
		else if(j_type == LO_DISC_SCAN){
			//return "a610831b-d12a-4d07-8368-1640faa3d0cd";
			return "A610831B-D12A-4D07-8368-1640FAA3D0CD";
		}
		else if(j_type == D_YEAR_SCAN){
			return "3336382d-3136-3430-6661-613364306364";
		}
		else
			return "";
	}
};

#endif


