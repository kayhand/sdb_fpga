#ifndef __scan_api_h__
#define __scan_api_h__

#include "JobWrapper.h"

#include "data/Column.h"
#include "util/Types.h"

#include "thread/Thread.h"

class ScanApi : public JobWrapper{

private:
	comparison_type comparison_op;
	uint32_t lower_param;
	uint32_t upper_param;

public:

	ScanApi(JOB_TYPE scan_job, Column *column, comparison_type comp, uint32_t param1) :
		JobWrapper(scan_job, column){

		this->comparison_op = comp;
		this->lower_param = param1;
		this->upper_param = -1;
	}

	~ScanApi() {
	}

	void setUpperParam(uint32_t param){
		upper_param = param;
	}

	void initializeScanOperator() {
		this->initializeOperator();
	}

	int simdScan4(Node*);
	int simdScan8(int);
	int simdScan16(Node*);

	uint32_t& FilterPredicate(){
		return this->lower_param;
	}

	uint32_t RangePredicate(){
		return ((this->upper_param << 4) | (this->lower_param));
	}

	Column*& ScanColumn(){
		return this->BaseColumn();
	}

};

#endif
