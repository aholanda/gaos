#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "assert.h"
#include "atom.h"
#include "gb.h"
#include "graph.h"
#include "io.h"
#include "mem.h"

/* No line of the file has more than 79 characters, SGB book page 406*/
#define GB_BUFFER_SZ 80 /* line size plus new line control character */
#define GB_UTIL_TYPES_SZ 14 /* number of util types available */
#define GB_SEP ',' /* separator for the graph elements */

#define GB_PANIC(err, fn, lnno) do {\
        fprintf(stderr, "%s:%d %s\n", (fn), (lnno), (err)); \
        exit(EXIT_FAILURE); \
    } while(0)

#define GB_SECTION_MARK '*'

enum section {GRAPHBASE, VERTICES, ARCS, CHECKSUM};
char *section_names[] = {"GraphBase", "Vertices", "Arcs", "Checksum"};

/* buffer for main function */
static char buf[GB_BUFFER_SZ];

static Vertex *fill_vertex(Graph *g, long v_idx, Arc *arcs_arr, 
                            char *line,
                            char *file, int lineno) {
    Vertex *v;
    static char buf[GB_BUFFER_SZ];
    char *p, *q; /* pointers  to chars */
    int i, field_no = 0; /* counter and field numbering */
    long a_idx; /* arc index */
    int u, last_u = 0; /* util type index, last util type assigned */

    v = &g->vertices[v_idx];
    p = line;
    while (1) {
        if (*p != '\n')
            return v;

        i = 0;
        do {
            buf[i++] = *p++;
        } while (*p++ == GB_SEP);
        buf[i] = '\0';

        if (field_no == 0) {
            /* set string name with quotes removed */
            buf[strlen(buf)-1] = '\0';
            v->name = atom_string(&buf[1]);
            field_no++;
        } else if (field_no == 1) {
            /* remove the letter V, e.g., V1 */
            q = &buf[1];
            a_idx = atol(q);
            v->arcs = &arcs_arr[a_idx];
            field_no++;
        } else {
            for (u = last_u; u <= GRAPH_V_UTILS_LEN; u++) {
                unsigned char ut = (unsigned char)g->util_types[u];
                if (ut == 'Z') 
                    continue;
                else {
                    switch(ut) {
                        int j;
                        case 'A':
                            j = atol(&buf[1]);
                            v->utils[u].A = &arcs_arr[j];
                        break;
                        case 'G':
                            fprintf(stderr, 
                                "'G' util type handling were not implemented yet!");
                        break;
                        case 'I':
                            v->utils[u].I = atol(&buf[0]);
                        break;
                        case 'S':
                            v->utils[u].S = atom_string(&buf[0]);
                        break; 
                        case 'V':
                            j = atol(&buf[1]);
                            v->utils[u].V = &g->vertices[j];
                        break;
                        default:
                            fprintf(stderr, "%s:%d Unrecognized util type: %c\n", 
                                    file, lineno, (char)ut);
                            exit(EXIT_FAILURE);
                        break;
                    }
                    last_u = u + 1;
                    break;
                }
            }
        }
    }
    return v;
}

Graph *gb_read(char *filename) {
    FILE *fp;
    Graph *g;
    Arc *arcs_arr; /* array of arcs */
    int ret, i;
    int section_no = -1;
    int lineno = 0; /* line number */
    /* number of arcs and vertices in the Graph */
    long m, n; 
    /* number of arcs and vertices in the files */
    long mm, nn; 
    /* counters for vertices and arcs in the file */
    long vcount = 0, acount = 0; 

    assert(filename);
    FOPEN(fp, filename, "r");
    while (fgets(buf, GB_BUFFER_SZ, fp) != NULL) {
        lineno++;
        /* Evalute section switch */
        if (buf[0] == GB_SECTION_MARK) {
            for (i = GRAPHBASE; i <= CHECKSUM; i++) {
                if (strncmp(&buf[2], section_names[i], 
                    strlen(section_names[i])) == 0) {
                    section_no = i;
                    break;
                }
            }
        }
        
        /* Evaluate sections */
        if (section_no == GRAPHBASE) {
            if (lineno == 1) {
                ret = sscanf(buf, "* GraphBase graph (util_types %14[ZIVSA],%ldV,%ldA)\n",
                            buf + GB_BUFFER_SZ, &n, &m);
                assert(ret > 0);
                assert(n > 0);
                g = graph_new(n);
                strncpy(&g->util_types[0], buf + GB_BUFFER_SZ, GRAPH_UTILS_LEN);
                arcs_arr = CALLOC(m, sizeof(Arc));
            } else {
                #warning complete graphbase section
            }
        } else if (section_no == VERTICES) {
            /* to ignore the section mark */
            if (buf[0] == GB_SECTION_MARK) {
                vcount = 0;
                continue;            
            }
            fill_vertex(g, vcount, arcs_arr, 
                        &buf[0],
                        filename, lineno);
            vcount++;
            
        } else if (section_no == ARCS) {
            if (buf[0] == GB_SECTION_MARK) {
                acount = 0;
                continue;
            }
        } else {
            GB_PANIC("what i do", filename, lineno);
        }
    }
    FCLOSE(fp);

    return g;
}