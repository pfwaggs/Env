SHELL = /bin/bash

ifndef ENV_HOME
    ENV_HOME = $(HOME)
endif

DEST = $(ENV_HOME)/Env

LIST = $(shell ls -r $(DEST) | grep -E '^[0-9_.-]+' | sed -n $(1)p)
LINKS = $(shell cd $(DEST)/$(1) 2>/dev/null && pwd -P || echo none)

ifdef TUMBLE
    TUMBLE = -DTumble:true
endif

CURRENT = $(notdir $(call LINKS,current))
LAST = $(notdir $(call LINKS,last))
DATE = $(shell . dotfiles/mkwdir $(DEST))
REV = $(shell git rev-parse --short HEAD)

ifeq ($(REV), $(findstring $(REV), $(LIST)))
    UPDATE := 0
else
    UPDATE := 1
endif

SNAPDIR = $(DATE)-$(REV)

STATUS = PWD ENV_HOME DEST CURRENT LAST DATE REV SNAPDIR
export $(STATUS) STATUS

all:

.PHONY: help status list shanpshot filelist long short

help:
	@echo 'status   : shows current variables'
	@echo 'list     : shows current snapshots'
	@echo 'snapshot : takes a snapshot into a derived dir'
	@echo 'check    : (broken) will show what has changed wrt Git structure'
	@echo 'long     : output in portrait, duplex'
	@echo 'short    : output in landscape, 2-up, duplex'

status:
	@for v in $(STATUS); do echo $$v = $${!v}; done

list:
	@ls -r $(DEST) | grep -E '^[0-9_.-]+' | cat -n

update :
	@[[ $(UPDATE) -eq 1 ]] || { echo we can not update. some dir matches HEAD; exit 1; }

snapshot: update
	@git archive --format=tar --prefix=$(SNAPDIR)/ HEAD | (tar -C $(DEST) -xf -)
	@ls -r $(DEST) | grep -E '^[0-9_.-]+' | cat -n

recent: C-1

save:
	@ln -n -f -s $(CURRENT) $(DEST)/last
C-%:
	@x=$(call LIST,$*); ln -n -f -s $$x $(DEST)/current; ls -ld $(DEST)/current
L-%:
	@x=$(call LIST,$*); ln -n -f -s $$x $(DEST)/last; ls -ld $(DEST)/last

check-%:
	@[[ -d /tmp/${REV} ]] || git archive --format=tar --prefix=$(REV)/ HEAD | (tar -C /tmp -xf -)
	-@z=$*; [[ -n $$z ]] && x=$(call LIST,$*) || x=$(REV); [[ $$x =~ $(REV) ]] || diff -q -r $(DEST)/$$x /tmp/$(REV)

# check:
# 	@cd $(DEST); [[ $$(pwd -P) =~ $(CURRENT) ]] && echo Env link is good || { echo Env link is broken; exit 1; }
# 	@for dir in $(DOTDIRS); do \
# 	    echo checking $$dir; \
# 	    for fr in $$dir/*; do \
# 		to=$(ENV_HOME)/."$${fr#*/}"; \
# 		[[ -e $$to ]] || { echo $$to does not exist; continue; }; \
# 		[[ $$to -ef $$fr ]] || { echo missing hardlink for $$fr to $$to; continue; }; \
# 	    done; \
# 	done

filelist:
	@echo Makefile > filelist
	@find dotfile* envfile* -type f >> filelist
	-@rm -r *.txt *.ps 2>/dev/null

short: filelist
	@source envfiles/xmn; source envfiles/bashrcfuncs; \
	xmn -pm -f filelist | tee short.txt | \
	enscript -2 -r -f Courier8 -DDuplex:true $(TUMBLE) -o short.ps

long: filelist
	@source envfiles/xmn; source envfiles/bashrcfuncs; \
	xmn -a -f filelist  | tee long.txt | \
	enscript -f Courier8 -DDuplex:true $(TUMBLE) -o long.ps
