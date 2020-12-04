#ifndef LIBGRAPHS_GB_H
#define LIBGRAPHS_GB_H

#include "graph.h"

/* No line of the file has more than 79 characters, SGB book page 406*/
#define GB_MAXLINE 80 /* line size plus new line control character */
#define GB_SEP ',' /* separator for the graph elements */

#define GB_PANIC(err, fn, lnno) do {\
        fprintf(stderr, "%s:%d %s\n", (fn), (lnno), (err)); \
        exit(EXIT_FAILURE); \
    } while(0)

#define GB_SECTION_MARK '*'

extern Graph*gb_read(char *filename);
extern void gb_write(Graph *graph);

#endif