
\def\title{GRAPH}

@* Introduction. {\sc GRAPH} is the core module used 
in this project. It contains the main data structures 
 to represent a graph. The module has the following
 structure:

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
files (see Input section). 

@ The \&{Vertex} structure has a name to identify it and 
 a adjacency list representing the destination of the arcs.
  The |name| is a pointer to the element of the array |names| 
  in the \&{Graph} structure where the array index is equal to
  the vertex index.

@<exported types@>=
typedef struct vertex_struct {
    /* Pointer to the vertex name in Graph.names */
    char *name;
    /* Adjacency list */
    struct arc_struct *arcs;
} Vertex;
  
@ During the graph initialization, the number of arcs is known 
  upfront by the assignment of attribute ``{\tt narcs}'' in 
  the graph data file. With this information in hand, the exact memory 
  needed may be allocated. It's not so flexible but it allows an
  improvement in the memory locality of the arcs elements in the array.

@<exported types@>=
typedef struct arc_struct {
    Vertex *tip;
    struct arc_struct *next; /* linked list of arcs pointers */
} Arc;

@ A new arc is retrieved from the |Graph| |arcs| variable and 
returned as a pointer. The |Vertex| |v| is set to the new |Arc|
|tip| field. A assertion of capacity to add a new arc is performed.

@<static functions@>=
static Arc *new_arc(Graph *g, Vertex *v) {
    Arc *a;

    assert(g->m < g->acap);

    a = &g->arcs[g->m++];
    a->tip = v;
    a->next = NULL;

    return a;
}

@ To add an |Arc| to |Vertex| |u| with index |from|, 
|Vertex| |v| with index |to| is added in the 
adjacency list of |u| that is represented by the 
|arcs| field. There is no verification of duplicity 
of arcs and the arcs' length or weight are not considered.

@<functions@>=
Arc *graph_add_arc(Graph *g, long from, long to) {
    Arc *a, *b;
    Vertex *u, *v;

    assert(from < g->n && to < g->n);

    u = &g->vertices[from];
    v = &g->vertices[to];

    a = new_arc(g, v);
    b = u->arcs;
    u->arcs = a;
    a->next = b;

    return a;
}

@ @<exported functions@>=
extern Arc*graph_add_arc(Graph*, long from, long to);

@ |Graph| type is composed of array of vertices, array 
of arcs, array of vertices' names, size information about 
these arrays and a Boolean to inform if the names are present. 
Sometimes one may wish to create a graph without names to 
speed up the initialization or simply to load a integer graph, 
where the vertices has their indices as representation.

@<exported types@>=
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

@ Memory for \&{Graph}s are created and released by 
|graph_new| and |graph_free| respectively.

@<exported types@>=
extern struct graph *graph_new(char *name, long nvertices,
                                long narcs, int load_names);
extern void graph_free(Graph*);

@ |Graph| type concentrates most of the data needed to 
store its information. The number of vertices must be
passed as parameter to allocate the number of vertices 
and an array to store the vertices' names. The arcs are
also allocated upfront as an array and then used by 
|Vertex| type as a pointer to its value location. 
The vertices' names loading is optional and the Boolean
variable |load_names| controls this behavior.

@<functions@>=
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

@ We tried to concentrate the allocated variables in the 
|Graph| type to stick the memory freed to few possible 
points in the code.

@<functions@>=
void graph_free(Graph *g) {
    if (g) {
        if (g->arcs)
            free(g->arcs);

        if (g->vertices)
            free(g->vertices);

        if (g->has_names && g->names)
            free(g->names);

        free(g);
    }
}

@ @<exported functions@>=
extern Name*graph_index_name(Graph*, long index, char*name);

@ If the graph field |has_names| is set to true, the 
vertices' name are copied to |names| array in the graph 
where the array index is also the vertex index and the 
limit in the string to be copied is set according to 
|MAXNAME|. The |Vertex| type uses a pointer to its name 
in the array of |names| to set its field |name|.

