
SHELL = /bin/bash

work_files = Makefile

MISC_DIR = misc
misc_files = $(notdir $(sort $(wildcard $(MISC_DIR)/*)))
work_files += $(addprefix $(MISC_DIR)/,$(misc_files))

DOTFILE_DIR = dot_files
dot_files = $(notdir $(sort $(wildcard $(DOTFILE_DIR)/*)))
dot_files := $(filter-out mac_%, $(dot_files))
work_files += $(addprefix $(DOTFILE_DIR)/,$(dot_files))

FUNCTION_DIR = functions
function_files = $(filter-out \#%, $(notdir $(sort $(wildcard $(FUNCTION_DIR)/*))))
work_files += $(addprefix $(FUNCTION_DIR)/,$(function_files))

ifndef DEST
    DEST = $(HOME)
endif

.PHONY: dots check dcheck work txt ps print $(dot_files)

all: list

list:
	@echo listing all work_files
	@for f in $(work_files); do  echo $$f;  done

archive:
	@for f in $(dot_files); do \
	    [[ -f ~/.$$f ]] && cp ~/.$$f ~/.$$f~ || : ; \
	done

revert:
	@for f in $(dot_files); do \
	    [[ -f ~/.$$f~ ]] && cp ~/.$$f~ /.$$f || : ; \
	done

dcheck:
	@echo checking dot files
	@for f in $(dot_files); do \
	    [[ -f ~/.$$f ]] || continue; \
	    $$(diff -q ~/.$$f $(DOTFILE_DIR)/$$f) && continue; \
	    clear; echo checking $$f; \
	    diff ~/.$$f $(DOTFILE_DIR)/$$f; \
	    echo checked $$f; \
	    read; \
	done

check:
	@echo checking dot files
	@for f in $(dot_files); do \
	    [[ -f ~/.$$f ]] || continue; \
	    diff -q ~/.$$f $(DOTFILE_DIR)/$$f; \
	done

dots:
	@echo copying $(dot_files)
	@for d in $(dot_files); do \
	    cp $(DOTFILE_DIR)/$$d $(DEST)/.$$d; \
	done

$(dot_files):
	@echo copying $@
	@[[ -f $(DOTFILE_DIR)/$@ ]] && cp $(DOTFILE_DIR)/$@ $(DEST)/.$@;

txt: work

work:
	@echo making work copy
	@for f in $(work_files); do \
	    echo -e "\n#### $$f <<<<<<<<<<<<<"; \
	    cat $$f; \
	done > printme.txt

ps: txt
	enscript -2 -r -DDuplex:true -DTumble:true -o printme.ps printme.txt

print: ps
	enscript -Z -P local printme.ps
	rm printme.ps printme.txt
