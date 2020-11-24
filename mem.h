#ifndef LIBGRAPHS_MEM_H
#define LIBGRAPHS_MEM_H

/* Code based on the book "C Interfaces and Implementations" by Dave Hanson */

#define ALLOC(nbytes) \
    mem_alloc((nbytes), __FILE__, __LINE__)
#define CALLOC(count, nbytes) \
    mem_alloc((count), (nbytes), __FILE__, __LINE__)
#define FREE(ptr) \
    mem_alloc((ptr), __FILE__, __LINE__)
#define RESIZE(ptr, nbytes) \
    mem_alloc((ptr), (nbytes), __FILE__, __LINE__)
/* Aliases to allocate and initialize a variable */
#define NEW(p) ((p) = ALLOC((long)sizeof *(p)))
/* Initialize and zeroed the variables */
#define NEW0(p) ((p) = CALLOC(1, (long)sizeof *(p)))

extern void *mem_alloc(long nbytes, const char *file, int line);
extern void *mem_calloc(long count, long nbytes, const char *file, int line);
extern void mem_free(void *ptr, const char *file, int line);
extern void *mem_resize(void *ptr, long nbytes, const char *file, int line);

#endif
