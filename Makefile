check_data:
	for md5 in `ls data/*.md5`; do md5sum -c $${md5}; done

clean:
	$(RM) -rv *.pyc __pycache__\
				*.c *.h *.o

TIDY: clean
	$(RM) -v qdata/*.dat data/*.md5

.PHONY: check_data

# stay quiet
$(V).SILENT:
