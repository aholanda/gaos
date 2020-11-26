#include <stdio.h>
#include <stdlib.h>

#include "assert.h"
#include "mem.h"

static void mem_exit(const char *file, int line) {
    fprintf(stderr, "%s:%d Allocation failed\n", file, line);
    exit(EXIT_FAILURE);
}

void *mem_alloc(long nbytes, const char *file, int line) {
    void *ptr; 

    assert(nbytes > 0);

    ptr = calloc(1, nbytes);
    if (ptr == NULL)
        mem_exit(file, line);

    return ptr;
}
void *mem_calloc(long count, long nbytes, const char *file, int line) {
    void *ptr; 

    assert(count > 0);
    assert(nbytes > 0);

    ptr = calloc(count, nbytes);
    if (ptr == NULL)
        mem_exit(file, line);

    return ptr;
}
void mem_free(void *ptr, const char *file, int line) {
    if (ptr)
        free(ptr);
}

void *mem_resize(void *ptr, long nbytes, const char *file, int line) {
    assert(ptr);
    assert(nbytes > 0);

    ptr = realloc(ptr, nbytes);
    if (ptr == NULL)
        mem_exit(file, line);

    return ptr;
}
