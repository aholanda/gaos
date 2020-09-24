
@* Input. The input file contains the graph description 
in a customized format where the main concern is to have
upfront the size of the memory to be allocated for each 
graph element. The size of the string buffer, the number 
of vertices and the number of arcs for each vertex in the 
adjacency list is explicitly presented. An example of the
file format is presented as follows:

\smallskip
\begingroup
\obeylines\tt
* string
20

* name
mygraph

* vertices
0 foo
1 bar
2 baz

* arcs
0,2: 1 2
1,1: 2
2,0:
\endgroup\smallskip

The changing in the context are marked by the symbol ``*''. The first 
part is called {\tt string} and in the next line is presented the value 
for the context. This value represents the number of characters in the 
vertices' names and graph name plus the {\tt NULL} terminator for each 
name. The value is used to allocate memory for a string buffer and load 
the strings in an unique place. Any element that uses a name in the string 
buffer, catch a pointer the the begining of the string representing the 
name in the string buffer.

The section ``{\tt * name}'' holds the graph name to be assigned to the 
{\tt name} field of \&{Graph} structure. In the section ``{\tt * vertices}''
there is a listing of the graph's vertices. The first field represents the 
vertex index and the second the vertex name. The default separator is a space.

The section ``{\tt *arcs}'' presents an adjacency list to represent the arcs 
in the graph. The graph of function call is considered to be directed. The 
first field element is the vertex index and after the comma is the number 
of arcs that goes from the vertex. After the colon, there is a list of 
 vertices' indices representing the tip of an arc separated by space. 
 No arc length is considered because the number of calls of a function to 
 another can be aproximated to one, more than one calls to the same function
 is not common.

@<types@>=
enum {LIMBO=00, STRING=01, NAME=02, VERTICES=04, ARCS=010};

@ @p
#include <ctype.h>
#include <stdio.h>
#include <stdlib.h>

#include "input.h"

@<types@>@;
@<internal data@>@;
@<functions@>@;

@ @(input.h@>=
#ifndef __INPUT_H__
#define __INPUT_H__

#include "graph.h"

extern Graph *read_file(const char *filename);
extern Graph **read_dir(const char *dirname);

#endif

@ A |buffer| with macro |MAXLINE| as size is used to read 
the characters of the input file.

@d MAXLINE 512

@<internal data@>=
static unsigned char buffer[MAXLINE+1];
static char *cp; /* character pointer */
static int lineno; /* line number */

@ @<functions@>=
Graph *input_file(const char *filename) {
    FILE *fp;
    Graph *graph;
    int ctx = LIMBO; /* context in file */

    fp = fopen(filename, "r");
    if (fp == NULL) {
        fprintf(stderr, "Could not open %s\n", filename);
        exit(EXIT_FAILURE);
    }
    while (fgets((char*)buffer, MAXLINE, fp)) {
        newline();

        if (is_comment())
            continue;
        
    }
    fclose(fp);

    return graph;
}

@ @<static functions@>=
static void skip_space() {
    while (isspace(cp))
        cp++;
}

static void newline() {
    lineno++;
    cp = &buffer[0];
    skip_space();
}

@ Lines that begin with '\#' are ignored during the parsing.

@d COMMENT_SYM '#'

@<static functions@>=
static int is_comment() {
    return *cp == COMMENT_SYM;
}