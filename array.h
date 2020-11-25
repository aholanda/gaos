#ifndef LIBGRAPHS_ARRAY_H
#define LIBGRAPHS_ARRAY_H

typedef struct array_struct {
    long length; /* number of elements */
    long size; /* size of each element */
    char *array; /* the data elements*/
} Array;

extern Array *array_new(long length, int size);
extern void *array_get(Array *array, long i);
extern void *array_put(Array *array, long i, void *elem);
extern void array_free(Array **array);

#endif
