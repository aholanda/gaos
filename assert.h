#ifndef LIBGRAPHS_ASSERT_H
#define LIBGRAPHS_ASSERT_H

/* Code based on the book "C Interfaces and Implementations" by Dave Hanson */

#undef assert
#ifdef NDEBUG
#define assert(e) ((void)0)
#else
#include <stdio.h>
#include <stdlib.h>
extern void assert(int e);
#define assert(e) ((void)((e)||\
    (fprintf(stderr, "%s:%d: Assertion failed: %s\n", \
    __FILE__, (int)__LINE__, #e), abort(), 0)))
#endif

#endif