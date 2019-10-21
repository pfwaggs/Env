SHELL = /bin/bash

ifndef ENV_HOME
    ENV_HOME = $(HOME)
endif

DEST = $(ENV_HOME)/Env

LIST = $(shell cd $(DEST); ls -r | grep -E '^[0-9_.-]+' | sed -n $(1)p)
LINKS = $(shell cd $(DEST)/$(1) 2>/dev/null && pwd -P || echo none)

ifdef TUMBLE
    TUMBLE = -DTumble:true
endif

#CURRENT = $(shell cd $(DEST)/current && pwd -P || echo none)
CURRENT = $(call LINKS,current)
#LAST = $(shell cd $(DEST)/last && pwd -P || echo none)
LAST = $(call LINKS,last)
DATE = $(shell . dotfiles/mkwdir $(DEST))
REV = $(shell git rev-parse --short HEAD)
LIST = $(shell cd $(DEST); ls | grep -E '^[0-9_.-]+')
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
	@[[ $(UPDATE) -eq 1 ]] && echo we can update || echo we can not update

snapshot:
	@[[ $(UPDATE) -eq 1 ]] || { echo no update: head matches current link; exit 1; }
	@git archive --format=tar --prefix=$(SNAPDIR)/ HEAD | (tar -C $(DEST) -xf -)
	@echo $(DEST)/$(SNAPDIR)

C-%:
#	@cd $(DEST); x=$$(ls -r | grep -E '^[0-9_.-]+' | sed -n $*p); ln -n -f -s $$x current
	@cd $(DEST); x=$(call LIST,$*); ln -n -f -s $$x current
L-%:
#	@cd $(DEST); x=$$(ls -r | grep -E '^[0-9_.-]+' | sed -n $*p); ln -n -f -s $$x last
	@cd $(DEST); x=$(call LIST,$*); ln -n -f -s $$x last

check-%:
	@[[ $(UPDATE) -eq 1 ]] || { echo no update: head matches current link; exit 1; }
	@[[ -d /tmp/${REV} ]] || git archive --format=tar --prefix=$(REV)/ HEAD | (tar -C /tmp -xf -)
	@cd $(DEST); z=$*; [[ -n $$z ]] && x=$(call LIST,$*) || x=$(REV); diff -q -r $(CURRENT) /tmp/$$x

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
