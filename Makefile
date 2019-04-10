
# initializing system AzA
SHELL = /bin/bash

ifndef DEST
    DEST = $(HOME)
endif

ifndef DIRS
    DOTDIRS  := $(sort $(wildcard dotfiles*))
    ENVDIRS  := $(sort $(wildcard envfiles*))
    SYNCDIRS := $(sort $(wildcard syncdirs*))
else
    DOTDIRS  := $(filter dotfiles, $(DIRS))
    ENVDIRS  := $(filter envfiles, $(DIRS))
    SYNCDIRS := $(filter syncdirs, $(DIRS))
endif
DIRS := $(DOTDIRS) $(ENVDIRS) $(SYNCDIRS)

#DOTFILES := $(sort $(filter dotfiles%, $(FILES)))
export DIRS DOTDIRS ENVDIRS SYNCDIRS

NAME = $(notdir $(PWD))
BRANCH = $(shell git branch | sed -n '/*/p' | cut -c3-)
VER = $(shell git tag | sed -n '$$p')
TAR = $(NAME)_$(BRANCH)_$(VER).tgz
STATUS = PWD DOTDIRS ENVDIRS SYNCDIRS NAME BRANCH VER TAR
export STATUS $(STATUS)

.PHONY: clean check $(DIRS)

#ZaZ

# targets AzA

# help: AzA
help:
	@echo 'status   : shows current variables'
	@echo 'list     : shows current files to be installed'
	@echo 'tarinstall  : will install files in designated DEST'
	@echo 'tararchive : create an arcive of the installed files'
	@echo 'check    : will show what has changed wrt Git structure'
	@echo 'clean    : will uninstall the current environment'
	@echo 'tgz      : generate a complete tar file of Git structure'
	@echo 'preview  : show a list of files to be printed'
	@echo 'printout : print the files shown from preview'

#ZaZ

# status AzA
status:
	@for v in $(STATUS); do eval "echo $$v = $${!v}"; done
#ZaZ

# install AzA
install: install-dots install-sync

install-dots:
	@for dir in $(DOTDIRS); do \
	    echo $$dir; \
	    for fr in $$dir/*; do \
	        to=$(DEST)/."$${fr##*/}"; \
		[[ -e $$to ]] || ln $$fr $$to; \
	    done; \
	done

install-sync:
	@for dir in $(SYNCDIRS); do \
	    for fr in $$dir/*; do \
		to=$(DEST)/."$${fr##*/}"; \
		[[ -d $$to ]] || rsync -a $$fr/ $$to; \
	    done; \
	done
#ZaZ

# remove AzA
remove: remove-dots remove-sync

remove-dots:
	@for dir in $(DOTDIRS); do \
	    for fr in $$dir/*; do \
	        to=$(DEST)/."$${fr##*/}"; \
		[[ $$fr -ef $$to ]] && rm $$to || :; \
	    done; \
	done

remove-sync:
	@for dir in $(SYNCDIRS); do \
	    for fr in $$dir/*; do \
		to=$(DEST)/."$${fr##*/}"; \
		[[ -d $$to ]] && rm -r $$to || :; \
	    done; \
	done

# ZaZ

# check AzA
check: check-dots check-syncs

check-dots:
	@for dir in $(DOTDIRS); do \
	    echo checking $$dir; \
	    for fr in $$dir/*; do \
	        to="$${fr##*/}"; \
		[[ $$to -ef $$fr]] || echo missing $$fr; \
	    done; \
	done

check-syncs:
	@for dir in $(SYNCDIRS); do \
	    echo checking $$dir; \
	    for fr in $$dir/*; do \
		to="$${fr##*/}"; \
		[[ -d $$to ]] && diff -r -q $$fr $$to || echo missing $$fr; \
	    done; \
	done
# ZaZ

# gitarchive AzA
gitarchive:
	@git archive --format=tgz --prefix=$(NAME)/ --output=$(TAR) HEAD
#ZaZ

# printout AzA
printout:
	@echo printing
	@for file in $$(git ls-files $(DOTDIRS) $(ENVDIRS)); do \
	    [[ -f $$file ]] || continue; \
	    echo -e "\n#### $$(md5sum $$file))"; \
	    cat $$file; \
	done > review
#	enscript -2 -r -f Courier8 -DDuplex:true -DTumble:true -P local
#ZaZ

#ZaZ
