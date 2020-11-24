#ifndef LIBGRAPHS_HASHMAP_H
#define LIBGRAPHS_HASHMAP_H

typedef struct hashmap_struct {
    int size; /* number of buckets */
    /* function used for keys comparison */
    int (*cmp)(const void *x, const void *y);
    /* function to compute the position in the bucket of the key */
    /* if collision occurs the entry is inserted in a linked list */
    /* in the same bucket */
    unsigned (*hash)(const void *key);
    struct binding {
        /* points to the next entry in the same bucket */
        struct binding *link;
        const void *key;
        void *value;        
    } **buckets;
    int length; /* number of bindings in the map */
    /* every time map is changed timestamp is incremented */
    unsigned timestamp;    
} HashMap;

extern HashMap *hashmap_new(int hint,
        int cmp(const void *x, const void *y),
        unsigned hash(const void *key));
extern void *hashmap_get(HashMap *map, const void *key);
extern void *hashmap_put(HashMap *map, const void *key, void *value);
extern void *hashmap_remove(HashMap *map, const void *key);
extern int hashmap_length(HashMap *map);
extern void hashmap_free(HashMap *map);

#endif