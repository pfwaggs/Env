
SHELL = /bin/bash

ifndef ENV_HOME
    ENV_HOME = $(HOME)
endif

ROOT = $(shell pwd -P)

DOTDIRS  := $(sort $(wildcard dotfiles*))
ENVDIRS  := $(sort $(wildcard envfiles*))

DIRS := $(DOTDIRS) $(ENVDIRS)

export DIRS DOTDIRS ENVDIRS

STATUS = PWD ROOT ENV_HOME DOTDIRS ENVDIRS
export STATUS $(STATUS)

.PHONY: clean check $(DIRS)

help:
	@echo 'status   : shows current variables'
	@echo 'list     : shows current files to be installed'
	@echo 'check    : will show what has changed wrt Git structure'
	@echo 'clean    : will uninstall the current environment'
	@echo 'preview  : show a list of files to be printed'
	@echo 'printout : print the files shown from preview'

status:
	@for v in $(STATUS); do eval "echo $$v = $${!v}"; done

install:
	@for dir in $(DOTDIRS); do \
	    echo installing $$dir; \
	    for fr in $$dir/*; do \
		to=$(ENV_HOME)/."$${fr#*/}"; \
		[[ -e $$to ]] || ln $$fr $$to;\
	    done; \
	done; \
	[[ -L $(ENV_HOME)/Env ]] || ln -T -s -f $(ROOT) $(ENV_HOME)/Env

uninstall:
	@for dir in $(DOTDIRS); do \
	    echo uninstalling $$dir; \
	    for fr in $$dir/*; do \
		to=$(ENV_HOME)/."$${fr#*/}"; \
		[[ -e $$to ]] && rm $$to; \
	    done; \
	done; \
	[[ -L $(ENV_HOME)/Env ]] && rm $(ENV_HOME)/Env || :

check:
	@[[ $$(readlink $(ENV_HOME)/Env) =~ $(ROOT) ]] && echo Env link is good || { echo Env link is broken; exit 1; }
	@for dir in $(DOTDIRS); do \
	    echo checking $$dir; \
	    for fr in $$dir/*; do \
		to=$(ENV_HOME)/."$${fr#*/}"; \
		[[ -e $$to ]] || { echo $$to does not exist; continue; }; \
		[[ $$to -ef $$fr ]] || { echo missing hardlink for $$fr to $$to; continue; }; \
	    done; \
	done

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
