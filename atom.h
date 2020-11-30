#ifndef LIBGRAPHS_ATOM_H
#define LIBGRAPHS_ATOM_H

#define ATOM_MAXSZ 256

extern char *atom_new(char *str, int len);
extern char *atom_string(char *str);
extern void atom_free();

#endif