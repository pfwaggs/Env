
SHELL = /bin/bash

work_files = Makefile

MISC_DIR = misc
misc_files = $(notdir $(sort $(wildcard $(MISC_DIR)/*)))
work_files += $(addsuffix $(MISC_DIR)/,$(misc_files))

DOTFILE_DIR = dot_files
dot_files = $(notdir $(sort $(wildcard $(DOTFILE_DIR)/*)))
work_files += $(addsuffix $(DOTFILE_DIR)/,$(dot_files))

FUNCTION_DIR = functions
function_files = $(filter-out \#%, $(notdir $(sort $(wildcard $(FUNCTION_DIR)/*))))

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
	    cp $(DOTFILE_DIR)/$$d $(DEST)/.$$d; \
	done

$(dot_files):
	@echo copying $@
	@cp $(DOTFILE_DIR)/$@ $(DEST)/.$@

work:
	@echo making work copy
	@for f in $(work_files); do \
	    echo "#### $$f"; \
	    cat $$n; \
	done | enscript -2 -r -DDuplex:true -DTumble:false
