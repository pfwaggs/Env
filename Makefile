SHELL = /bin/bash
GITHOME = $(HOME)/Git/Env
GITPREFIX = -C $(GITHOME)
ifeq (.git,$(notdir $(findstring .git,$(shell ls -d .git 2>/dev/null))))
  ifeq (,$(filter status help filelist long short envcheck,$(MAKECMDGOALS)))
    $(error make operations should not be run in git repo)
  endif
endif

ENVCHECK = fsplit cksumit
ENVNEEDS = $(shell have=$$(compgen -A function); for x in $(ENVCHECK); do [[ $$have =~ $$x ]] || echo $$x; done)
ifneq (,$(ENVNEEDS))
    $(error environment needs: $(ENVNEEDS))
endif

#ifeq (,$(filter $(ENVTAG),$(wildcard *)))
#else
#  DOTSRCDIR = $(ENVTAG)/dotinstall
#  MAKEFILE = $(ENVTAG)/Makefile
#endif

BRANCH = $(shell git $(GITPREFIX) rev-parse --abbrev-ref HEAD)
ifeq (,$(findstring $(BRANCH),master))
  $(error branch is not master. please change branches)
endif

ifeq (short,$(findstring short,$(MAKECMDGOALS)))
  ENSCRIPT = -2 -r -f Courier8
endif

LIST := $(shell ls | sed -nr '/^[0-9][0-9_.]+-[[:alnum:]]+$$/p' | sort)
FOLLOW_LINK = $(shell cd $(1) &>/dev/null && pwd -P || echo none)

ifndef TUMBLE
  TUMBLE = -DTumble:true
endif

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
NEEDUPDATE = $(if $(findstring $(REV),$(LIST)),,$(DATE).$(SEQ)-$(REV))
STATUS = DOTSRCDIR PWD GITHOME BRANCH LAST CURRENT SAVE TESTING DATE SEQ REV NEEDUPDATE 
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
	    git $(GITPREFIX) archive --format=tar --prefix=$$x/ $$rev | (tar -xf -)

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
	@[[ -n $(NEEDUPDATE) ]] || { echo no update needed.; exit 1; }
	@git $(GITPREFIX) archive --format=tar --prefix=$(NEEDUPDATE)/ HEAD | (tar -xf -)

#help: (%-)current : makes the named (latest) version current
#help: (%-)testing : makes the named (lastest) version testing
#help: (%-)save    : makes the named (current) version save
save : $(CURRENT)-save
testing : $(LAST)-testing
current : $(LAST)-current

%-current %-save %-testing :
	@dir=$*; tmp=$@; link="$${tmp##*-}"; ln -n -f -s $$dir $$link; ls -ld $$link

#help: roll : relinks current to save and links last to current
roll : save current
	-@rm testing &>/dev/null

#help: install-% : used to install individual user dotfile like .bashrc
.SECONDEXPANSION:
install-% : $(DOTSRCDIR)/$$*
	@echo checking $^; diff -qr $^ ~/.$* || cp -r $^ ~/.$*

#help: install : used to install all the dotfiles for the user
install : $(addprefix install-, $(DOTINSTALL));

#help: check : checks content of DOTINSTALL with the users dotfiles for status
check :
	@for x in $(DOTINSTALL); do \
	    diff -qr $(DOTSRCDIR)/$$x ~/.$$x || echo $$x is not current; \
	done

#help: filelist : generates the list of files to print
#	@sed -n 's/\\$/\\\\/;p' Makefile > Makefile.txt; echo Makefile.txt > filelist
filelist :
	@[[ ! -d $(MAINDIR)/prime ]] || { echo $(MAINDIR)/prime exits; exit 1; }
	@[[ ! -d $(MAINDIR)/extra ]] || { echo $(MAINDIR)/extra exits; exit 1; }
	@cd $(MAINDIR) &>/dev/null; fsplit prime_functions 2>/dev/null
	@cd $(MAINDIR) &>/dev/null; fsplit extra_functions 2>/dev/null
	@echo Makefile > $@
	@find $(ENVDIR)/{main,dotinstall,support} -maxdepth 2 -type f | \
	    grep -v '_functions' | sort >> $@
	-@echo removing old print files; rm -r long* short* 2>/dev/null

#help: long : output in portrait, duplex
#help: short : output in landscape, 2-up, duplex
long short : filelist
	@cksumit $$(cat $^) | tee $@.txt | \
	enscript $(ENSCRIPT) -DDuplex:true $(TUMBLE) -o $@.ps

md5sums : filelist
	@while read; do md5sum $$REPLY; done < $^ > $@

