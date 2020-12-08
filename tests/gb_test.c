#include <stdio.h>

#include "../assert.h"
#include "../gb.h"
#include "../graph.h"
#include "../mem.h"

static void gb_test() {
    Graph *g;    

    g = gb_read("foo.gb");
    gb_write(g, "/tmp/foo.gb");
}

int main(int argc, char**argv) {
    gb_test();
    return 0;
}