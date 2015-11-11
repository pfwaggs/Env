
full = $(wildcard *)
pre = bashrc_pre
post = bashrc_post
firsts = aliases basevars
ignore = $(pre) $(post) $(firsts) Makefile \#%
list = $(firsts) $(filter-out $(ignore), $(full))
dest = ~/.bashrc
all: $(list)
	@cat $(pre) | tee $(dest)
	@echo "pushd $${PWD} >/dev/null" | tee -a $(dest)
	@for n in $?; do echo "[[ \$$VERBOSE ]] && echo $$n || echo -n .; . $$n"; done | tee -a $(dest)
	@echo "popd >/dev/null" | tee -a $(dest)
	@echo "echo \$$ENV_STATE "| tee -a $(dest)
	@cat $(post) | tee -a $(dest)

