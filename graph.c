#include <stdlib.h>
#include <string.h>

#include "assert.h"
#include "atom.h"
#include "graph.h"
#include "mem.h"

Graph *graph_new(long nvertices) {
    Graph *g;

    NEW(g);
    g->vertices = array_new(nvertices, sizeof (Vertex));
    g->str2v = hashmap_new(nvertices, NULL, NULL);
    g->n = 0;
    g->m = 0;

    return g;
}

static Vertex *lookup_vertex(Graph *g, char *name) {
    Vertex *v;
    char *key;

    key = atom_string(name);
    v = (Vertex *)hashmap_get(g->str2v, key);
    if (v == NULL) {
        NEW(v);
        v->name = key;
        v->arcs = NULL;
        v = array_put(g->vertices, g->n++, v);
        hashmap_put(g->str2v, key, v);
    }
    return v;
}

void graph_add_arc (Graph *g, char *from, char *to, int len) {
    Vertex *v, *w;
    Arc *a, *b;

    v = lookup_vertex(g, from);
    w = lookup_vertex(g, to);

    NEW(a);
    a->tip = w;
    a->len = len;
    b = v->arcs;
    v->arcs = a;
    a->next = b;
    g->m++;
}

void graph_add_edge (Graph *g, char *from, char *to, int len) {
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
    long i, n;

    n = graph_order(g);
    for (i = 0; i < n; i++) {
        v = (Vertex*)array_get(g->vertices, i);
        for (a = v->arcs; a; a = b) {
            b = a->next;
            FREE(a);
        }
    }
    array_free(&g->vertices);
    hashmap_free(&g->str2v);
    FREE(g);
}