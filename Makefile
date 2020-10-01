CFLAGS := -Wall -g
TEX := xetex

.SUFFIXES:
.SUFFIXES: .c .dvi .o .pdf .tex .w

vpath %.w linux test

#####
# C #
#####
%.c : %.w
	$(CTANGLE) $<

%.o : %.c
	$(CC) -c $(CFLAGS) $< -o $@

%.h : %.c

#######
# TeX #
#######
%.tex : %.w
	$(CWEAVE) $<

%.pdf: %.tex
	$(TEX) $<

########
# Data #
########
check_data:
	for md5 in `ls data/*.md5`; do md5sum -c $${md5}; done

############
# Programs #
############
# Linux components
linux_components.c: graph.c

linux_components: graph.o linux_components.o
	$(CC) $(CFLAGS) $^ -o $@
TRASH += linux_components

# test
graph_test.c: graph.c

graph_test: graph.o graph_test.o
	$(CC) $(CFLAGS) $^ -o $@
TRASH += graph_test

#########
# Admin #
#########
clean:
	$(RM) -rv *.pyc __pycache__\
				*.c *.h *.o \
				*.idx *.scn *.tex *.ttp \
				$(TRASH)

TIDY: clean
	$(RM) -v data/linux-*.dat data/linux-*.md5

.PHONY: check_data

# stay quiet
#$(V).SILENT:
