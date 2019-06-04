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

enum JOB_TYPE{
	LO_DISC_SCAN = 0,
	LO_QUANTITY_SCAN = 1,
	LO_ORDERDATE_SCAN = 2,
	D_YEAR_SCAN = 3,
	C_MKTSEGMENT_SCAN = 4,
	LD_JOIN = 5
};

typedef enum {
	EQ = 0,
	NE = 2,
	GE = 1,
	LT = 3,
	LE = 5,
	GT = 7
} comparison_type;

#ifndef __sun
typedef unsigned long hrtime_t;
static unsigned long gethrtime(void) {
	struct timespec ts;

	if (clock_gettime(CLOCK_MONOTONIC_RAW, &ts) != 0) {
		return (-1);
	}

	return ((ts.tv_sec * NANOSEC) + ts.tv_nsec);
}
#endif

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


