#ifndef __query_h__
#define __query_h__

class Query {

public:
	Query(){
	}

	Query(int type, int p_id, JOB_TYPE j_type) :
			p_type(type), part_id(p_id), job_type(j_type) {
	}

	~Query(){}

	void setFields(int r_id, int p_id, JOB_TYPE j_id) {
		this->p_type = r_id;
		this->part_id = p_id;
		this->job_type = j_id;
	}

	void setPartId(int p_id) {
		this->part_id = p_id;
	}

	int &getType() {
		return this->p_type;
	}

	int &getPart() {
		return this->part_id;
	}

	JOB_TYPE &getJobType() {
		return this->job_type;
	}

private:
	int p_type = -1;
	int part_id = -1;
	JOB_TYPE job_type = D_YEAR_SCAN;
};

#endif
