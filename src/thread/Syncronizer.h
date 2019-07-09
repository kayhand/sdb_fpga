#ifndef __syncronizer_h__
#define __syncronizer_h__

#include "util/PThreadBarrier.h"

#ifndef __APPLE__
#include <pthread.h>
#endif

#include <atomic>

class Syncronizer {
	pthread_barrier_t start_barrier;
	pthread_barrier_t end_barrier;

	pthread_barrier_t fpga_barrier;

	std::atomic<int> agg_counter;

public:
	Syncronizer(int num_of_workers) {
		initBarriers (num_of_workers);
	}

	void initBarriers(int num_of_workers) {
		pthread_barrier_init(&start_barrier, NULL, num_of_workers);
		pthread_barrier_init(&fpga_barrier, NULL, num_of_workers);
		pthread_barrier_init(&end_barrier, NULL, num_of_workers);
	}

	void initAggCounter(int num_of_parts) {
		agg_counter = ATOMIC_VAR_INIT(num_of_parts);
	}

	void decrementAggCounter() {
		agg_counter--;
	}

	bool isQueryDone() {
		return agg_counter == 0;
	}

	void waitOnStartBarrier() {
		pthread_barrier_wait(&start_barrier);
	}

	void waitOnFPGABarrier() {
		pthread_barrier_wait(&fpga_barrier);
	}

	void waitOnEndBarrier() {
		pthread_barrier_wait(&end_barrier);
	}

	void destroyBarriers() {
		pthread_barrier_destroy(&start_barrier);
		pthread_barrier_destroy(&fpga_barrier);
		pthread_barrier_destroy(&end_barrier);
	}

};

#endif
