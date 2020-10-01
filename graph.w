
\def\title{GRAPH}

@* Introduction. {\sc GRAPH} is the core module used 
in this project. It contains the main data structures 
 to represent a graph. 

@p
#include <ctype.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
@h@#
#include "graph.h"

@<types@>@;
@<internal data@>@;
@<static functions@>@;
@<functions@>@;

@ The exported types and functions are declared in the 
header file \.{graph.h}. The standard headers for assertion
functions, input/output and string handling are included 
 to be used along the \.{graph.h}.

@(graph.h@>=
#ifndef __GRAPH_H__
#define __GRAPH_H__

#include <assert.h>
#ifdef SYSV
#include <string.h>
#else
#include <strings.h>
#endif
#include <stdio.h>
#include <stdlib.h>

@<macros@>@;
@<exported types@>@;
@<exported functions@>@;

#endif

@* Data structures. The basic types of {\sc GRAPH} module
are \&{Vertex}, \&{Arcs} and \&{Graph}. The data structures 
adapt to the format of graph representation in the data 
files (see {\tt input} module for the format description). 

@ The \&{Vertex} structure has a name to identify it and 
 a array of indices representing the destination of the arcs.
  The |name| is a pointer to string buffer an address where 
  the begining of the string representing the name is located.
  
# warning write about the same index of vertices and names

@<exported types@>=
typedef struct vertex_struct {
    /* Pointer to the vertex name in Graph.names */
    char *name;
    /* Adjacency list */
    struct arc_struct *arcs;
} Vertex;
  
@ During the graph initialization, the number of arcs is known 
  by the second field of each element in the ``{\tt * arcs}''
  section. With this information in hand, the exact memory 
  needed may be allocated.

@<exported types@>=
typedef struct arc_struct {
    Vertex *tip;
    struct arc_struct *next; /* linked list of arcs pointers */
} Arc;

@ @<static functions@>=
static Arc *arc_new(Graph *g, Vertex *v) {
    Arc *a;

    assert(g->m+1 < g->acap);

    a = &g->arcs[g->m++];
    a->tip = v;
    a->next = NULL;

    return a;
}

@ @<functions@>=
Arc *graph_add_arc(Graph *g, long from, long to) {
    Arc *a, *b;
    Vertex *u, *v;

    assert(from < g->n && to < g->n);

    u = &g->vertices[from];
    v = &g->vertices[to];

    a = arc_new(g, v);
    b = u->arcs;
    u->arcs = a;
    a->next = b;

    return a;
}

@ @<exported types@>=
struct name_struct;
typedef struct graph {
    char name[MAXNAME];
    /* List of vertices where the array index is also 
       the vertex index. */
    Vertex *vertices;
    /* All arcs in the graph. */
    Arc *arcs;
    /* Capacity of arcs array */
    long acap;
    /* Boolean to indicate if the names were loaded. */
    int has_names;
    /* Map vertex index and its name */
    struct name_struct *names;
    long n; /* number of vertices */
    long m; /* number of arcs */
} Graph;

@ @<macros@>=
#define MAXNAME 256

@ @<exported functions@>=
extern struct graph *graph_new(char *name, long nvertices,
                                long narcs, int load_names);
extern void graph_free(Graph*);

@ @<functions@>=
Graph *graph_new(char *name, 
                 long nvertices,
                 long narcs,
                 int load_names) {
    Graph *g;

    assert(nvertices > 0);
    assert(narcs > 0);

    g = (Graph*)calloc(1, sizeof(Graph));
    strncpy(g->name, name, MAXNAME);
    g->n = nvertices;
    g->vertices = calloc(g->n, sizeof(Vertex));
    assert(g->vertices);
    g->acap = narcs;
    g->arcs = calloc(g->acap, sizeof(Arc));
    assert(g->arcs);
    g->m = 0;

    g->has_names = load_names;
    if (g->has_names) {
        g->names = calloc(g->n, sizeof(Name));
    }

    return g;
}

@ @<functions@>=
void graph_free(Graph *g) {
    if (g) {
        if (g->arcs)
            free(g->arcs);

        if (g->vertices)
            free(g->vertices);

        free(g);
    }
}

@ @<functions@>=
Name *graph_index_name(Graph *g, long idx, const char *name) {
    Name *n;
    Vertex *v;

    if (!g->has_names)
        return NULL;

    assert(idx < g->n);

    n = &g->names[idx];
    assert(n);
    strncpy(n->data, name, MAXNAME);

    /* Link the name to the vertex */
    v = &g->vertices[idx];
    v->name = n->data;

    return n;
}

@ @<exported types@>=
typedef struct name_struct {
    char data[MAXNAME];
} Name;

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
nvertices=3
narcs=4

* vertices
0 foo
1 bar
2 baz

* arcs
0:1,2
1:2
2:2
\endgroup\smallskip

@ The changing in the context are marked by the symbol ``*''. The first 
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

@ The section ``{\tt *arcs}'' presents an adjacency list to represent the arcs 
in the graph. The graph of function call is considered to be directed. The 
first field element is the vertex index and after the comma is the number 
of arcs that goes from the vertex. After the colon, there is a list of 
 vertices' indices representing the tip of an arc separated by space. 
 No arc length is considered because the number of calls of a function to 
 another can be aproximated to one, more than one calls to the same function
 is not common.

@<types@>=
enum {ATTRS=0, VERTICES=1, ARCS=2, NCTXS=ARCS+1};

@ @<internal data@>=
static char *context_marks[NCTXS] = {
    "", "* vertices", "* arcs"
};

@ The key name for the attributes that contains the 
number of elements, vertices or arcs, are assigned 
to |attr_num_names|, and retrieved according to the 
element that it is numbering.

@<internal data@>=
static char *attr_num_names[NCTXS] = {
    "", "nvertices", "narcs"
};

@ @<exported functions@>=
extern Graph *graph_read(const char *filename, int load_names);

@ @<local data@>=
char *buffer;
char *cp; /* character pointer */
int lineno; /* line number */

@ A |buffer| with macro |MAXLINE| as size is used to read 
the characters of the input file.

@d MAXLINE 512

@<functions@>=
Graph *graph_read(const char *filename, int load_names) {
    FILE *fp;
    Graph *g;
    int ctx = ATTRS; /* starting context */
    @<local data@>@;    

    fp = fopen(filename, "r");
    if (fp == NULL) {
        fprintf(stderr, "Could not open %s\n", filename);
        exit(EXIT_FAILURE);
    }
    buffer = (char*)calloc(MAXLINE+1, sizeof(char));
    while (fgets((char*)buffer, MAXLINE, fp)) {
        @<update variables...@>@;

        if (ctx == ATTRS)
            @<extract the value from key-value pair@>@;
        else if (ctx == VERTICES) {
            if (g->has_names) {
                @<index the vertex name to its index in the graph@>@;
            }
        } else if (ctx == ARCS)
            @<include the arcs in the adjacency list of a vertex@>@;
        else {
            fprintf(stderr, "unknown context %d\n", ctx);
            exit(EXIT_FAILURE);
        }
        @<check if the line contains a context transition@>@;
    }
    free(buffer);
    fclose(fp);

    return g;
}

@ @<skip spaces@>=
{
    while (isspace(cp))
        cp++;
}

@ @<update variables to start parsing a new line@>=
{
    lineno++;
    cp = &buffer[0];
}

@ @<check if the line contains a context transition@>=
{
    register int i;
    for (i=1; i<=ARCS; i++)
        if(strstr(cp, context_marks[i]) != NULL) {
            ctx = i;
            break;
        }
    
    if (ctx==VERTICES)
        @<create the graph@>@;
}

@ @<create the graph@>=
 {
#warning parse file name to extract graph name     
     register char* graph_name = "graph";
     g = graph_new(graph_name, nverts, narcs, load_names);
 }

@ @<local data@>=
 /* key and value */
char name[MAXNAME];
long val;
 /* number of vertices */ 
long nverts;
/* number of arcs */
long narcs; 

@ @<extract the value...@>=
{
    sscanf(buffer, "%s=%ld", name, &val);
    if (strncmp(name, attr_num_names[VERTICES], MAXNAME)==0) {
        nverts = val;
        assert(nverts > 0);
    } else if (strncmp(name, attr_num_names[ARCS], MAXNAME)==0) {
        narcs = val;
        assert(narcs > 0);
    } else {
        fprintf(stderr, "found \"%s=%ld\" as attribute at line %d", 
                name, val, lineno);
    }
}

@ @<index the vertex...@>=
{    
    sscanf(buffer, "%ld %s", &val, name);
    assert(val >= 0);
    graph_index_name(g, val, name);
}

@ @<include the arcs...@>=
{
    @<get the vertex index@>@;
    @<extract the arcs and add to adjacency list@>@;
}

@ @<local...@>=
int i;
long u, v;

@ @<get the vertex index@>=
i = 0;
 while (*cp || *cp != ':')
     name[i++] = *cp++;
 
 u = atol(name);

 @ @<extract the arcs...@>=
 while (*cp || *cp != '\n') {
    i = 0;
    while (*cp || *cp != ',')
        name[i++] = *cp++;
 
    v = atol(name);
    graph_add_arc(g, u, v);
 }
 