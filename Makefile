SHELL = /bin/bash
GITHOME = $(HOME)/Git/Env
GITPREFIX = -C $(GITHOME)
ifeq (.git,$(notdir $(findstring .git,$(shell ls -d .git 2>/dev/null))))
  ifeq (,$(filter status help filelist long short envcheck,$(MAKECMDGOALS)))
    $(error make operations should not be run in git repo)
  endif
endif

NEEDLOAD = $(shell [[ $$(compgen -A function) =~ load ]] || echo load)
ifeq (load,$(NEEDLOAD))
    $(error environment needs function load. run 'export -f load' then rerun make)
endif

BRANCH = $(shell git $(GITPREFIX) rev-parse --abbrev-ref HEAD)
ifeq (,$(findstring $(BRANCH),master))
  $(error branch is not master. please change branches)
endif

ifeq (short,$(findstring short,$(MAKECMDGOALS)))
  OPT_ENSCRIPT = -2 -r -f Courier8
endif
OPT_ENSCRIPT += -DDuplex:true

ifdef TUMBLE
  OPT_ENSCRIPT += -DTumble:true
endif

LIST := $(shell ls | sed -nr '/^[0-9][0-9_.]+-[[:alnum:]]+$$/p' | sort)
FOLLOW_LINK = $(shell cd $(1) &>/dev/null && pwd -P || echo none)

