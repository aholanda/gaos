CFLAGS := -Wall -g

.SUFFIXES:
.SUFFIXES: .c .o

vpath %.w src:lib

# C
%.c : %.w
	$(CTANGLE) $<

%.o : %.c
	$(CC) -c $(CFLAGS) $< -o $@

%.h : %.c

# TeX
%.tex : %.w
	$(CWEAVE) $<

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
