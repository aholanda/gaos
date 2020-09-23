check_data:
	for md5 in `ls data/*.md5`; do md5sum -c $${md5}; done

clean:
	$(RM) *.pyc \
			*.c *.h *.o

.PHONY: check_data

# stay quiet
$(V).SILENT:
