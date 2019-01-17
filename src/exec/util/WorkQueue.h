#ifndef __workqueue_h__
#define __workqueue_h__

#include <atomic>
#include <pthread.h>
#include <list>
#include <unordered_map>
#include <algorithm>

#include "thread/Thread.h"

using namespace std;

class WorkQueue {
	int mq_id;

	Node* headNode;

	atomic<Node*> head;
	atomic<Node*> tail;
public:
	WorkQueue() {
		this->mq_id = -1;
		Query dummy;
		headNode = new Node(dummy);
		head.store(headNode);
		tail.store(head.load());
	}

	WorkQueue(int q_id) {
		this->mq_id = q_id;
		Query dummy;
		headNode = new Node(dummy);
		head.store(headNode);
		tail.store(head.load());
	}

	WorkQueue(const WorkQueue &source) {
		this->mq_id = source.mq_id;
		this->headNode = source.headNode;

		head.store(source.head.load(std::memory_order_relaxed));
		tail.store(source.tail.load(std::memory_order_relaxed));
	}

	~WorkQueue() {
		delete headNode;
	}

	Node* getHead() {
		return head.load(std::memory_order_relaxed);
	}

	Node* getTail() {
		return tail.load(std::memory_order_relaxed);
	}

	bool isNotEmpty(){
		return (getHead() != getTail());
	}

	void printQueue() {
		Node* curNode = head.load(std::memory_order_relaxed);
		curNode = curNode->next;
		while (curNode != NULL) {
			printf("(%d : %d) - ", curNode->value.getPart(),
					curNode->value.getJobType());
			curNode = curNode->next;
		}
		printf("\n");
	}

	void add(Node *node) {
		while (true) {
			Node *last = tail;
			Node *next = (last->next).load(std::memory_order_relaxed);
			if (last == tail) {
				if (next == NULL) {
					if ((last->next).compare_exchange_weak(next, node)) {
						//printf("First...\n");
						//printQueue();
						tail.compare_exchange_weak(last, node);
						return;
					}
				} else {
					//printf("Second...\n");
					tail.compare_exchange_weak(last, next);
				}
			}
		}
	}

	Node* nextElement() {
		while (true) {
			Node *first = head.load(std::memory_order_relaxed);
			Node *last = tail.load(std::memory_order_relaxed);
			Node *next = (first->next).load(std::memory_order_relaxed);
			if (first == head) {
				if (first == last) {
					if (next == NULL) {
						//tail.compare_exchange_weak(last, next);
						printf("Queue is empty!\n!");
						return NULL;
					}
					tail.compare_exchange_weak(last, next);
				} else{
					if (head.compare_exchange_weak(first, next)) {
						return next;
					}
				}
			}
		}
	}

	int getId() {
		return mq_id;
	}
};

#endif
