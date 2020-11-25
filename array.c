#include <string.h>

#include "array.h"
#include "assert.h"
#include "mem.h"

Array *array_new(long length, int size) {
    Array *ary;
    
    assert(length > 0);
    assert(size > 0);

    NEW(ary);
    ary->size = size;
    ary->length = length;
    ary->array = CALLOC(length, size);

    return ary;
}

void *array_get(Array *array, long i) {
    assert(array);
    assert(i >= 0 && i < array->length);
    return array->array + i*array->size;
}

void *array_put(Array *array, long i, void *elem) {
    assert(array);
    assert(i >= 0 && i < array->length);
    assert(elem);
    memcpy(array->array + i*array->size, elem, array->size);

    return array->array + i*array->size;
}

long array_size(Array *array) {
    assert(array);
    return array->size;
}

long array_length(Array *array) {
    assert(array);
    return array->length;
}

void array_free(Array **array) {
    assert(array && *array);
    FREE((*array)->array);
    FREE(*array);
}