@<functions@>=
Name *graph_index_name(Graph *g, long idx, char *name) {
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

@ |Name| type wrap a string that represents the |Vertex| 
name. It is used in the |names| array graph field to store 
the vertices' names.

@<exported types@>=
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
int lineno=0; /* line number */

@ A |buffer| with macro |MAXLINE| as size is used to read 
the characters of the input file.

@d MAXLINE 512

@<functions@>=
Graph *graph_read(const char *filename, int load_names) {
    FILE *fp;
    Graph *g;
    int ctx = ATTRS; /* starting context */
    static char graph_name[MAXNAME];
    @<local data@>@;    

    fp = fopen(filename, "r");
    if (fp == NULL) {
        fprintf(stderr, "Could not open %s\n", filename);
        exit(EXIT_FAILURE);
    }
    buffer = (char*)calloc(MAXLINE+1, sizeof(char));
    while (fgets((char*)buffer, MAXLINE, fp)) {
        lineno++;
        
        if (buffer[0] == '\r' || buffer[0] == '\n')
            continue;

        cp = &buffer[0];

        if (is_line_a_context_switcher(cp, &ctx)) {
            if (ctx==VERTICES)
                @<create the graph@>@;

            continue;
        }

        if (ctx == ATTRS)
            @<extract the value from key-value pair@>@;
        else if (ctx == VERTICES) {
            if (g->has_names) {
                index_vertex_name(g, cp);
            }
        } else if (ctx == ARCS)
            add_arcs(g, cp, lineno);
        else {
            fprintf(stderr, "unknown context %d\n", ctx);
            exit(EXIT_FAILURE);
        }
    }
    free(buffer);
    fclose(fp);

    return g;
}

@ Check if the line contains a context switch.

@<static functions@>=
static int is_line_a_context_switcher(char *ln, int *ctx) {
    int i;
    
    for (i=1; i<=ARCS; i++)
        if(strstr(ln, context_marks[i]) != NULL) {
            *ctx = i;
             return 1;
        }
    return 0;
}

@ @<create the graph@>=
 {
     strncpy(name_buf, filename, MAXNAME);
     extract_graph_name(name_buf, graph_name);
     g = graph_new(graph_name, nverts, narcs, load_names);
 }

@ The graph name is extracted from the input file name 
after leaving only the relative path and striping the
extension.

@<static functions@>=
static void extract_graph_name(char *filename, char buffer[]) {        
    int i=0;
    char *c;

    c = filename;
    while (*c != '.' || !*c) {
        if (*c == '/' || *c == '\\') {
            i = 0;
            c++;
            continue;
        }
        buffer[i++] = *c++;
    }
    buffer[i] = '\0';
}

@ @<internal data@>=
 /* key and value */
char name_buf[MAXNAME];

@ @<local data@>=
long val;
 /* number of vertices */ 
long nverts;
/* number of arcs */
long narcs; 

@ @<extract the value...@>=
{
    sscanf(buffer, "%256[^=]=%ld", name_buf, &val);
    if (strncmp(name_buf, attr_num_names[VERTICES], MAXNAME)==0) {
        nverts = val;
        assert(nverts > 0);
    } else if (strncmp(name_buf, attr_num_names[ARCS], MAXNAME)==0) {
        narcs = val;
        assert(narcs > 0);
    } else {
        fprintf(stderr, "found \"%s=%ld\" as attribute at line %d", 
                name_buf, val, lineno);
    }
}

@ @<static functions@>=
static void index_vertex_name(Graph *g, char *str) {
    long idx;

    sscanf(str, "%ld %256[^\n]", &idx, name_buf);
    assert(idx >= 0);
    graph_index_name(g, idx, &name_buf[0]);
}

@ @<static functions@>=
void add_arcs(Graph *g, char *ln, long lineno) {
    int i;
    long from=-1, to=-1;

    i = 0;
    while (1) {
        if (!*ln) {
            @<throw error due wrong arcs list syntax@>@;
        }

        name_buf[i++] = *ln++;
 
        if (*ln == ':') {
            name_buf[i] = '\0';
            i = 0;
            from = atol(name_buf);
            ln++;
            continue;
        }

        if (*ln == ',' || *ln == '\n') {
            if (from == -1) {
                @<throw error due wrong arcs list syntax@>@;
            }
            name_buf[i] = '\0';
            i = 0;
            to = atol(name_buf);
            (void)graph_add_arc(g, from, to);
            
            if (*ln == '\n')
                break;
        
            ln++;
        }
    }
}
 
@ @<throw error due wrong arcs list syntax@>=
{
    fprintf(stderr, "FATAL: wrong sysntax at line %ld, ", lineno);
    fprintf(stderr, "expecting something like \"0:1,2,3\", ");
    exit(EXIT_FAILURE);
}