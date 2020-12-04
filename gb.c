#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "assert.h"
#include "atom.h"
#include "gb.h"
#include "graph.h"
#include "io.h"
#include "mem.h"

#define GB_UTIL_TYPES_SZ 14 /* number of util types available */

enum section {GRAPHBASE, VERTICES, ARCS, CHECKSUM};
char *section_names[] = {"GraphBase", "Vertices", "Arcs", "Checksum"};

/* buffer for characters in each line of the gb file */
static char line[GB_MAXLINE];

static Vertex *get_vertex_ptr(Graph *g, char field[],
                        char *file, int lineno) {
    long i;
    Vertex *w;

    /* 
        GraphBase format allows a vertex have a value 
        1 to use the vertex as a Boolena type where NULL
        is false and 0x1 is true.
    */

    if (strlen(&field[0]) == 1) {
        i = atol(&field[0]);
        if (i == 0)
              w = NULL;
        else if (i == 1)
            w = (Vertex *)0x1;
        else {
            fprintf(stderr, "%s:%d Unrecognized vertex value %s\n", 
                    file, lineno, &field[0]);
            exit(EXIT_FAILURE);                                    
        }
    } else {
        i = atol(&field[1]);
        w = &g->vertices[i];
    }
    return w;
}

static Arc *get_arc_ptr(Arc *arcs_arr, char field[],
                        char *file, int lineno) {
    long i;
    Arc *a;

    if (strlen(&field[0]) == 1) {
        i = atol(&field[0]);
        if (i == 0)
              a = NULL;
        else {
            fprintf(stderr, "%s:%d Unrecognized util value %s\n", 
                    file, lineno, &field[0]);
            exit(EXIT_FAILURE);                                    
        }
    } else {
        i = atol(&field[1]);
        a = &arcs_arr[i];
    }
    return a;
}

static void fill_utils (Graph *g, Vertex *v, Arc *a, 
                        Arc *arcs_arr, char u_label, int u_idx,
                        char field[],
                        char *file, int lineno) {
    Vertex *w;
    Arc *b;
    long i;
    char *s;

    if (u_label == 'Z') 
        return;
    else {
        switch(u_label) {
            case 'A':
                b = get_arc_ptr(arcs_arr, field, file, lineno);               
                if (v != NULL)
                    v->utils[u_idx].A = b;
                else if (a != NULL)
                    a->utils[u_idx].A = b;
                else
                    g->utils[u_idx].A = b;
            break;
            case 'G':
                fprintf(stderr, 
                        "'G' util type handling were not implemented yet!");
            break;
            case 'I':
                i = atol(&field[0]);
                if (v != NULL)
                    v->utils[u_idx].I = i;
                else if (a != NULL)
                    a->utils[u_idx].I = i;
                else
                    g->utils[u_idx].I = i;
            break;
            case 'S':
                s = atom_string(&field[0]);
                if (v != NULL)
                    v->utils[u_idx].S = s;
                else if (a != NULL)
                    a->utils[u_idx].S = s;
                else
                    g->utils[u_idx].S = s;                
            break; 
            case 'V':
                w = get_vertex_ptr(g, &field[0], file, lineno);
                if (v != NULL)
                    v->utils[u_idx].V = w;
                else if (a != NULL)
                    a->utils[u_idx].V = w;
                else
                    g->utils[u_idx].V = w;                
            break;
            default:
                fprintf(stderr, "%s:%d Unrecognized util type: %c\n", 
                        file, lineno, (char)u_label);
                exit(EXIT_FAILURE);
            break;
        }
    }
}

/* 
    Calculate de index limit of the last element that has 
    a label different from 'Z'
*/
static int get_last_util_idx(Graph *g, int begin, int end) {
    int i, stop = 0;

    for (i = begin; i < end; i++) {
        if (g->util_types[i] == 'Z')
            continue;
        else
            stop = i;
    }
    return stop;
}


static Graph *fill_graph(Graph *g, char data[], Arc *arcs_arr,
                         char *file, int lineno) {
    /* buffer length is due long graph ids */
    static char buf[ATOM_MAX_LEN];
    int i = 0, field_no = 0;
    int u = 0;/* utils index */
    int stop; /* where to stop the parsing based on util_types */
    char *p, *plim; /* pointer do char data and the limit for the pointer */

    stop = get_last_util_idx(g, GRAPH_V_UTILS_LEN+GRAPH_A_UTILS_LEN, 
                             GRAPH_UTILS_LEN);

    p = &data[0];
    plim = &data[0] + strlen(&data[0]);
    while (1) {
        i = 0;
        while (p <= plim) {
            /* ignore control chars and unquote strings */
            if (*p == '\n' || *p == '\\' || *p == '"') {
                *p++;
                continue;
            }
            if (*p == GB_SEP) {
                *p++;
                buf[i] = '\0';
                break;
            }
            buf[i++] = *p++;
        }         

        if (field_no == 0) {          
            g->id = atom_string(&buf[0]);
            field_no++;
        } else if (field_no == 1) {
            g->n = atol(&buf[0]);
            field_no++;
        } else if (field_no == 2) {
            g->m = atol(&buf[0]);
            field_no++;
        } else {
            if (u < GRAPH_G_UTILS_LEN) {
                char ut = 
                    g->util_types[GRAPH_V_UTILS_LEN + GRAPH_A_UTILS_LEN + u];
                if (ut != 'Z')  
                    fill_utils(g, NULL, NULL, arcs_arr, ut, u,
                               &buf[0], file, lineno);
                u++;
            }
        }
        if ((GRAPH_V_UTILS_LEN + GRAPH_A_UTILS_LEN + u - 1) == stop)
            break;
    }
    return g;
}