PRUNE = $(shell echo $${ENVDIR%/*/*})
DOTSRCDIR = $(ENVDIR)/dotinstall
MAKEFILE = $(ENVDIR)/Makefile
DOTINSTALL = $(notdir $(wildcard $(DOTSRCDIR)/*))
LAST = $(lastword $(LIST))
CURRENT = $(notdir $(call FOLLOW_LINK,current))
SAVE = $(notdir $(call FOLLOW_LINK,save))
TESTING = $(notdir $(call FOLLOW_LINK,testing))
DATE = $(shell date +%F | tr '-' '_')
SEQ = $(shell c=$$(ls -d $(DATE)* 2>/dev/null | wc -l); printf "%02d" $$((c+1)))
REV = $(shell git $(GITPREFIX) rev-parse --short HEAD)
ARCHIVE = $(filter-out $(CURRENT) $(SAVE) $(TESTING),$(LIST))
UPDATETO = $(if $(findstring $(REV),$(LIST)),,$(DATE).$(SEQ)-$(REV))
STATUS = DOTSRCDIR PWD GITHOME BRANCH LAST CURRENT SAVE TESTING DATE SEQ REV UPDATETO 
export $(STATUS)

.PHONY: archive

help :
	@grep '^#help: ' $(MAKEFILE) | cut -f2- -d: | column -s: -t

#help: envcheck : checks environment for needed functions
#help: : you may need to load these functions then export them
#help: : use 'make status' to find what ENVCHECK functions are needed
envcheck :
	@for x in $(ENVCHECK); do \
	    [[ $$(compgen -A function) =~ $$x ]] || { echo ENVCHECK failure; exit 1; }; done

#help: info : combines status and list
info : status list

#help: status : shows current variables
status :
	@for v in $(STATUS); do echo $$v = $${!v}; done | column -s= -t

#help: list : list the snapshots
list :
	@echo archive:; for v in $(ARCHIVE); do echo $$v; done

#help: %-x{info,recover,tar,targz} : the 'x' commands let you specify a line
#help: : number in archive.txt to use for the git
#help: : reference and runs a new make instance
#help: : with the altered command.
%-xinfo %-xrecover %-xtar %-xtargz : 
	@ref=$$(perl -n -E '$*==$$. && say /-(\w+)$$/' archive.txt); cmd=$@; cmd="$${cmd#*x}"; make $$ref-$$cmd

#help: %-recover : recover an entry. use the log tag at end of the dir name
%-recover :
	@x=$$(grep $* archive.txt); [[ -n $$x ]] || { echo $* not found in archive.txt; exit 1; }; \
	    read date seq rev < <(echo $${x//[.-]/ }); \
	    git $(GITPREFIX) archive --format=tar --prefix=$$x/ $$rev | tar -x

#help: %-tar : create a tar of the repo
%-tar %-targz:
	@[[ $@ =~ targz ]] && format=targz || format=tar; \
	    git $(GITPREFIX) archive --format=$$format --prefix=$*/ $* > $*.$$format

%-info :
	@x=$$(grep $* archive.txt); [[ -n $$x ]] || { echo $* not found in archive.txt; exit 1; }; \
	    read date seq rev < <(echo $${x//[.-]/ }); git $(GITPREFIX) log $$rev -1; 

#help: archive : appends archive names to archive.txt then deletes the archive
archive :
	@[[ -n "$(ARCHIVE)" ]] || { echo nothing to archive; exit 1; }
	@printf "%s\n" $(ARCHIVE) >> archive.txt; rm -r $(ARCHIVE)

#help: snapshot : takes a snapshot into a derived dir
update :
	@[[ -n $(UPDATETO) ]] || { echo no update needed.; exit 1; }
	@git $(GITPREFIX) archive --format=tar --prefix=$(UPDATETO)/ HEAD | tar -x

#help: (%-)current : makes the named (latest) version current
#help: (%-)testing : makes the named (lastest) version testing
#help: (%-)save    : makes the named (current) version save
save : $(CURRENT)-save
testing : $(LAST)-testing
current : $(LAST)-current

%-current %-save %-testing :
	@dir=$*; tmp=$@; link="$${tmp##*-}"; ln -n -f -s $$dir $$link; ls -ld $$link

#help: devtest : links the Git repo to testing
devtest :
	ln -n -f -s $(GITHOME) testing

#help: roll : relinks current to save and links last to current
roll : save current
	-@rm testing &>/dev/null

#help: dotcheck : checks content of DOTINSTALL with the users dotfiles for diffs
dotcheck :
	@for x in $(DOTINSTALL); do \
	    diff -qr $(DOTSRCDIR)/$$x ~/.$$x || echo $$x is not current; \
	done

#help: filelist : generates the list of files to print
#	@sed -n 's/\\$/\\\\/;p' Makefile > Makefile.txt; echo Makefile.txt > filelist
filelist :
	@[[ ! -d $(ENVDIR)/prime ]] || { echo $(ENVDIR)/prime exits; exit 1; }
	@[[ ! -d $(ENVDIR)/extra ]] || { echo $(ENVDIR)/extra exits; exit 1; }
	@cd $(ENVDIR) &>/dev/null; load fsplit; fsplit prime.rc extra.rc 2>/dev/null
	@echo $(MAKEFILE) > $@
	@find $(ENVDIR)/{,dotinstall,support} -maxdepth 2 -type f | \
	    grep -v '\.rc' | sort >> $@
	-@echo removing old print files; rm -r long* short* md5sums* 2>/dev/null

#help: long : output in portrait, duplex
#help: short : output in landscape, 2-up, duplex
long short : filelist
	@echo $(ENVDIR) > $@.txt
#	@load cksumit; PRUNE=$(ENVDIR) cksumit $$(cat $^) >> $@.txt
	@cat $^ | while read; do echo $$REPLY; cat "$$REPLY"; done >> $@.txt
	@enscript $(OPT_ENSCRIPT) -o $@.ps $@.txt
	@[[ -s md5sums.txt ]] && enscript $(OPT_ENSCRIPT) -o md5sums.ps md5sums.txt || :
	-@rm -r -v $(ENVDIR)/{prime,extra} 2>/dev/null

#help: md5sums : generates md5sums for files in the filelist
md5sums : filelist
	@echo $(ENVDIR) >$@.txt
	@while read; do md5sum $$REPLY; done < $^ | sed "s|$(ENVDIR)/||" >> $@.txt

