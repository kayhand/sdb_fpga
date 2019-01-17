#ifndef __syncronizer_h__
#define __syncronizer_h__

#include <pthread.h>
#include <atomic>

class Syncronizer {
	pthread_barrier_t start_barrier;
	pthread_barrier_t end_barrier;

	std::atomic<int> agg_counter;

public:
	Syncronizer() {}

	void initBarriers(int num_of_workers) {
		pthread_barrier_init(&start_barrier, NULL, num_of_workers);
		pthread_barrier_init(&end_barrier, NULL, num_of_workers);
	}

	void initAggCounter(int num_of_parts) {
		agg_counter = ATOMIC_VAR_INIT(num_of_parts);
	}

	void incrementAggCounter() {
		agg_counter--;
	}

	bool isQueryDone() {
		return agg_counter == 0;
	}

	void waitOnStartBarrier() {
		pthread_barrier_wait(&start_barrier);
	}

	void waitOnEndBarrier() {
		pthread_barrier_wait(&end_barrier);
	}

	void destroyBarriers() {
		pthread_barrier_destroy(&start_barrier);
		pthread_barrier_destroy(&end_barrier);
	}

};

#endif