static Vertex *fill_vertex(Graph *g, long v_idx, Arc *arcs_arr, 
                            char *line,
                            char *file, int lineno) {
    Vertex *v;
    static char buf[GB_MAXLINE];
    char *p; /* pointer  to char */
    int i, field_no = 0; /* counters and field numbering */
    int u = 0, last_u = 0; /* util type index, last util type assigned */
    int stop = 0; /* signal to stop the line parsing */

    v = &g->vertices[v_idx];
    p = line;
    while (1) {
        i = 0;
        do {
            /* unquote strings */
            if (*p == '"') {
                *p++;
                continue;
            }

            if (*p == '\n') {
                stop = 1;
                break;
            }

            buf[i++] = *p++;
        } while (*p != GB_SEP);
        /* skip comma separator and reinitialize buffer */
        *p++, buf[i] = '\0'; 

        if (field_no == 0) {
            v->name = atom_string(&buf[0]);
            field_no++;
        } else if (field_no == 1) {
            /* remove the letter V, e.g., V1 */
            v->arcs = get_arc_ptr(arcs_arr, buf, file, lineno);
            field_no++;
        } else {
            for (u = last_u; u < GRAPH_V_UTILS_LEN; u++) {
                char ut = g->util_types[u];
                
                if (ut == 'Z')
                    continue;
                               
                 fill_utils(g, v, NULL, arcs_arr, ut, u,
                            &buf[0], file, lineno);
                 break;                    
            }
            last_u = u + 1;
        }
        if (stop)
            break;
    }
    return v;
}

static Arc *fill_arc(Graph *g, long a_idx, Arc *arcs_arr, 
                            char *line,
                            char *file, int lineno) {
    Arc *a;
    static char buf[GB_MAXLINE];
    char *p; /* pointer  to char */
    int i, field_no = 0; /* counters and field numbering */
    int u = 0, last_u = 0; /* util type index, last util type assigned */
    int stop = 0; /* signal to stop the line parsing */

    a = &arcs_arr[a_idx];
    p = line;
    while (1) {
        i = 0;
        do {
            if (*p == '\n') {
                stop = 1;
                break;
            }

            buf[i++] = *p++;
        } while (*p != GB_SEP);
        /* skip comma separator and reinitialize buffer */
        *p++, buf[i] = '\0'; 

        if (field_no == 0) {
            /* set the tip of the arc */
            a->tip = get_vertex_ptr(g, &buf[0], file, lineno);
            field_no++;
        } else if (field_no == 1) {
            /* next arc in the list */
            a->next = get_arc_ptr(arcs_arr, &buf[0], file, lineno);
            field_no++;
        } else if (field_no == 2) {
            /* get the arc len */
            a->len = atol(&buf[0]);
            field_no++;
        } else {
            for (u = last_u; u < GRAPH_A_UTILS_LEN; u++) {
                char ut = g->util_types[GRAPH_V_UTILS_LEN + u];
            
                if (ut == 'Z')
                    continue;

                fill_utils(g, NULL, a, arcs_arr, ut, u,
                        &buf[0], file, lineno);
                break;
            }
            last_u = u + 1;                            
        }
        if (stop)
            break;
    }
    return a;
}

Graph *gb_read(char *filename) {
    FILE *fp;
    Graph *g;
    Arc *arcs_arr; /* array of arcs */
    /* Store strings that starts on the second line
        containing graph attributes;
     */
    static char g_attrs_buf[ATOM_MAX_LEN+256];
    int ret, i;
    int section_no = -1;
    int lineno = 0; /* line number */
    /* number of arcs and vertices in the Graph */
    long m, n; 
    /* counters for vertices and arcs in the file */
    long vcount = 0, acount = 0; 

    assert(filename);
    FOPEN(fp, filename, "r");
    while (fgets(line, GB_MAXLINE, fp) != NULL) {
        lineno++;
        /* Evalute section switch */
        if (line[0] == GB_SECTION_MARK) {
            for (i = GRAPHBASE; i <= CHECKSUM; i++) {
                if (strncmp(&line[2], section_names[i], 
                    strlen(section_names[i])) == 0) {
                    section_no = i;
                    break;
                }
            }
        }
        
        /* Evaluate sections */
        if (section_no == GRAPHBASE) {
            if (lineno == 1) {
                ret = sscanf(line, "* GraphBase graph (util_types %14[ZIVSA],%ldV,%ldA)\n",
                            line + GB_MAXLINE, &n, &m);
                assert(ret > 0);
                assert(n > 0);
                g = graph_new(n);
                strncpy(&g->util_types[0], line + GB_MAXLINE, GRAPH_UTILS_LEN);
                arcs_arr = CALLOC(m, sizeof(Arc));
            } else {
                strncat(g_attrs_buf, line, GB_MAXLINE);
            }
        } else if (section_no == VERTICES) {
            /* to ignore the section mark */
            if (line[0] == GB_SECTION_MARK) {
                vcount = 0;
                g = fill_graph(g, g_attrs_buf, arcs_arr,
                                filename, lineno);
                continue;            
            }
            fill_vertex(g, vcount, arcs_arr, 
                        &line[0],
                        filename, lineno);
            vcount++;            
        } else if (section_no == ARCS) {
            if (line[0] == GB_SECTION_MARK) {
                acount = 0;
                continue;
            }
            fill_arc(g, acount, arcs_arr, 
                        &line[0],
                        filename, lineno);
            acount++;                            
        } else if (section_no == CHECKSUM) {
            long checksum = 0;
            sscanf(&line[0], "* Checksum %ld\n", &checksum);
#warning handle checksum
        } else {
            GB_PANIC("gb file seems not to obey the specs", filename, lineno);
        }
    }
    FCLOSE(fp);

    return g;
}