@* Linux components.

@p
#include <stdlib.h>

#include "graph.h"

int main(int argc, char **argv) {
    Graph *g;

    g = graph_read("data/linux-1.0.dat", 0);

    graph_free(g);

    return EXIT_SUCCESS;
}