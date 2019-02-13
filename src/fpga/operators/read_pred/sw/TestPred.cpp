#include "util/Types.h"
#include "read_pred.h"

int main(int argc, char *argv[]){
	JOB_TYPE j_type = C_SCAN;

	READ_PRED read_pred_op(Types::getAclId(j_type));
	if(read_pred_op.isAccOK()){
		read_pred_op.writePredicate(2);
		read_pred_op.waitAndWriteResponse();
	}
	else{
		printf("Accelerator not found!\n");
	}

	return 0;
}
