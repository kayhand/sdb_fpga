#include "ScanApi.h"

#include <algorithm>
#include <cstring>
#include <memory>
#include <tuple>

#include <immintrin.h>
#include <mmintrin.h>
#include <xmmintrin.h>

#include <sys/time.h>

int ScanApi::simdScan4(Node* node) {
	int curPart = node->value.getPart();

	__m64 data_vec;
	__m64 converted_pred1 = _mm_set_pi8(lower_param, lower_param, lower_param, lower_param,
			lower_param, lower_param, lower_param, lower_param);

	//converted_pred1 += (int8_t) this->lower_param;

	uint64_t cur_result = 0;
	int count = 0;
	int res_offset = curPart * this->ResBuffLen();

	uint8_t* bit_vector = ((uint8_t*)(*this->bit_result)) + res_offset; //offset to the proper location
	uint64_t *compressed_data = (uint64_t *) this->DataBlock(curPart);

	int dataInd = 0;
	int i = 0;
	int cnt = 0;

	/*hrtime_t t_start, t_end;
	t_start = gethrtime();*/

	for (int word_id = 0; word_id < this->ResBuffLen(); word_id++){
		data_vec = (__m64) (compressed_data[word_id]);

		bit_vector[word_id] = ~((uint8_t) _mm_movemask_pi8
				(_mm_cmpgt_pi8(data_vec, converted_pred1))); // LE

		cnt = __builtin_popcountl(bit_vector[word_id]);
		count += cnt;
	}

	//t_end = gethrtime();

	//printf("Count: %d - Offset: %d\n", count, res_offset);
	return count;
}

int ScanApi::simdScan8(int curPart) {

	__m64 data_vec;
	__m64 converted_pred1 = _mm_set_pi8(lower_param, lower_param, lower_param, lower_param,
			lower_param, lower_param, lower_param, lower_param);

	//converted_pred1 += (int8_t) this->lower_param;

	uint64_t cur_result = 0;
	int count = 0;
	int res_offset = curPart * this->ResBuffLen();

	//(uint64_t *) bit_result[res_offset] has 64 (res_buff_len) slots for each part
	//(uint8_t *) (bit_result[res_offset]) has 64 * 8 (res_buff_len * 8) slots for each part

	uint8_t* bit_vector = ((uint8_t *) (bit_result[res_offset]));
	uint64_t *compressed_data = (uint64_t *) this->DataBlock(curPart);

	int dataInd = 0;
	int i = 0;
	int cnt = 0;

	/*hrtime_t t_start, t_end;
	t_start = gethrtime();*/

	for (int word_id = 0; word_id < this->ResBuffLen() * 8; word_id++){
		data_vec = (__m64) (compressed_data[word_id]);

		bit_vector[word_id] = ~((uint8_t) _mm_movemask_pi8 (_mm_cmpgt_pi8(data_vec, converted_pred1))); // LE

		cnt = __builtin_popcountl(bit_vector[word_id]);
		count += cnt;
	}

	//t_end = gethrtime();

	//printf("Count: %d - Offset: %d\n", count, res_offset);
	return count;
}


int ScanApi::simdScan16(Node* node) {
	int curPart = node->value.getPart();

	__m64 data_vec1, data_vec2;
	__m64 converted_pred1 = _mm_set_pi16(lower_param, lower_param, lower_param, lower_param);

	uint64_t cur_result = 0;
	int count = 0;
	int res_offset = curPart * this->ResBuffLen();

	uint8_t* bit_vector = ((uint8_t*)(*this->bit_result)) + res_offset; //offset to the proper location
	uint64_t *compressed_data = (uint64_t *) this->DataBlock(curPart);

	int dataInd = 0;
	int i = 0;
	int cnt = 0;

	int input_id = 0;
	uint8_t temp_res;
	uint64_t mask = 0b10000000100000001000000010000000;
	for (int res_ind = 0; res_ind < this->ResBuffLen(); res_ind++){
		data_vec1 = (__m64) (compressed_data[input_id++]);
		//temp_res = ((uint8_t) _pext_u64((uint64_t) _mm_cmpgt_pi16 (data_vec1, converted_pred1),mask)) << 4;

		data_vec2 = (__m64) (compressed_data[input_id++]);
		//temp_res |= ((uint8_t) _pext_u64(_mm_cmpgt_pi16 (data_vec1, converted_pred1), mask));

		// data_vec1: [|val1|val2|val3|val4] -- each val is 16-bits
		// -> _mm_cmpgt_pi16 (data_vec1, pred)
		//  -> temp_res1: |11...1|00...0|00...0|11...1| // 64-bits
		//	 ->_pext_u64(temp_res1, mask) // (mask = 15, 31, 47, 63)
		// 		-> res: 1001

		// data_vec2: [|val5|val6|val7|val8] -- each val is 16-bits
		// -> _mm_cmpgt_pi16 (data_vec2, pred)
		//  -> temp_res2: |11...1|00...0|11...1|11...1|
		// 		-> res: 1011

		//bit_vector[res_ind] = 10011011

		bit_vector[res_ind] = ~temp_res; //GT to LE
		cnt = __builtin_popcountl(bit_vector[res_ind]);

		count += cnt;
	}

	//t_end = gethrtime();

	//printf("Count: %d - Offset: %d\n", count, res_offset);
	return count;
}


