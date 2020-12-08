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
                s = atom_string(g->buckets, g->nbuckets, &field[0]);
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

static void fwrite_separator(FILE *fp) {
    fputc(GB_SEP, fp);
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
            g->id = atom_string(g->buckets, g->nbuckets, &buf[0]);
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
            v->name = atom_string(g->buckets, g->nbuckets, &buf[0]);
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

/*******************************************************************/
/*                WRITE GRAPH TO FILE                              */
/*WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW*/
static void fwrite_arc(FILE *fp, HashMap *a2aidx, Arc **arcs_parr, Arc *a) {
    Arc *a_idx; 

    a_idx = hashmap_get(a2aidx, a);
    fprintf(fp, "A%ld",  &a_idx - &arcs_parr[0]);
}

static void fwrite_vertex(FILE *fp, Graph *g, Vertex *v) {
    long i;

    i = v - &g->vertices[0];
    fprintf(fp, "V%ld", i);
}

static void fwrite_util_value(FILE *fp, Graph *g, char ut, util *pu,
            HashMap *a2aidx, Arc **arcs_parr) {
    switch(ut) {
        case 'A':
            fwrite_arc(fp, a2aidx, arcs_parr, (*pu).A);
        break;
        case 'I':
            fprintf(fp, "\"%ld\"", (*pu).I);
        break;
        case 'S':
            fprintf(fp, "\"%s\"", (*pu).S);
        break;
        case 'V':
            fwrite_vertex(fp, g, (*pu).V);
        break;
        default:
        break;
    }
}

static void fwrite_utils(FILE *fp, Graph*g, Vertex *v, Arc *a, 
                        HashMap *a2aidx, Arc **arcs_parr) {
    int u;
    char ut; /* util type label */
    util *pu;
    int offset = 0; /* number of indices to advance */
    enum section sec = -1;

    if (a != NULL)
        sec = ARCS;
    else if (v != NULL)
        sec = VERTICES;
    else
        sec = GRAPHBASE;
    
    switch (sec) {
        case GRAPHBASE:
            offset = GRAPH_V_UTILS_LEN+GRAPH_A_UTILS_LEN;
            for (u = offset; u < GRAPH_UTILS_LEN; u++) {
                ut = g->util_types[u];
                if (ut != 'Z') {
                    pu = &g->utils[u - offset];
                    fwrite_util_value(fp, g, ut, pu, a2aidx, arcs_parr);
                    fwrite_separator(fp);
                }
            }
        break;
        case VERTICES:
            assert(v);
            offset = 0;
            for (u = offset; u < GRAPH_A_UTILS_LEN; u++) {
                ut = g->util_types[u];
                if (ut != 'Z') {
                    pu = &v->utils[u - offset];
                    fwrite_util_value(fp, g, ut, pu, a2aidx, arcs_parr);
                    fwrite_separator(fp);
                }
            }
        break;
        case ARCS:
            assert(a);
            offset = GRAPH_V_UTILS_LEN;
            for (u = offset; u < offset + GRAPH_A_UTILS_LEN; u++) {
                ut = g->util_types[u];
                if (ut != 'Z') {
                    pu = &a->utils[u - offset];
                    fwrite_util_value(fp, g, ut, pu, a2aidx, arcs_parr);
                    fwrite_separator(fp);
                }
            }
        break;
        case CHECKSUM:
#warning checksum not implemented yet
        break;
        default:
            fprintf(stderr, "Unrecognized section %d\n", (int)sec);
            exit(EXIT_FAILURE);
        break;        
    }
    /* switch the last separator by new line */
    fseek(fp, -1, SEEK_CUR);
    fputc('\n', fp);
}

static void fwrite_graphbase_section(FILE *fp, Graph *g) {
    int ret = 0;
    static char buf[GB_MAXLINE];
    char *p0, *p, *plim; /* pointer to buffer start, current and limit */

    /* 1st line */
    /* 
        In the first line we use g->n and g->type what is different
        from SGB that uses the allocated blocks.
     */
    ret = snprintf(&buf[0], GB_MAXLINE, 
                   "* GraphBase graph (util_types %14s,%ldV,%ldA)\n",
                   g->util_types, g->n, g->m);
    fprintf(fp, "%s", &buf[0]);
    assert(ret > 0);

    /* graph attributes */
    assert(g->id);    
    p0 = &g->id[0];
    plim = p0 + strlen(&g->id[0]);
    fputc('"', fp); /* start quote */
    for (p = &g->id[0]; p < plim; p++) {
        /* continue on the next line*/
        if ((p - p0) == 58) {
            fputc('\\', fp);
            fputc('\n', fp);
        }
        fputc(*p, fp);
    }
    fputc('"', fp); /* end the quote */    
    fwrite_separator(fp);
    fputc('\n', fp); /* put the attributes and util types in a new line */

    /* effective number of vertices */
    fprintf(fp, "%ld", g->n);
    fwrite_separator(fp);
 
    /* effective number of arcs */
    fprintf(fp, "%ld", g->m);    
    fwrite_separator(fp);

    fwrite_utils(fp, g, NULL, NULL, NULL, NULL);
    fflush(fp);   
}

static void fwrite_vertices_section(FILE *fp, Graph *g, HashMap *a2aidx, Arc **arcs_parr) {
    Vertex *v;
    Arc *a;

    fprintf(fp, "* %s\n", section_names[VERTICES]);
    for (v = &g->vertices[0]; v < &g->vertices[0] + g->n; v++) {
        a = v->arcs;
        /* Name */
        if (v->name) {
            fprintf(fp, "\"%s\"", v->name);
            fwrite_separator(fp);  
        } else {
            fprintf(fp, "\"0\"");
            fwrite_separator(fp);  
        }

        if (a == NULL) {
            /* next arc */
            fprintf(fp, "0");
            fwrite_separator(fp);
        } else {
            fwrite_arc(fp, a2aidx, arcs_parr, a);
        }
        fwrite_utils(fp, g, v, NULL, a2aidx, arcs_parr);
    }
}

static void fwrite_arcs_section(FILE *fp, Graph *g, HashMap *a2aidx, Arc **arcs_parr) {
    Vertex *v = NULL;
    Arc *a;

    fprintf(fp, "* %s\n", section_names[VERTICES]);
    for (a = arcs_parr[0]; &a < &arcs_parr[0] + g->m; a++) {
        a = a->next;
        if (a == NULL) {
            fprintf(fp, "0");
            fwrite_separator(fp);
            /* Length */
            fprintf(fp, "0");
            fwrite_separator(fp);  
        } else {
            fwrite_arc(fp, a2aidx, arcs_parr, a);
            /* Length */
            fprintf(fp, "%ld", a->len);
            fwrite_separator(fp);
        }
        fwrite_utils(fp, g, v, NULL, a2aidx, arcs_parr);
    }
}

void gb_write(Graph *g, char *filename) {
    FILE *fp;
    Vertex *v;
    Arc *a = 0;
    long acount = 0; /* arc counter */
    /* Array of pointer to arcs to numbering them */
    Arc **arcs_parr;
    /* Map arc pointers to their address in the array of arc pointer */
    HashMap *a2aidx;

    assert(g);
    assert(filename);

    FOPEN(fp, filename, "w");

    fwrite_graphbase_section(fp, g);
    FCLOSE(fp);
    return;

    a2aidx = hashmap_new(g->m, NULL, NULL);
    arcs_parr = (Arc **)CALLOC(g->m, sizeof(Arc *));
    for (v = &g->vertices[0]; v < &g->vertices[0] + g->n; v++)
        for (a = v->arcs; a; a = a->next) {
            arcs_parr[acount] = a;
            hashmap_put(a2aidx, a, &arcs_parr[acount]);
            acount++;
        }
    fwrite_vertices_section(fp, g, a2aidx, arcs_parr);

    fwrite_arcs_section(fp, g, a2aidx, arcs_parr);

    FREE(arcs_parr);
    hashmap_free(&a2aidx);
    FCLOSE(fp);
}
