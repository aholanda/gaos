#include <limits.h>

#include "assert.h"
#include "hashmap.h"

/* default function to compare keys */
static int cmpatom(const void *x, const void *y) {
    return x != y;
}

/* default hash function */
static unsigned hashatom(const void *key) {
    return (unsigned long)key>>2;
}

HashMap *hashmap_new(int hint,
        int cmp(const void *x, const void *y),
        unsigned hash(const void *key)) {
    HashMap *map;
    int i;
    static int primes[] = {509, 509, 1021, 2053, 4093,
        8191, 16381, 32771, 65521, INT_MAX};

    assert(hint >= 0);
    for (i = 1; primes[i] < hint; i++) ;

    map = ALLOC(sizeof (*map) +
        primes[i-1]*sizeof (map->buckets[0]));
    map->size = primes[i-1];
    map->cmp = cmp ? cmp : cmpatom;
    map->hash = hash ? hash : hashatom;
    map->buckets = (struct binding **)(map + 1);
    for (i = 0; i < map->size; i++)
        map->buckets[i] = NULL;
    map->length = 0;
    map->timestamp = 0;

    return map;
}

static int index(HashMap *map, const void *key) {
    return (*map->hash)(key)%map->size;
}

static struct binding *search_key(HashMap *map, const void *key) {
    int i;
    struct binding *p;

    i = index(map, key);
    for (p = map->buckets[i]; p; p = p->link)
        if ((*map->cmp)(key, p->key) == 0)
            return p;

    return NULL;
}

void *hashmap_get(HashMap *map, const void *key) {
    struct binding *p;

    assert(map);
    assert(key);

    p = search_key(map, key);

    return p ? p->value : NULL;
}
void *hashmap_put(HashMap *map, const void *key, void *value) {
    int i;
    struct binding *p;
    void *prev;

    assert(map);
    assert(key);
    assert(value);

    p = search_key(map, key);
    if (p == NULL) {
        i = index(map, key);
        NEW(p);
        p->key = key;
        p->value = value;
        map->buckets[i] = p;
        map->length++;
        prev = NULL;
    } else {
        prev = p->value;
    }
    p->value = value;
    map->timestamp++;
    return prev;
}

void *hashmap_remove(HashMap *map, const void *key) {
    int i;
    struct binding **pp;

    assert(map);
    assert(key);
    map->timestamp++;

    i = index(map, key);
    for (pp = &map->buckets[i]; *pp; pp = &(*pp)->link)
        if ((*map->cmp)(key, (*pp)->key) == 0) {
            struct binding *p = *pp;
            void *value = p->value;
            *pp = p->link;
            FREE(p);
            map->length--;
            return value;
        }
    
    return NULL;
}


int hashmap_length(HashMap *map) {
    assert(map);

    return map->length;
}

void hashmap_free(HashMap **map) {
    assert(map && *map);

    if ((*map)->length > 0) {
        int i; 
        struct binding *p, *q;

        for (i = 0; i < (*map)->size; i++)
            for (p = (*map)->buckets[i]; p; p = q) {
                q = p->link;
                FREE(p);
            }
    }
    FREE(*map);
}