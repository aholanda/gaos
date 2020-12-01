#include <stdlib.h>
#include <string.h>

#include "assert.h"
#include "atom.h"
#include "graph.h"
#include "mem.h"

Graph *graph_new(long nvertices) {
    Graph *graph;
    static char id[ATOM_MAX_LEN];

    NEW(graph);
    sprintf(id, "graph(%ld)", nvertices);
    graph->id = atom_string(&id[0]);
    graph->vertices = CALLOC(nvertices, sizeof(Vertex));
    graph->str2v = hashmap_new(nvertices, NULL, NULL);
    strcpy(graph->util_types, "ZZZZZZZZZZZZZZ");
    graph->n = 0;
    graph->m = 0;

    return graph;
}

static Vertex *lookup_vertex(Graph *g, char *name) {
    Vertex *v;
    char *key;

    key = atom_string(name);
    v = (Vertex *)hashmap_get(g->str2v, key);
    if (v == NULL) {
        v = &g->vertices[g->n++];
        assert(v);
        v->name = key;
        v->arcs = NULL;
        hashmap_put(g->str2v, key, v);
    }
    return v;
}

static Arc *new_arc (Graph *g, Vertex *tip, int len) {
    Arc *arc;
    
    NEW(arc);
    arc->tip = tip;
    arc->len = len;
    return arc;
} 

void graph_add_arc (Graph *g, char *from, char *to, long len) {
    Vertex *v, *w;
    Arc *a, *b;

    v = lookup_vertex(g, from);
    w = lookup_vertex(g, to);

    a = new_arc(g, w, len);
    b = v->arcs;
    v->arcs = a;
    a->next = b;
    g->m++;
}

void graph_add_edge (Graph *g, char *from, char *to, long len) {
    graph_add_arc (g, from, to, len);

    /* avoid duplication due loop */
    if (strncmp(to, from, strlen(to)) != 0) {
        graph_add_arc (g, to, from, len);
        g->m--; /* eliminate double direction counting */
    }
}

long graph_order(Graph *g) {
    assert(g);
    return g->n;
}

void graph_free(Graph *g) {
    Vertex *v;
    Arc *a, *b;

    for (v = g->vertices; v < g->vertices + g->n; v++)
        for (a = v->arcs; a; a = b) {
            b = a->next;
            FREE(a);
        }
    hashmap_free(&g->str2v);
    atom_free();   
    FREE(g->vertices);
    FREE(g);
}