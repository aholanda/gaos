#ifndef LIBGRAPHS_IO_H
#define LIBGRAPHS_IO_H

#define FOPEN(fp, fn, mode) \
    do {\
        (fp) = fopen((fn), (mode)); \
        if (!(fp)) {\
            fprintf(stderr, "%s:%d Could not open %s\n", __FILE__, __LINE__, fn);\
            exit(EXIT_FAILURE); \
        } \
    } while (0)

#define FCLOSE(fp) if (fp) fclose(fp)

#endif