CHANGEFILE := versions.ch
linux.c: main.w
	$(CTANGLE) $< $(CHANGEFILE) $@

linux: linux.c
