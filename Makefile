
SHELL = /bin/bash

ifndef ENV_HOME
    ENV_HOME = $(HOME)
endif

ROOT = $(dir $(shell pwd -P))

ifndef DIRS
    DOTDIRS  := $(sort $(wildcard dotfiles*))
    ENVDIRS  := $(sort $(wildcard envfiles*))
    SYNCDIRS := $(sort $(wildcard syncdirs*))
else
    DOTDIRS  := $(filter dotfiles, $(DIRS))
    ENVDIRS  := $(filter envfiles, $(DIRS))
    SYNCDIRS := $(filter syncdirs, $(DIRS))
endif
DIRS := $(DOTDIRS) $(ENVDIRS) $(SYNCDIRS)

#DOTFILES := $(sort $(filter dotfiles%, $(FILES)))
export DIRS DOTDIRS ENVDIRS SYNCDIRS

NAME = $(notdir $(PWD))
BRANCH = $(shell git branch | sed -n '/*/p' | cut -c3-)
VER = $(shell git tag | sed -n '$$p')
TAR = $(NAME)_$(BRANCH)_$(VER).tgz
STATUS = PWD ROOT ENV_HOME DOTDIRS ENVDIRS SYNCDIRS NAME BRANCH VER TAR
export STATUS $(STATUS)

.PHONY: clean check $(DIRS)

help:
	@echo 'status   : shows current variables'
	@echo 'list     : shows current files to be installed'
	@echo 'tarinstall  : will install files in designated ENV_HOME'
	@echo 'tararchive : create an arcive of the installed files'
	@echo 'check    : will show what has changed wrt Git structure'
	@echo 'clean    : will uninstall the current environment'
	@echo 'tgz      : generate a complete tar file of Git structure'
	@echo 'preview  : show a list of files to be printed'
	@echo 'printout : print the files shown from preview'

status:
	@for v in $(STATUS); do eval "echo $$v = $${!v}"; done

install:
	@for dir in $(DOTDIRS) $(SYNCDIRS); do \
	    echo installing $$dir; \
	    for fr in $$dir/*; do \
		to=$(ENV_HOME)/."$${fr#*/}"; \
		[[ -e $$to ]] && continue || : ;\
		[[ -d $$fr ]] && rsync -a $$fr/ $$to || ln $$fr $$to; \
	    done; \
	done; \
	ln -T -s -f $(ROOT) $(ENV_HOME)/Env

uninstall:
	@for dir in $(DOTDIRS) $(SYNCDIRS); do \
	    echo uninstalling $$dir; \
	    for fr in $$dir/*; do \
		to=$(ENV_HOME)/."$${fr#*/}"; \
		[[ -e $$to ]] || continue; \
		[[ -d $$to ]] && rm -r $$to || rm $$to; \
	    done; \
	done; \
	[[ -L $(ENV_HOME)/Env ]] && rm $(ENV_HOME)/Env || :

check:
	@[[ $$(readlink $(ENV_HOME)/Env) =~ $(ROOT) ]] && echo Env link is good || { echo Env link is broken; exit 1; }
	@for dir in $(DOTDIRS) $(SYNCDIRS); do \
	    echo checking $$dir; \
	    for fr in $$dir/*; do \
		to=$(ENV_HOME)/."$${fr#*/}"; \
		[[ -e $$to ]] || { echo $$to does not exist; continue; }; \
		[[ $$to -ef $$fr ]] && continue || :; \
		[[ -d $$to ]] && diff -q -r $$to $$fr || diff $$to $$fr; \
	    done; \
	done

gitarchive:
	@git archive --format=tgz --prefix=$(NAME)/ --output=$(TAR) HEAD

updates:
	@-rm -r update.txt update.ps 2>/dev/null
	@source envfiles/xmn; \
	for file in Makefile $$(git ls-files $(DOTDIRS) $(ENVDIRS)); do \
	    [[ -f $$file ]] || continue; \
	    echo -e "\n#### $${file##*/}"; \
	    xmn ax $$file; \
	done | tee updates.txt | \
	enscript -2 -r -f Courier8 -DDuplex:true -DTumble:true -o updates.ps

outputs:
	@[[ -f filelist ]] || { echo missing filelist; exit -1; }
	@-rm -r output.txt output.ps 2>/dev/null
	@source envfiles/xmn; \
	source envfiles/bashrcfuncs; \
	for file in $$(cat filelist); do \
	    echo -e "\n#### $${file##*/}"; \
	    xmn -a $$file; \
	done | tee output.txt | \
	enscript -f Courier8 -DDuplex:true -DTumble:true -o output.ps
#	enscript -2 -r -f Courier8 -DDuplex:true -DTumble:true -o output.ps
