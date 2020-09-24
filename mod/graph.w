
\def\title{GRAPH}

@* Introduction. {\sc GRAPH} is the core module used 
in this project. It contains the main data structures 
 to represent a graph. 

@p
#include <stdio.h>
#include <stdlib.h>
@h@#
#include "graph.h"

@<types@>@;
@<static functions@>@;
@<functions@>@;

@ The exported types and functions are declared in the 
header file \.{graph.h}. The standard headers for assertion
functions, input/output and string handling are included 
 to be used along the \.{graph.h}.

@(graph.h@>=
#ifndef __GRAPH_H__
#define __GRAPH_H__

#include <assert.h>
#ifdef SYSV
#include <string.h>
#else
#include <strings.h>
#endif
#include <stdio.h>
#include <stdlib.h>

@<exported types@>@;
@<exported functions@>@;

#endif

@* Data structures. The basic types of {\sc GRAPH} module
are \&{Vertex}, \&{Arcs} and \&{Graph}. The data structures 
adapt to the format of graph representation in the data 
files (see {\tt input} module for the format description). 

@ The \&{Vertex} structure has a name to identify it and 
 a array of indices representing the destination of the arcs.
  The |name| is a pointer to string buffer an address where 
  the begining of the string representing the name is located.
  During the graph initialization, the number of arcs is known 
  by the second field of each element in the ``{\tt * arcs}''
  section. With this information in hand, the exact memory 
  needed may be allocated.

@<exported types@>=
typedef long Arc;
typedef struct vertex_struct {
    char *name; /* name of the vertex */
    long *arcs; /* array of indices */
    long m; /* number of arcs from this vertex */
} Vertex;

@ @<functions@>=
Vertex *vertex_new(Graph *g, char *name, long narcs) {
    Vertex *v;

    assert(g);
    assert(name);
    assert(narcs > 0);

    v = &g->vertices[g->n++];
    v->name = strbuf_save(g, name);
    v->arcs = calloc(narcs, sizeof(Arc));
    v->m = 0;

    return v;
}

@ @<functions@>=
void vertex_add_arc(Vertex *v, Arc a) {
    assert(v);
    assert(a >= 0);

    v->arcs[v->m++] = a;

    return v;
}

@ @<exported types@>=
typedef struct graph {
    char *name;
    /* List of vertices where the array index is also 
       the vertex index. */
    Vertex *vertices;
    /* A buffer for strings, mainly, names */
    char *strbuf;
    long n; /* number of vertices */
    long m; /* number of arcs */
} Graph;

@ @<exported functions@>=
extern struct graph *graph_new(char *name, long nvertices,
                                long strbuf_size);
extern void graph_free(Graph*);

@ @<functions@>=
Graph *graph_new(char *name, long nvertices,
                        long strbuf_size) {
    Graph *g;

    assert(nvertices > 0);
    assert(strbuf_size > 0);

    g = (Graph*)calloc(1, sizeof(Graph));
    g->vertices = calloc(nvertices, sizeof(Vertex));
    g->strbuf = strbuf_new(strbuf_size);
    g->n = 0;
    g->m = 0;

    assert(g && g->vertices && g->strbuf);
    return g;
}

@ @<functions@>=
void graph_free(Graph *g) {
    Vertex *v;
    long i;

    if (g) {
        for (i=0; i<g->n; i++) {
            v = &g->vertices[i];
            if (v->arcs)
                free(v->arcs)
        }
        if (g->strbuf)
            strbuf_free(g->strbuf);

        if (g->vertices)
            free(g->vertices);
    }
}

@ @<types@>=
typedef struct strbuf_struct {
    /* starting of where to copy the strings */
    char *buffer;
    /* point to the next available space */
    char *next_avail;
    /* string buffer capacity */
    size_t cap;
} StrBuf;

@ 

@d EXTRA_SPACE 256

@<static functions@>=
static char *strbuf_new(size_t capacity) {
    StrBuf *sb;

    sb = calloc(1, sizeof(StrBuf));
    sb->cap = capacity;
    sb->buffer = calloc(sb->cap + EXTRA_SPACE, sizeof(char));
    sb->next_avail = sb->buffer;
    return sb;
}

@ @<static functions@>=
static char *strbuf_save(StrBuf strbuf, const char *str) {
    char *p;
    size_t len;

    assert(g);
    assert(strbuf);
    assert(str);

    /* string length including NULL byte */
    len = strlen(str) + 1;
    /* pointer to the next available space */
    p = strbuf->next_avail;
    /* copy the string str to string buffer */
    p = strncpy(p, str, len);
    /* advance to the start of the available space */
    strbuf->next_avail += len;

     assert(strbuf->next_avail < strbuf->cap);

    return p;
}

@ @<static...@>=
static void strbuf_free(Strbuf *strbuf) {
    if (strbuf) {
        if (strbuf->buffer)
            free(strbuf->buffer);
        free(strbuf);
    }
}
