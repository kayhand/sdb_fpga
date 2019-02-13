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
	LO_SCAN_2 = -2,
	LO_SCAN = -1,
	S_SCAN,
	C_SCAN,
	P_SCAN,
	D_SCAN_2 = 3,
	D_SCAN = 4,
	LS_JOIN = 11,
	LC_JOIN = 12,
	LP_JOIN = 13,
	LD_JOIN = 14,
	AGG = 21,
	PRE_AGG = 22,
	POST_AGG = 23
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

	static bool isFactScan(JOB_TYPE j_type){
		if(j_type == LO_SCAN)
			return true;
		else
			return false;
	}

	static bool isFact2Scan(JOB_TYPE j_type){
		if(j_type == LO_SCAN_2)
			return true;
		else
			return false;
	}

	static bool isScan(JOB_TYPE j_type){
		if(j_type <= D_SCAN)
			return true;
		else
			return false;
	}

	static bool isPartJoin(JOB_TYPE j_type){
		if(j_type == LP_JOIN)
			return true;
		else
			return false;
	}

	static bool isJoin(JOB_TYPE j_type){
		if(j_type >= LS_JOIN && j_type <= LD_JOIN)
			return true;
		else
			return false;
	}

	static bool isAgg(JOB_TYPE j_type){
		if(j_type >= AGG)
			return true;
		else
			return false;
	}

	static const char* getAclId(JOB_TYPE j_type){
		if (j_type == LO_SCAN){
			return "1cddcf01-c266-44de-af63-9d09858310e5";
			}
		else if(j_type == C_SCAN){
			//return "a610831b-d12a-4d07-8368-1640faa3d0cd";
			return "A610831B-D12A-4D07-8368-1640FAA3D0CD";
		}
		else if(j_type == D_SCAN){
			return "3336382d-3136-3430-6661-613364306364";
		}
		else
			return "";
	}
};

#endif


