#include "ScanApi.h"

#include <algorithm>
#include <cstring>
#include <memory>
#include <tuple>

#include <mmintrin.h>
#include <xmmintrin.h>

#include <sys/time.h>

void ScanApi::simdScan8(Node* node) {
	int curPart = node->value.getPart();

	__m64 data_vec;
	__m64 converted_pred1 = _mm_set_pi8(scan_param, scan_param, scan_param, scan_param,
			scan_param, scan_param, scan_param, scan_param);

	//converted_pred1 += (int8_t) this->scan_param;

	uint64_t cur_result = 0;
	int count = 0;

	uint8_t* bit_vector = this->bit_result + this->slots_per_partition; //offset to the proper location
	uint64_t *compressed_data = this->partition_data[curPart];

	int dataInd = 0;
	int i = 0;
	int cnt = 0;

	/*hrtime_t t_start, t_end;
	t_start = gethrtime();*/

	for (int slot_id = 0; slot_id < this->slots_per_partition; slot_id++){
		data_vec = (__m64) (compressed_data[slot_id]);
		bit_vector[slot_id] = (uint8_t) _mm_movemask_pi8(_mm_cmpeq_pi8(data_vec, converted_pred1));

		cnt = __builtin_popcountl(bit_vector[slot_id]);
		count += cnt;
	}

	//t_end = gethrtime();

	printf("Partition count: %d\n", count);
}
