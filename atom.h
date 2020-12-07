#ifndef LIBGRAPHS_ATOM_H
#define LIBGRAPHS_ATOM_H

#define ATOM_MAX_LEN 256

typedef struct atom {
    struct atom *link;
    int len;
    char *str;
} Atom;


extern char *atom_new(Atom *buckets[], int nbuckets, char *str, int len);
extern char *atom_string(Atom *buckets[], int nbuckets, char *str);
extern void atom_free(Atom *buckets[], int nbuckets);

#endif