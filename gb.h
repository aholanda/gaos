#ifndef LIBGRAPHS_GB_H
#define LIBGRAPHS_GB_H

#include "graph.h"

extern Graph*gb_read(char *filename);
extern void gb_write(Graph *graph);

#endif