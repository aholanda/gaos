#ifndef LIBGRAPHS_GRAPH_H
#define LIBGRAPHS_GRAPH_H

#define GRAPH_V_UTILS_LEN 6
#define GRAPH_A_UTILS_LEN 2
#define GRAPH_G_UTILS_LEN 6
#define GRAPH_UTILS_LEN (GRAPH_V_UTILS_LEN \
    + GRAPH_A_UTILS_LEN + GRAPH_G_UTILS_LEN)

#include "atom.h"
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
    util utils[GRAPH_A_UTILS_LEN];
} Arc;

typedef struct vertex_struct {
    char *name;
    Arc *arcs;
    util utils[GRAPH_V_UTILS_LEN];    
} Vertex;

typedef struct graph_struct {
    char *id;
    /* number of utils type label plus null value */
    char util_types[GRAPH_UTILS_LEN + 1];
    Vertex *vertices;
    /* Store strings without repetition */
    Atom **buckets;
    int nbuckets; /* number of buckets for Atom */
    /* map vertex name to its pointer */
    HashMap *str2v;
    long n; /* number of vertices */
    long m; /* number of arcs */
    util utils[GRAPH_G_UTILS_LEN];
} Graph;

extern Graph *graph_new(long nvertices);
extern void graph_add_arc (Graph *g, char *from, char *to, long len);
extern void graph_add_edge (Graph *g, char *from, char *to, long len);
extern Arc *graph_arcs_get(Graph *g, long i);
extern long graph_order(Graph *g);
extern long graph_size(Graph *g);
extern void graph_free(Graph *g);
#endif
