CFLAGS := -Wall -g
TEX := xetex

.SUFFIXES:
.SUFFIXES: .c .dvi .o .pdf .tex .w

vpath %.w mod

# C
%.c : %.w
	$(CTANGLE) $<

%.o : %.c
	$(CC) -c $(CFLAGS) $< -o $@

%.h : %.c

input.c: graph.c

# TeX
%.tex : %.w
	$(CWEAVE) $<

%.pdf: %.tex
	$(TEX) $<

# Data
check_data:
	for md5 in `ls data/*.md5`; do md5sum -c $${md5}; done

# Admin
clean:
	$(RM) -rv *.pyc __pycache__\
				*.c *.h *.o \
				*.idx *.scn *.tex *.ttp

TIDY: clean
	$(RM) -v qdata/*.dat data/*.md5

.PHONY: check_data

# stay quiet
$(V).SILENT:
