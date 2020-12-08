CC := clang
CFLAGS := -Wall -g

VPATH = .:tests/

LIB_OBJS += atom.o
LIB_OBJS += hashmap.o
LIB_OBJS += gb.o
LIB_OBJS += graph.o
LIB_OBJS += mem.o

libgraphs.a: $(LIB_OBJS)
	$(AR) rcs $@ $^

clean:
	$(RM) $(LIB_OBJS)

gb_test: gb_test.o libgraphs.a
	$(CC) $(CFLAGS) $^ -o $@