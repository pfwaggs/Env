
SHELL = /bin/bash

work_files = Makefile

MISC_DIR = misc
misc_files = $(notdir $(sort $(wildcard $(MISC_DIR)/*)))
work_files += $(addprefix $(MISC_DIR)/,$(misc_files))

DOTFILE_DIR = dot_files
dot_files = $(notdir $(sort $(wildcard $(DOTFILE_DIR)/*)))
work_files += $(addprefix $(DOTFILE_DIR)/,$(dot_files))

FUNCTION_DIR = functions
function_files = $(filter-out \#%, $(notdir $(sort $(wildcard $(FUNCTION_DIR)/*))))
work_files += $(addprefix $(FUNCTION_DIR)/,$(function_files))

ifndef DEST
    DEST = $(HOME)
endif

.PHONY: dots work check $(dot_files)

all: check

check:
	@echo checking dot files
	@for f in $(dot_files); do diff -q ~/.$$f $(DOTFILE_DIR)/$$f; done

dots:
	@echo copying $(dot_files)
	@for d in $(dot_files); do \
	    [[ ! -r $(DOTFILE_DIR)/$$d ]] || continue; \
	    cp $(DOTFILE_DIR)/$$d $(DEST)/.$$d; \
	done

$(dot_files):
	@echo copying $@
	@cp $(DOTFILE_DIR)/$@ $(DEST)/.$@

work:
	@echo making work copy
	@for f in $(work_files); do \
	    echo -e "\n#### $$f <<<<<<<<<<<<<"; \
	    cat $$f; \
	done | enscript -2 -r
