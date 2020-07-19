SHELL = /bin/bash
GITHOME = $(HOME)/Git/Env
GITPREFIX = --git-dir=$(GITHOME)/.git --work-tree=$(GITHOME)
#BRANCH = branch is $(shell git $(GITPREFIX) branch -l | perl -n -E '/\*/ && say /\s(\w+)\s/')
BRANCH = master
ifneq ($(BRANCH), master)
    $(if $(findstring help, $(MAKECMDGOALS)), $(warning warn $(BRANCH)), $(error error $(BRANCH)))
endif

ifeq (short,$(findstring short,$(MAKECMDGOALS)))
  ENSCRIPT = -2 -r -f Courier8
endif

LIST = $(shell ls | grep -E '^[0-9_.-]+' | sort -r)
FOLLOW_LINK = $(shell cd $(1) 2>/dev/null && pwd -P || echo none)

ifdef TUMBLE
    TUMBLE = -DTumble:true
endif

LAST = $(firstword $(LIST))
CURRENT = $(notdir $(call FOLLOW_LINK,current))
SAVE = $(notdir $(call FOLLOW_LINK,save))
DATE = $(shell date +%F | tr '-' '_')
SEQ = $(shell c=$$(ls -d $(DATE)* 2>/dev/null | wc -l); printf "%02d" $$((c+1)))
REV = $(shell git $(GITPREFIX) rev-parse --short HEAD)
UPDATE = $(if $(findstring $(REV),$(LIST)),no,yes)
ARCHIVE = $(filter-out $(CURRENT) $(SAVE),$(LIST))
SNAPDIR = $(DATE).$(SEQ)-$(REV)

STATUS = PWD BRANCH LAST CURRENT SAVE DATE SEQ REV SNAPDIR UPDATE
export $(STATUS) STATUS

.PHONY: archive

all:

help:
	@sed -nr '/^#doc:/p' Makefile | cut -f2- -d: | column -s: -t

#doc: status : shows current variables
status:
	@for v in $(STATUS); do echo $$v = $${!v}; done
	@echo archive:; for v in $(ARCHIVE); do echo $$v; done

oops-% :
	@want=$$(grep $* archive_list | cut -f2 -d-); git $(GITPREFIX) checkout -b $$want $$want

archive:
	@[[ -d archive ]] || mkdir archive; mv -v $(ARCHIVE) archive

#doc: list : shows current snapshots
list:
	@echo $(LIST) | xargs -n 1 | nl

#doc: snapshot : takes a snapshot into a derived dir
snapshot:
	@[[ $(UPDATE) = yes ]] || { echo no update needed.; exit 1; }
	@git $(GITPREFIX) archive --format=tar --prefix=$(SNAPDIR)/ HEAD | (tar -xvf -)
	@[[ -d $(SNAPDIR) ]] || { echo oops, no $(SNAPDIR); exit 1; }; \
	  diff -qr $(SNAPDIR) $(LAST) 2>/dev/null && { echo nothing to keep; rm -r $(SNAPDIR); } || : 

.SECONDEXPANSION:
current check : $(LAST)-$$@

save : $(CURRENT)-save

#doc: (%-)current : makes the named (latest) version current
#doc: (%-)save    : makes the named (current) version save
%-current %-save :
	@dir=$*; tmp=$@; link=$${tmp##*-}; ln -n -f -s $$dir $$link; ls -ld $$link

testing :
	-@ln -s $(GITHOME) testing

roll : save current

filelist :
	@echo Makefile > filelist
	@find dotfile* envfile* priv* syncdirs* -type f | grep -v '~' >> filelist
	-@rm -r *.txt *.ps 2>/dev/null

#doc: long : output in portrait, duplex
#doc: short : output in landscape, 2-up, duplex
long short : filelist
	source envfiles/xmn; source envfiles/bashrcfuncs; \
	xmn -pm -f filelist | tee $@.txt | \
	enscript $(ENSCRIPT) -DDuplex:true $(TUMBLE) -o $@.ps

