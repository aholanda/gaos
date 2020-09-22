check_data:
	for md5 in `ls data/*.md5`; do md5sum -c $${md5}; done

.PHONY: check_data

# stay quiet
$(V).SILENT:
