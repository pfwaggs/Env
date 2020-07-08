SHELL = /bin/bash
GITHOME = $(HOME)/Git/Env
GITPREFIX = --git-dir=$(GITHOME)/.git --work-tree=$(GITHOME)

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
TESTING = $(notdir $(call FOLLOW_LINK,testing))
DATE = $(shell date +%F | tr '-' '_')
SEQ = $(shell c=$$(ls -d $(DATE)* 2>/dev/null | wc -l); printf "%02d" $$((c+1)))
REV = $(shell git $(GITPREFIX) rev-parse --short HEAD)
UPDATE = $(if $(findstring $(REV),$(LIST)),no,yes)
ARCHIVE = $(filter-out $(CURRENT) $(SAVE) $(TESTING),$(LIST))
SNAPDIR = $(DATE).$(SEQ)-$(REV)

STATUS = PWD LAST CURRENT SAVE TESTING DATE SEQ REV SNAPDIR UPDATE
export $(STATUS) STATUS

.PHONY: archive

all:

help:
	@echo 'status      : shows current variables'
	@echo 'list        : shows current snapshots'
	@echo 'snapshot    : takes a snapshot into a derived dir'
	@echo 'check       : (broken) will show what has changed wrt Git structure'
	@echo 'long        : output in portrait, duplex'
	@echo 'short       : output in landscape, 2-up, duplex'
	@echo '(%-)current : makes the named (latest) version current'
	@echo '(%-)testing : makes the named (latest) version testing'
	@echo '(%-)save    : makes the named (current) version save'
status:
	@for v in $(STATUS); do echo $$v = $${!v}; done
	@echo archive:; for v in $(ARCHIVE); do echo $$v; done

archive:
	@[[ -d archive ]] || mkdir archive; mv -v $(ARCHIVE) archive
list:
	@echo $(LIST) | xargs -n 1 | nl

snapshot:
	@[[ $(UPDATE) = yes ]] || { echo no update needed.; exit 1; }
	@git $(GITPREFIX) archive --format=tar --prefix=$(SNAPDIR)/ HEAD | (tar -xvf -)
	@[[ -d $(SNAPDIR) ]] || { echo oops, no $(SNAPDIR); exit 1; }; \
	  diff -qr $(SNAPDIR) $(LAST) 2>/dev/null && { echo nothing to keep; rm -r $(SNAPDIR); } || : 

.SECONDEXPANSION:
current testing check : $(LAST)-$$@

save : $(CURRENT)-save

%-current %-save %-testing :
	@dir=$*; tmp=$@; link=$${tmp##*-}; ln -n -f -s $$dir $$link; ls -ld $$link

# %-check :
# 	@[[ -d /tmp/$(REV) ]] || git archive --format=tar --prefix=$(REV)/ HEAD | tar -C /tmp -xf -
# 	-@x=$(call LIST_PICK,$*); [[ $$x =~ $(REV) ]] && rm -r /tmp/$(REV) || diff -q -r $(DEST)/$$x /tmp/$(REV)

roll : save current
	-@rm testing &>/dev/null

filelist :
	@echo Makefile > filelist
	@find dotfile* envfile* priv* syncdirs* -type f | grep -v '~' >> filelist
	-@rm -r *.txt *.ps 2>/dev/null

long short : filelist
	source envfiles/xmn; source envfiles/bashrcfuncs; \
	xmn -pm -f filelist | tee $@.txt | \
	enscript $(ENSCRIPT) -DDuplex:true $(TUMBLE) -o $@.ps

# long: filelist
# 	@source envfiles/xmn; source envfiles/bashrcfuncs; \
# 	xmn -a -f filelist  | tee long.txt | \
# 	enscript -f Courier8 -DDuplex:true $(TUMBLE) -o long.ps
