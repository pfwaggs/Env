# initializing system AzA
SHELL = /bin/bash

ifndef DEST
    DEST = $(HOME)
endif

ifdef XTRAS
    XTRAS := $(sort $(filter-out dotfiles, $(XTRAS)))
endif

#DOTFILES := $(sort $(wildcard dotfiles/*))
DOTFILES := $(sort $(shell find dotfiles -type f))
#$(error $(DOTFILES))
FILES := $(DOTFILES) $(foreach dir, $(XTRAS), $(sort $(shell find $(dir) -type f)))
DIRS := dotfiles $(XTRAS)

export FILES XTRAS

ifdef LINE
    export LINE
    CURRENT := $(shell git log -n 1 --oneline | cut -c1-7)
    COMMIT := $(shell git log -n 20 --oneline | sed -n $(LINE)p | cut -c1-7)
    MASTER = $(shell git diff-tree -r --name-only $(CURRENT) $(COMMIT) | \
	perl -nl -E 'say $$_ if -f $$_')
else
    COMMIT := $(shell git log -n 1 --oneline | cut -c1-7)
    MASTER = Makefile $(FILES)
endif

.PHONY: clean check $(DIRS)

BASE = $(PWD)
NAME = $(notdir $(BASE))
BRANCH = $(shell git branch | sed -n '/*/p' | cut -c3-)
VER = $(shell git tag | sed -n '$$p')
TAR = $(NAME)_$(BRANCH)_$(VER).tgz
STATUS = COMMIT BASE NAME BRANCH VER TAR
export STATUS $(STATUS)

#ZaZ

# targets AzA

help:
	@echo 'status   shows current variables'
	@echo 'list     shows current files to be installed'
	@echo 'install  will install files in designated DEST'
	@echo 'check    will show what has changed wrt Git structure'
	@echo 'clean    will uninstall the current environment'
	@echo 'tgz      generate a complete tar file of Git structure'
	@echo 'preview  see 1) current file list, or 2) file list wrt'
	@echo '             given Git check-in'
	@echo 'printout a printed copy of changes.'

all: info

info: status list

# status AzA
status:
	@for v in $(STATUS); do \
	    eval "echo $$v = $${!v}"; \
	done
#ZaZ

# list AzA
list:
	@for dir in $(DIRS); do \
	    echo $$dir; \
	    for file in $$(echo $(FILES) | xargs -n 1 | grep $$dir); do \
		echo -e "\t$${file#*/}"; \
	    done; \
	    echo; \
	done
#ZaZ

## making environment AzA
#files:
#	@tar cf $@.tar --xform='s,^dotfiles/,.,' $(FILES)
##ZaZ

# install: AzA
install:
	@echo $(FILES) | xargs -n 1 | \
	    sed -e "s,dotfiles/,.,g;s,^,$(DEST)/,g" | \
	    tee | tar cf installed.tar -P -T -
#ZaZ

# check: AzA
check:
	@echo the following dest files are different:
	@for file in $(FILES); do \
	    x="$(DEST)/$${file/dotfiles\//.}"; \
	    [[ -f $$x ]] || continue; \
    	    cmp -s "$$x" "$$file" || echo $$x; \
	done | tee differences
#ZaZ

# clean: AzA
clean:
	@echo cleaning up dotfiles:
	@for file in $(DOTFILES); do \
	    rm -r "$(DEST)/$${file/dotfiles\//.}"; \
	done
	@if [[ $$XTRAS ]]; then \
	    echo removing extra dirs; \
	    for dir in $(XTRAS); do \
		echo -e "\t$(DEST)/$$dir"; \
		rm -r $(DEST)/$$dir; \
	    done; \
	fi
# ZaZ

# tgz archive AzA
archive:
	@git archive --format=tgz --prefix=$(NAME)/ --output=$(TAR) HEAD
#ZaZ

# preview AzA
preview:
	@if [[ $$LINE ]]; then \
	    echo listing updated files since $(COMMIT); \
	else \
	    echo preview file list; \
	fi
	@echo $(MASTER) | xargs -n 1 | tee preview
#ZaZ

# printout AzA
printout: preview
	@echo printing
	@for file in $$(cat preview); do \
	    [[ -f $$file ]] || continue; \
	    echo -e "\n#### $$file <<<<<<<<<<<<<"; \
	    cat $$file; \
	done | tee | \
	enscript -2 -r -DDuplex:true -DTumble:true -P local
	@rm preview
#ZaZ

#ZaZ
