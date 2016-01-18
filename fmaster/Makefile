
full = $(wildcard *)
pre = bashrc_pre
post = bashrc_post
firsts = aliases basevars
ignore = $(pre) $(post) $(firsts) Makefile \#%
list = $(firsts) $(filter-out $(ignore), $(full))
ifdef DEST
    homedir = $(DEST)
else
    homedir = $(realpath ../..)
endif
bashrc = $(homedir)/.bashrc
prep_files = $(addprefix base., pm pl fnc sh)
dot_files = bash_profile exrc vimrc vimrc-abbr vimrc-maps

all: bashrc dot_files prep_files

bashrc: $(list)
	@echo building $(bashrc)
	@cp $(pre) $(bashrc)
	@base=$${PWD%/*}; echo "declare ENV_BASE=$$base" >> $(bashrc)
	@echo "declare ENV_DIRS=\$$ENV_BASE/fmaster" >> $(bashrc)
	@echo >> $(bashrc)
	@echo "unset -f \$$(compgen -A function)" >> $(bashrc)
	@echo "pushd $${PWD} >/dev/null" >> $(bashrc)
	@for n in $?; do echo "[[ \$$VERBOSE ]] && echo $$n || echo -n .; . $$n"; done >> $(bashrc)
	@echo "popd >/dev/null" >> $(bashrc)
	@echo "echo \$$ENV_STATE " >> $(bashrc)
	@cat $(post) >> $(bashrc)

prep_files:
	@echo copying $(prep_files)
	@for n in $(prep_files); do [[ ! -s $(homedir)/.$$n ]] && cp ../$$n $(homedir)/.$$n || echo skipping $$n; done

dot_files:
	@echo copying $(dot_files)
	@for n in $(dot_files); do [[ ! -s $(homedir)/.$$n ]] && cp ../$$n $(homedir)/.$$n || echo skipping $$n; done

