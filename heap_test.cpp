#define CATCH_CONFIG_MAIN
#define CATCH_CONFIG_ENABLE_BENCHMARKING

#include <catch.hpp>
#include <heap.hpp>

#include <queue>
#include <Windows.h>

TEST_CASE("Test #1") {
	SYSTEM_INFO si;
	GetSystemInfo(&si);

	const DWORD capacity_divider = si.dwPageSize >> 3;

	void* my_heap = heap_create(10);
	REQUIRE(my_heap != nullptr);
	REQUIRE(heap_size(my_heap) == 0);
	REQUIRE(heap_empty(my_heap));
	REQUIRE((heap_capacity(my_heap) + 2) % capacity_divider == 0);

	for (int i = 0; i < 10000; i++) {
		const uint64_t old_capacity = heap_capacity(my_heap);
		const uint64_t old_size = heap_size(my_heap);

		REQUIRE(old_capacity >= old_size);

		my_heap = heap_push(my_heap, rand());

		const uint64_t new_capacity = heap_capacity(my_heap);
		const uint64_t new_size = heap_size(my_heap);

		REQUIRE(old_size + 1 == new_size);
		if (old_capacity == old_size) {
			REQUIRE(new_capacity > old_capacity);
		} else {
			REQUIRE(new_capacity == old_capacity);
		}

		REQUIRE((new_capacity + 2) % capacity_divider == 0);
	}

	heap_destroy(my_heap);
}

TEST_CASE("Test #2") {
	std::priority_queue<uint64_t> pq;
	void* my_heap = heap_create(0);
	for (int k = 0; k < 10000; k++) {
		const int action = rand() % 6;
		if (action < 3) {
			uint64_t rnd = rand();
			pq.push(rnd);
			my_heap = heap_push(my_heap, rnd);
		} else if (action == 3) {
			bool pq_empty = pq.empty();
			bool my_heap_empty = heap_empty(my_heap);
			REQUIRE(pq_empty == my_heap_empty);
			if (!pq_empty) {
				pq.pop();
				heap_pop(my_heap);
			}
		} else if (action == 4) {
			bool pq_empty = pq.empty();
			bool my_heap_empty = heap_empty(my_heap);
			REQUIRE(pq_empty == my_heap_empty);
			if (!pq_empty) {
				uint64_t pq_top = pq.top();
				uint64_t my_heap_top = heap_top(my_heap);
				REQUIRE(pq_top == my_heap_top);
			}
		} else if (action == 5) {
			uint64_t pq_size = pq.size();
			uint64_t my_heap_size = heap_size(my_heap);
			REQUIRE(pq_size == my_heap_size);
		}
	}
	heap_destroy(my_heap);
}

TEST_CASE("Test #3") {
	std::priority_queue<uint64_t> pq;
	std::vector<uint64_t> data(10000);
	for (size_t i = 0; i < data.size(); i++) {
		uint64_t rnd = rand();
		pq.push(rnd);
		data[i] = rnd;
	}

	void* my_heap = heap_build(data.data(), data.size());

	while (!pq.empty() && !heap_empty(my_heap)) {
		REQUIRE(pq.top() == heap_top(my_heap));
		pq.pop();
		heap_pop(my_heap);
	}

	heap_destroy(my_heap);
}

TEST_CASE("Benchmark #1") {
	BENCHMARK("std push 10000") {
		std::priority_queue<uint64_t> pq;
		for (int k = 0; k < 10000; k++) {
			pq.push(rand());
		}
	};

	BENCHMARK("push 10000") {
		void* my_heap = heap_create(0);
		for (int k = 0; k < 10000; k++) {
			my_heap = heap_push(my_heap, rand());
		}
		heap_destroy(my_heap);
	};

	BENCHMARK("std push / std pop 10000") {
		std::priority_queue<uint64_t> pq;
		for (int k = 0; k < 10000; k++) {
			pq.push(rand());
		}
		for (int k = 0; k < 10000; k++) {
			pq.pop();
		}
	};

	BENCHMARK("push / pop 10000") {
		void* my_heap = heap_create(0);
		for (int k = 0; k < 10000; k++) {
			my_heap = heap_push(my_heap, rand());
		}
		for (int k = 0; k < 10000; k++) {
			heap_pop(my_heap);
		}
		heap_destroy(my_heap);
	};

	BENCHMARK("push / pop 10000 (pre-allocated capacity)") {
		void* my_heap = heap_create(10000);
		for (int k = 0; k < 10000; k++) {
			my_heap = heap_push(my_heap, rand());
		}
		for (int k = 0; k < 10000; k++) {
			heap_pop(my_heap);
		}
		heap_destroy(my_heap);
	};
}

TEST_CASE("Benchmark #2") {
	BENCHMARK("std push 100000") {
		std::priority_queue<uint64_t> pq;
		for (int k = 0; k < 100000; k++) {
			pq.push(rand());
		}
	};

	BENCHMARK("push 100000") {
		void* my_heap = heap_create(0);
		for (int k = 0; k < 100000; k++) {
			my_heap = heap_push(my_heap, rand());
		}
		heap_destroy(my_heap);
	};

	BENCHMARK("std push / std pop 100000") {
		std::priority_queue<uint64_t> pq;
		for (int k = 0; k < 100000; k++) {
			pq.push(rand());
		}
		for (int k = 0; k < 100000; k++) {
			pq.pop();
		}
	};

	BENCHMARK("push / pop 100000") {
		void* my_heap = heap_create(0);
		for (int k = 0; k < 100000; k++) {
			my_heap = heap_push(my_heap, rand());
		}
		for (int k = 0; k < 100000; k++) {
			heap_pop(my_heap);
		}
		heap_destroy(my_heap);
	};

	BENCHMARK("push / pop 100000 (pre-allocated capacity)") {
		void* my_heap = heap_create(100000);
		for (int k = 0; k < 100000; k++) {
			my_heap = heap_push(my_heap, rand());
		}
		for (int k = 0; k < 100000; k++) {
			heap_pop(my_heap);
		}
		heap_destroy(my_heap);
	};
}
