
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
enum {STRING=0, NAME=1, VERTICES=2, ARCS=3, LIMBO=NCTXS=4};

@ @<internal data@>=
static char *context_marks[NCTXS] = {
    "* string", "* name", "* vertices", "* arcs"
};

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

@ @<local data@>=
char *buffer;
char *cp; /* character pointer */
int lineno; /* line number */

@ A |buffer| with macro |MAXLINE| as size is used to read 
the characters of the input file.

@d MAXLINE 512

@<functions@>=
Graph *input_file(const char *filename) {
    FILE *fp;
    Graph *graph;
    int ctx = ATTRS; /* starting context */
    @<local data@>@;    

    fp = fopen(filename, "r");
    if (fp == NULL) {
        fprintf(stderr, "Could not open %s\n", filename);
        exit(EXIT_FAILURE);
    }
    buffer = (char*)calloc(MAXLINE+1, sizeof(char));
    while (fgets((char*)buffer, MAXLINE, fp)) {
        @<start parsing a new line@>@;

        if (is_comment(cp))
            continue;
        
        if (ctx == ATTRS)
            @<extract the value from key-value pair@>@;
        elsif (ctx == VERTICES)
            @<parse the line and add the new vertex to graph@>@;
        elsif (ctx == VERTICES)
            @<parse the line and add the arcs to vertex@>@;
        else {
            fprintf(stderr, "unknown context %d\n", ctx);
            exit(EXIT_FAILURE);
        }

        @<check if the line contains a context transition@>@;
    }
    free(buffer);
    fclose(fp);

    return graph;
}

@ @<skip spaces@>=
{
    while (isspace(cp))
        cp++;
}

@ @<start parsing a new line@>=
{
    lineno++;
    cp = &buffer[0];
}

@ Lines that begin with '\#' are ignored during the parsing.

@d COMMENT_SYM '#'

@<static functions@>=
static int is_comment(char *cp) {
    @<skip spaces@>@;
    return *cp == COMMENT_SYM;
}

@ @<check if the line contains a context transition@>=
{
    register int i;
    for (i=0; i<NCTXS; i++)
        if(strstr(cp, context_marks[i]) != NULL) {
            ctx = i;
            break;
        }
    
    if (ctx==VERTICES)
        @<create the graph@>@;
}

@ @<create the graph@>=
 {
     graph = graph_new(graph_name, nverts, nchars);
 }

@ <local...@>=
/* name to assign to the graph */
char graph_name[MAXTOKEN];
 /* key and value in string representation of them */
char *keyval[2];
 /* number of vertices */ 
long nverts;
/* number of characters to be used in the graph string buffer */
long nchars; 

@ @<extract the value...@>=
{
    keyval = extract_keyval(cp, keyval);
    if (strncmp(keyval[0], attrs[NAME], MAXTOK)==0) {
        strncpy(graph_name, keyval[1], MAXTOK);
    } elsif (strncmp(keyval[0], attrs[NVERTS], MAXTOK)==0) {
        nverts = atol(keyval[1]);
        assert(nverts > 0);
    }  elsif (strncmp(keyval[0], attrs[NCHARS], MAXTOK)==0) {
        nverts = atol(keyval[1]);
        assert(nchars > 0);
    } else {
        fprintf(stderr, "found \"%s=%s\" as attribute at line %d", 
                lineno, keyval[0], keyval[1]);
    }
}

@ @<static...@>=
static char *extract_keyval(char *line, char *keyval[], char sep) {
    char *tok; /* token string */
    char *rkv; /* replica of keyval */
    int i=0;

    /* duplicate the line string */
    rkv = strndup(cp, MAXTOK);
    while ((tok = strtok_r(rkv, "=\t\r\n", &rkv)))
        keyval[i] = tok;

#warning remove this printf    
    printf("%s\n", tok);

    return tok;
}

@ @<local...@>=
long vid; /* vertex identification */

@ @<parse the line and add the new vertex to graph@>=
{
    keyval = extract_keyval(cp, keyval, " ");
    vid = atol(keyval[0]);
    vertex_new(vid, name);
}

@ @<parse the line and add the arcs to vertex@>=
{
    /* key-value for "vertex_id,number_of_arcs" part */
    register char *keyval0;
    keyval = extract_keyval(cp, keyval, ":");
    keyval0 = strndup(keyval[0], MAXTOK);
    vid = atol(keyval[0]);
    vertex_new(id, name);
}