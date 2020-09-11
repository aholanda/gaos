# ignoring IPC due low quantity of data
SUBSYSTEMS := block drivers fs init mm net sound
VERSIONS := 1.0 1.1.95 1.2.13 1.3.100 2.1.132 2.2.26 2.3.99-pre9 \
		2.4.37.11 2.5.75 2.6.39 3.19.8 4.14.14

# SEE flush_degrees.py to know which is the default subsystem
# of linux kernel to be processed.
kernel: flush_degrees.py
	-$(foreach v,$(VERSIONS),./$< kernel $(v);)
	-@echo "NOTE: Now run 'do_results.m' with kernel as argument inside Matlab."

# SEE flush_degrees.py to know which is the default version
# of linux kernel to be processed.
subsys: flush_degrees.py
	$(foreach s,$(SUBSYSTEMS),./$< $(s);)
	-@echo "NOTE: Now run 'do_results.m' with subsys as argument inside Matlab."

clean:
	$(RM) *.csv table*.tex

.PHONY: clean kernel subsys

# stay quiet
$(V).SILENT:
