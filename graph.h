#ifndef LIBGRAPHS_GRAPH_H
#define LIBGRAPHS_GRAPH_H

#define GRAPH_VERTEX_UTILS_SZ 6
#define GRAPH_ARC_UTILS_SZ 2
#define GRAPH_UTILS_SZ 6

#include "arena.h"
#include "hashmap.h"

typedef union {
    struct vertex_struct *V;
    struct arc_struct *A;
    struct graph_struct *G;    
    char *S;
    long I;
} util;

typedef struct arc_struct {
    struct vertex_struct *tip;
    struct arc_struct *next;
    long len;
    util utils[GRAPH_ARC_UTILS_SZ];
} Arc;

typedef struct vertex_struct {
    char *name;
    Arc *arcs;
    util utils[GRAPH_VERTEX_UTILS_SZ];    
} Vertex;

typedef struct graph_struct {
    char *id;
    char util_types[15];
    Vertex *vertices;
    /* map vertex name to its pointer */
    HashMap *str2v;
    long n; /* number of vertices */
    long m; /* number of arcs */
    /* main place to allocate elements */
    Arena *data;
    util utils[GRAPH_UTILS_SZ];
} Graph;

extern Graph *graph_new(long nvertices);
extern void graph_add_arc (Graph *g, char *from, char *to, long len);
extern void graph_add_edge (Graph *g, char *from, char *to, long len);
extern long graph_order(Graph *g);
extern void graph_free(Graph *g);
#endif
