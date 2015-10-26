
full = $(wildcard *)
firsts = basevars aliases
ignore = $(firsts) Makefile env \#%
list = $(firsts) $(filter-out $(ignore), $(full))
dest = ../env
all: $(list)
	@echo "pushd $${PWD} >/dev/null" | tee $(dest)
	@for n in $?; do echo "[[ \$$VERBOSE ]] && echo $$n || echo -n .; . $$n"; done | tee -a $(dest)
	@echo "echo done "| tee -a $(dest)
	@echo mkpc | tee -a $(dest)
	@echo "popd >/dev/null" | tee -a $(dest)


