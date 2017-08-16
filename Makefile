
SHELL = /bin/bash

BASE = ~/Git/ENV

fs = $(BASE)/dotfiles/fs_*
fs := $(sort $(wildcard $(fs)))

dots = $(BASE)/dotfiles/*
dots := $(sort $(filter-out $(fs), $(wildcard $(dots))))

info := dots fs

.PHONEY = $(info)

all: $(info)

$(info) :
	@echo listing $@;
	@for x in $($@); do echo $$x; done

link:
	@for x in $(dots) $(fs); do ln $$x ~/.$${x##*/}; done

unlink:
	@for x in $(dots) $(fs) ; do rm ~/.$${x##*/}; done

archive:
	@git archive --format tar.gz -o /tmp/$(USER).tar.gz HEAD

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

