CFLAGS := -Wall -g

LIB_OBJS += hashmap.o
LIB_OBJS += mem.o

main: main.c $(LIB_OBJS)
	$(CC) $(CFLAGS) $^ -o $@

main.c: assert.h mem.h

clean:
	$(RM) main

