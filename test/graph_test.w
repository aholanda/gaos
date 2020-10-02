@* Linux components.

@p
#include <stdlib.h>

#include "graph.h"

int main(int argc, char **argv) {
    Graph *g;
    Vertex *v;
    Arc *a;
    long i;

    g = graph_read("data/sample.dat", 1);

    printf("G(%s)\n", g->name);
    for (i=0; i<g->n; i++) {
        v = &g->vertices[i];
        printf("%s:", v->name);

        for (a=v->arcs; a; a = a->next) {
            printf(" %s", a->tip->name);
        }
        printf("\n");
    }
    graph_free(g);

    return EXIT_SUCCESS;
}
