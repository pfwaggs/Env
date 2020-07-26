SHELL = /bin/bash
GITHOME = $(HOME)/Git/Env
GITPREFIX = -C $(GITHOME)

BRANCH = $(shell git $(GITPREFIX) branch | awk '/\*/ {print $$NF}')
ifeq (1,$(findstring $(BRANCH),master dev))
    $(error branch is not master or dev)
endif

ifeq (short,$(findstring short,$(MAKECMDGOALS)))
  ENSCRIPT = -2 -r -f Courier8
endif

LIST = $(shell ls | grep -E '^[0-9_.-]+' | sort)
FOLLOW_LINK = $(shell cd $(1) &>/dev/null && pwd -P || echo none)

ifndef TUMBLE
    TUMBLE = -DTumble:true
endif

LAST = $(lastword $(LIST))
CURRENT = $(notdir $(call FOLLOW_LINK,current))
SAVE = $(notdir $(call FOLLOW_LINK,save))
TESTING = $(notdir $(call FOLLOW_LINK,testing))
DATE = $(shell date +%F | tr '-' '_')
SEQ = $(shell c=$$(ls -d $(DATE)* 2>/dev/null | wc -l); printf "%02d" $$((c+1)))
REV = $(shell git $(GITPREFIX) rev-parse --short HEAD)
UPDATE = $(if $(findstring $(REV),$(LIST)),no,yes)
ARCHIVE = $(filter-out $(CURRENT) $(SAVE) $(TESTING),$(LIST))
SNAPDIR = $(DATE).$(SEQ)-$(REV)

STATUS = PWD GITHOME BRANCH LAST CURRENT SAVE TESTING DATE SEQ REV SNAPDIR UPDATE
export $(STATUS)

.PHONY: archive

all :

help :
	@grep '^#help: ' Makefile | cut -f2- -d: | column -s: -t

help-% :
	@grep '^#help: $*' Makefile | cut -f2- -d: | column -s: -t

info-% :
	@x=$$(grep $* archive.txt); [[ -n $$x ]] || { echo $* not found in archive.txt; exit 1; }; \
	    read date seq rev < <(echo $${x//[.-]/ }); git $(GITPREFIX) log $$rev -1; 
	
info : status list

#help: status : shows current variables
status :
	@for v in $(STATUS); do echo $$v = $${!v}; done | column -s= -t

#help: list : list the snapshots
list :
	@echo archive:; for v in $(ARCHIVE); do echo $$v; done

#help: archive : appends archive names to archive.txt then deletes the archive
archive :
	@[[ -n "$(ARCHIVE)" ]] || { echo nothing to archive; exit 1; }
	@printf "%s\n" $(ARCHIVE) >> archive.txt; rm -r $(ARCHIVE)

#help: recover-% : recover an entry. use the log tag at end of the dir name
recover-% :
	@x=$$(grep $* archive.txt); [[ -n $$x ]] || { echo $* not found in archive.txt; exit 1; }; \
	    read date seq rev < <(echo $${x//[.-]/ }); \
	    git $(GITPREFIX) archive --format=tar --prefix=$$x/ $$rev | (tar -xf -)

#help: snapshot : takes a snapshot into a derived dir
snapshot :
	@[[ $(UPDATE) = yes ]] || { echo no update needed.; exit 1; }
	@git $(GITPREFIX) archive --format=tar --prefix=$(SNAPDIR)/ HEAD | (tar -xf -)

.SECONDEXPANSION :
current testing check : $(LAST)-$$@

save : $(CURRENT)-save

#help: (%-)current : makes the named (latest) version current
#help: (%-)testing : makes the named (latest) version testing
#help: (%-)save    : makes the named (current) version save
%-current %-save %-testing :
	@dir=$*; tmp=$@; link=$${tmp##*-}; ln -n -f -s $$dir $$link; ls -ld $$link

#help: check : (broken) will show what has changed wrt Git structure
# %-check :
# 	@[[ -d /tmp/$(REV) ]] || git archive --format=tar --prefix=$(REV)/ HEAD | tar -C /tmp -xf -
# 	-@x=$(call LIST_PICK,$*); [[ $$x =~ $(REV) ]] && rm -r /tmp/$(REV) || diff -q -r $(DEST)/$$x /tmp/$(REV)

roll : save current
	-@rm testing &>/dev/null

filelist :
	@echo Makefile > filelist
	@find dotfile* envfile* -type f | grep -v '~' >> filelist
	-@rm -r *.txt *.ps 2>/dev/null

#help: long : output in portrait, duplex
#help: short : output in landscape, 2-up, duplex
long short : filelist
	@source envfiles/xmn; source envfiles/bashrcfuncs; \
	xmn -pm -f filelist | tee $@.txt | \
	enscript $(ENSCRIPT) -DDuplex:true $(TUMBLE) -o $@.ps

# long: filelist
# 	@source envfiles/xmn; source envfiles/bashrcfuncs; \
# 	xmn -a -f filelist  | tee long.txt | \
# 	enscript -f Courier8 -DDuplex:true $(TUMBLE) -o long.ps
