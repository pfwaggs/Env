
SHELL = /bin/bash

ifndef ENV_HOME
    ENV_HOME = $(HOME)
endif
DEST = $(ENV_HOME)/Env

CURRENT = $(shell pwd -P)

SNAPDIR := $(shell . dotfiles/mkwdir $(DEST))

DOTDIRS  := $(sort $(wildcard dotfiles*))
ENVDIRS  := $(sort $(wildcard envfiles*))

DIRS := $(DOTDIRS) $(ENVDIRS)

export DIRS DOTDIRS ENVDIRS

STATUS = PWD CURRENT ENV_HOME DEST SNAPDIR DOTDIRS ENVDIRS
export STATUS $(STATUS)

.PHONY: clean check $(DIRS)

help:
	@echo 'status   : shows current variables'
	@echo 'list     : shows current files to be installed'
	@echo 'snapshot : takes a snapshot into a derived dir'
	@echo 'check    : will show what has changed wrt Git structure'
	@echo 'clean    : will uninstall the current environment'
	@echo 'output-long : output in portrait, duplex'
	@echo 'output-short : output in landscape, 2-up, duplex'

status:
	@for v in $(STATUS); do eval "echo $$v = $${!v}"; done

list:
	@ls -l $(DOTDIRS)

snapshot:
	@[[ -d $(SNAPDIR) ]] || mkdir $(SNAPDIR)
	@cp -r Makefile $(DOTDIRS) $(ENVDIRS) $(SNAPDIR)
	@echo $(SNAPDIR)

install:
	@for dir in $(DOTDIRS); do \
	    echo installing $$dir; \
	    for fr in $$dir/*; do \
		to=$(ENV_HOME)/."$${fr#*/}"; \
		[[ -e $$to ]] || ln $$fr $$to;\
	    done; \
	done; \
	ln -T -s -f $(CURRENT) $(DEST)

uninstall:
	@for dir in $(DOTDIRS); do \
	    echo uninstalling $$dir; \
	    for fr in $$dir/*; do \
		to=$(ENV_HOME)/."$${fr#*/}"; \
		[[ -e $$to ]] && rm $$to; \
	    done; \
	done; \
	[[ -L $(DEST) ]] && rm $(DEST) || :



check:
	@cd $(DEST); [[ $$(pwd -P) =~ $(CURRENT) ]] && echo Env link is good || { echo Env link is broken; exit 1; }
	@for dir in $(DOTDIRS); do \
	    echo checking $$dir; \
	    for fr in $$dir/*; do \
		to=$(ENV_HOME)/."$${fr#*/}"; \
		[[ -e $$to ]] || { echo $$to does not exist; continue; }; \
		[[ $$to -ef $$fr ]] || { echo missing hardlink for $$fr to $$to; continue; }; \
	    done; \
	done

filelist:
	@echo Makefile > filelist
	@find $(DOTDIRS) $(ENVDIRS) -type f >> filelist
	-@rm -r update.txt update.ps 2>/dev/null

output-short: filelist
	@source envfiles/xmn; source envfiles/bashrcfuncs; \
	xmn -pm -f filelist | tee update.txt | \
	enscript -2 -r -f Courier8 -DDuplex:true -DTumble:true -o update.ps

output-long: filelist
	@source envfiles/xmn; source envfiles/bashrcfuncs; \
	xmn -a -f filelist  | tee output.txt | \
	enscript -f Courier8 -DDuplex:true -DTumble:true -o output.ps
#	enscript -2 -r -f Courier8 -DDuplex:true -DTumble:true -o output.ps
