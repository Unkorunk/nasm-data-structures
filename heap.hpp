#pragma once

#include <cstdint>

extern "C"
{
	__declspec(dllimport) void *heap_create(uint64_t capacity);
	__declspec(dllimport) void heap_destroy(void *heap);
	__declspec(dllimport) void *heap_reserve(void *heap, uint64_t capacity);
	__declspec(dllimport) void *heap_build(void *data, uint64_t length);
	__declspec(dllimport) void *heap_push(void *heap, uint64_t key);
	__declspec(dllimport) void heap_pop(void *heap);
	__declspec(dllimport) uint64_t heap_top(void *heap);
	__declspec(dllimport) uint64_t heap_capacity(void *heap);
	__declspec(dllimport) uint64_t heap_size(void *heap);
	__declspec(dllimport) bool heap_empty(void* heap);
}
