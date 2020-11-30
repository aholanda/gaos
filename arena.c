#include <stdlib.h>
#include <string.h>

#include "arena.h"
#include "assert.h"
#include "mem.h"

/* free chunks available */
static Arena *freechunks;
/* number of free chunks */
static int nfree;

Arena *arena_new(void) {
    Arena *arena;
    arena = ALLOC(sizeof (*arena));
    return arena;
}

static long alignment_roundup(long nbytes) {
    return ((nbytes + sizeof (union align) - 1)/
            (sizeof (union align)))*(sizeof (union align));
}

void *arena_alloc(Arena *arena, long nbytes, 
                  const char *file, int line) {
    Arena *ptr;
    char *limit;

    assert(arena);
    assert(nbytes > 0);
    
    nbytes = alignment_roundup(nbytes);
    while (nbytes > arena->limit - arena->avail) {
        /* get a new chunk */
        if ((ptr = freechunks) != NULL) {
            freechunks = freechunks->prev;
            nfree--;
            limit = ptr->limit;
        } else {
            long m = sizeof (union header) + nbytes + 10*1024;
            ptr = ALLOC(m);
            limit = (char*)ptr + m;
        }
        *ptr = *arena;
        arena->avail = (char *)((union header *)ptr + 1);
        arena->limit = limit;
        arena->prev = ptr;
    }
    arena->avail += nbytes;
    return arena->avail - nbytes;
}

void *arena_calloc(Arena *arena, long count, long nbytes,
                    const char *file, int line) {
    void *ptr;

    assert(count > 0);
    ptr = arena_alloc(arena, count*nbytes, file, line);
    memset(ptr, '\0', count*nbytes);
    return ptr;
}

void arena_free(Arena *arena) {
    assert(arena);

    while (arena->prev) {
        Arena tmp = *arena->prev;

        /* free the chunk described by arena */
        if (nfree < THRESHOLD) {
            arena->prev->prev = freechunks;
            freechunks = arena->prev;
            nfree++;
            freechunks->limit = arena->limit;
        } else
            FREE(arena->prev);

        *arena = tmp;
    }
    assert(arena->limit == NULL);
    assert(arena->avail == NULL);
}

void arena_dispose(Arena **ap) {
    assert(ap && *ap);

    arena_free(*ap);
    FREE(*ap);
    *ap = NULL;
}