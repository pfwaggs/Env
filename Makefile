
SHELL = /bin/bash

BASE = ~/Git/ENV

DOTFILE_DIR = $(BASE)/dot_files
DOTFILES = $(notdir $(wildcard $(DOTFILE_DIR)/*))

work_dirs = dot_files functions misc prep_files
work_files = $(shell find $(work_dirs) -name \.git -prune -o -type f | sort)

all: info

info:
	@for x in $(DOTFILES); do echo $$x; done
	@echo $(USER)

link:
	@for x in $(DOTFILES); do ln $(DOTFILE_DIR)/$$x ~/.$$x; done

unlink:
	@for x in $(DOTFILES); do [[ -f ~/.$$x ]] && rm ~/.$$x || continue; done

update:
	@git add .
	@git commit

archive:
	@git archive --format tar.gz -o /tmp/$(USER).tar.gz HEAD

printme.txt:
	@echo making work copy
	@for f in $(work_files); do \
	    grep -q '#TAG:use' "$$f" || continue; \
	    echo -e "\n#### $$f <<<<<<<<<<<<<"; \
	    cat $$f; \
	done > printme.txt

printme.ps: printme.txt
	@enscript -2 -r -DDuplex:tru -DTumble:true -o printme.ps printme.txt
	@rm printme.txt

print: printme.ps
	@enscript -Z -P local printme.ps
	@rm printme.ps

