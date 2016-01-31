
SHELL = /bin/bash

MISC_DIR = misc

DOTFILE_DIR = dot_files
dot_files = $(notdir $(sort $(wildcard $(DOTFILE_DIR)/*)))

FUNCTION_DIR = functions
function_files = $(filter-out \#%, $(notdir $(sort $(wildcard $(FUNCTION_DIR)/*))))

ifndef DEST
    DEST = $(HOME)
endif
bashrc = $(DEST)/.bashrc

.PHONY: bashrc dots

all: bashrc dots

bashrc: 
	@echo building $@
	@[[ -f $(bashrc) ]] && mv $(bashrc) $(bashrc).old || echo no bashrc
	@cp $(MISC_DIR)/bashrc_pre $(bashrc)
	@echo "declare -x ENV=$${PWD}" >> $(bashrc)
	@echo >> $(bashrc)

	@echo "pushd $${PWD}/$(MISC_DIR) >/dev/null" >> $(bashrc)
	@echo "list=\"aliases basevars\"" >> $(bashrc)
	@echo "for n in \$$list; do [[ \$$VERBOSE ]] && echo \$$PWD/\$$n || echo -n .; . \$$n; done" >> $(bashrc)
	@echo "popd >/dev/null" >> $(bashrc)
	@echo >> $(bashrc)

	@echo "unset -f \$$(compgen -A function)" >> $(bashrc)
	@echo "pushd $${PWD}/$(FUNCTION_DIR) >/dev/null" >> $(bashrc)
	@echo "list=\$$(ls | grep -v '#')" >> $(bashrc)
	@echo "for n in \$$list; do [[ \$$VERBOSE ]] && echo \$$PWD/\$$n || echo -n .; . \$$n; done" >> $(bashrc)
	@echo "popd >/dev/null" >> $(bashrc)
	@echo >> $(bashrc)

	@echo "echo \$$STATE " >> $(bashrc)
	@cat $(MISC_DIR)/bashrc_post >> $(bashrc)

dots:
	@echo copying $(dot_files);
	@for d in $(dot_files); do [[ -s $(DEST)/.$$d ]] && echo skipping $$d || cp $(DOTFILE_DIR)/$$d $(DEST)/.$$d; done

