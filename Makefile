SHELL = /bin/bash

ifndef ENV_HOME
  ENV_HOME = $(HOME)
endif
ifeq (current,$(findstring current,$(MAKECMDGOALS)))
  LINK=$(DEST)/current
endif
ifeq (save,$(findstring save,$(MAKECMDGOALS)))
  LINK=$(DEST)/save
endif
ifeq (testing,$(findstring testing,$(MAKECMDGOALS)))
  LINK=$(DEST)/testing
endif
ifeq (short,$(findstring short,$(MAKECMDGOALS)))
  ENSCRIPT = -2 -r -f Courier8
endif

DEST = $(ENV_HOME)/Env
LIST = $(shell ls -r $(DEST) | grep -E '^[0-9_.-]+')
LIST_PICK = $(shell echo $(LIST) | xargs -n 1 | sed -n $(1)p || echo none)
LIST_LINE = $(shell echo $(LIST) | xargs -n 1 | awk '/$(1)/ {print NR}')
FOLLOW_LINK = $(shell cd $(DEST)/$(1) 2>/dev/null && pwd -P || echo none)

ifdef TUMBLE
    TUMBLE = -DTumble:true
endif

FIRST = $(call LIST_PICK,1)
CURRENT = $(notdir $(call FOLLOW_LINK,current))
CURRENT_LINE = $(call LIST_LINE,$(CURRENT))
SAVE = $(notdir $(call FOLLOW_LINK,save))
SAVE_LINE = $(call LIST_LINE,$(SAVE))
DATE = $(shell . dotfiles/mkwdir $(DEST))
REV = $(shell git rev-parse --short HEAD)
TESTING = $(notdir $(call FOLLOW_LINK,testing))
TESTING_LINE = $(call LIST_LINE,$(TESTING))
UPDATE = $(if $(findstring $(REV),$(LIST)),no,yes)
ARCHIVE = $(filter-out $(CURRENT) $(SAVE) $(TESTING),$(LIST))
SNAPDIR = $(DATE)-$(REV)

STATUS = PWD ENV_HOME DEST FIRST CURRENT CURRENT_LINE SAVE SAVE_LINE TESTING TESTING_LINE LINK DATE REV SNAPDIR UPDATE
export $(STATUS) STATUS

all:

help:
	@echo 'status   : shows current variables'
	@echo 'list     : shows current snapshots'
	@echo 'snapshot : takes a snapshot into a derived dir'
	@echo 'check    : (broken) will show what has changed wrt Git structure'
	@echo 'long     : output in portrait, duplex'
	@echo 'short    : output in landscape, 2-up, duplex'

status:
	@for v in $(STATUS); do echo $$v = $${!v}; done
	@echo archive:; for v in $(ARCHIVE); do echo $$v; done

archive:
	@cd $(DEST); [[ -d archive ]] || mkdir archive; mv -v $(ARCHIVE) archive
list:
	@echo $(LIST) | xargs -n 1 | nl

snapshot:
	@[[ $(UPDATE) = yes ]] || { echo no update needed.; exit 1; }
	@git archive --format=tar --prefix=$(SNAPDIR)/ HEAD | (tar -C $(DEST) -xf -)
	@f=$(DEST)/$(FIRST); n=$(DEST)/$(SNAPDIR); \
	  [[ -d $$n ]] || { echo oops, no $$n; exit 1; }; \
	  diff -qr $$n $$f &>/dev/null && { echo nothing to keep; rm -r $$n; } || :

.SECONDEXPANSION:
current testing check: 1$$@

save: $(CURRENT_LINE)save

%current %save %testing:
	@x=$(call LIST_PICK,$*); ln -n -f -s $$x $(LINK); ls -ld $(LINK)

%check:
	@[[ -d /tmp/$(REV) ]] || git archive --format=tar --prefix=$(REV)/ HEAD | tar -C /tmp -xf -
	-@x=$(call LIST_PICK,$*); [[ $$x =~ $(REV) ]] && rm -r /tmp/$(REV) || diff -q -r $(DEST)/$$x /tmp/$(REV)

filelist:
	@echo Makefile > filelist
	@find dotfile* envfile* -type f | grep -v '~' >> filelist
	-@rm -r *.txt *.ps 2>/dev/null

short long: filelist
	@source envfiles/xmn; source envfiles/bashrcfuncs; \
	xmn -pm -f filelist | tee $*.txt | \
	enscript -2 -r -f Courier8 -DDuplex:true $(TUMBLE) -o $*.ps

# long: filelist
# 	@source envfiles/xmn; source envfiles/bashrcfuncs; \
# 	xmn -a -f filelist  | tee long.txt | \
# 	enscript -f Courier8 -DDuplex:true $(TUMBLE) -o long.ps
