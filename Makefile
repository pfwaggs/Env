
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

ifeq ($(DIFF), 1)
    DIFF = diff
    CHECK = check_noisy
else
    DIFF = diff -q
    CHECK = check_quiet
endif

.PHONY: dots work check $(dot_files)

all: list

list:
	@echo listing all work_files
	@for f in $(work_files); do  echo $$f;  done

check: $(CHECK)

check_noisy:
	@echo checking dot files
	@for f in $(dot_files); do \
	    [[ -f ~/.$$f ]] || continue; \
	    $$(diff -q ~/.$$f $(DOTFILE_DIR)/$$f) && continue; \
	    clear; echo checking $$f; \
	    $(DIFF) ~/.$$f $(DOTFILE_DIR)/$$f; \
	    echo checked $$f; \
	    read; \
	done

check_quiet:
	@echo checking dot files
	@for f in $(dot_files); do \
	    [[ -f ~/.$$f ]] || continue; \
	    $(DIFF) ~/.$$f $(DOTFILE_DIR)/$$f; \
	done

dots:
	@echo copying $(dot_files)
	@for d in $(dot_files); do \
	    cp $(DOTFILE_DIR)/$$d $(DEST)/.$$d; \
	done

$(dot_files):
	@echo copying $@
	@[[ -f $(DOTFILE_DIR)/$@ ]] && cp $(DOTFILE_DIR)/$@ $(DEST)/.$@;

work:
	@echo making work copy
	@for f in $(work_files); do \
	    echo -e "\n#### $$f <<<<<<<<<<<<<"; \
	    cat $$f; \
	    done | enscript -2 -r -DDuplex:true -DTumble:true -o printme.ps
