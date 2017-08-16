
SHELL = /bin/bash

BASE = ~/Git/ENV

fs = dotfiles/fs_*
fs := $(sort $(wildcard $(fs)))

dots = dotfiles/*
dots := $(sort $(filter-out $(fs), $(wildcard $(dots))))

info := dots fs

.PHONEY = $(info) functions $(fs)

all: $(info)

$(info) :
	@echo listing $@;
	@for x in $($@); do echo $$x; done

link:
	@for x in $(dots) $(fs); do ln $(BASE)/$$x ~/.$${x##*/}; done

unlink:
	@for x in $(dots) $(fs) ; do rm ~/.$${x##*/}; done

archive:
	@git archive --format tar.gz -o /tmp/$(USER).tar.gz HEAD

functions: $(fs)
	@if [[ -d functions ]]; then \
	    echo making $^; \
	    cd functions; \
	    cat xx00 $$(ls -Ixx00) > ../fs_stuff; \
	    cd $(BASE); \
	    rm -r functions; \
	else \
	    mkdir functions; \
	    echo creating functions/xx files; \
	    csplit --prefix=functions/xx $(fs) '/#>>> /' {*}; \
	    cd functions; \
	    for x in xx*; do \
		read j n <<< $$(head -n 1 $$x); \
		[[ $$n ]] || continue; \
		mv $$x $$n; \
	    done; \
	fi
txt:
	@echo making work copy
	@for f in Makefile $(dots) $(fs); do \
	    echo -e "\n#### $$f <<<<<<<<<<<<<"; \
	    cat $$f; \
	done > txt

ps: txt
	@enscript -2 -r -DDuplex:true -DTumble:true -o ps txt
	@rm txt

print: ps
	@enscript -Z -P local ps
	@rm ps

