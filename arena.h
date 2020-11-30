#ifndef LIBGRAPHS_ARENA_H
#define LIBGRAPHS_ARENA_H

#define THRESHOLD 10

typedef struct arena_struct {
    /* pointer to previous areana */
    struct arena_struct *prev;
    /* begin of availability to allocate 
        on the previous arena chunk */
    char *avail;
    /* limit of the chunk form the previous arena */
    char *limit;
} Arena;

/* The size of this union gives the minimum alignment 
   on the host machine. */
union align {
    int i;
    long l;
    long *lp;
    void *p;
    void (*fp)(void);
    float f;
    double d;
    long double ld;
};

union header {
    Arena *b;
    union align a;
};

extern void *arena_alloc(Arena *arena, long nbytes, 
                  const char *file, int line);
extern void *arena_calloc(Arena *arena, long count, long nbytes,
                    const char *file, int line);
extern void arena_free(Arena *arena);
extern void arena_dispose(Arena **ap);

#endif