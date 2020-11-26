#ifndef LIBGRAPHS_GRAPH_H
#define LIBGRAPHS_GRAPH_H

#include "array.h"
#include "hashmap.h"

#define FOREACH_VERTEX(v, g) \
    long i; \
    for (i = 0; i < (g)->n && (((v)=array_get(g->vertices, i)) != NULL); i++)

#define FOREACH_ARC(a, v) \
    for (a = v->arcs; a; a = a->next)


typedef struct arc_struct {
    struct vertex_struct *tip;
    struct arc_struct *next;
    int len;
} Arc;

typedef struct vertex_struct {
    char *name;
    Arc *arcs;
} Vertex;

typedef struct graph_struct {
    Array *vertices;
    HashMap *str2v;
    long n; /* number of vertices */
    long m; /* number of arcs */
} Graph;

extern Graph *graph_new(long nvertices);
extern void graph_add_arc (Graph *g, char *from, char *to, int len);
extern void graph_add_edge (Graph *g, char *from, char *to, int len);
extern long graph_order(Graph *g);
extern void graph_free(Graph *g);
#endif
