
# initializing system AzA
SHELL = /bin/bash

ifndef DEST
    DEST = $(HOME)
endif

ifndef DIRS
    DOTDIRS  := $(sort $(wildcard dotfiles*))
    ENVDIRS  := $(sort $(wildcard envfiles*))
    SYNCDIRS := $(sort $(wildcard syncdirs*))
    DIRS := $(DOTDIRS) $(ENVDIRS) $(SYNCDIRS)
else
    DOTDIRS  := $(filter dotfiles, $(DIRS))
    ENVDIRS  := $(filter envfiles, $(DIRS))
    SYNCDIRS := $(filter syncdirs, $(DIRS))
endif

DOTFILES := $(sort $(filter dotfiles%, $(FILES)))
export DIRS DOTDIRS ENVDIRS SYNCDIRS

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

BASE = $(PWD)
NAME = $(notdir $(BASE))
BRANCH = $(shell git branch | sed -n '/*/p' | cut -c3-)
VER = $(shell git tag | sed -n '$$p')
TAR = $(NAME)_$(BRANCH)_$(VER).tgz
STATUS = PWD DOTDIRS ENVDIRS SYNCDIRS COMMIT BASE NAME BRANCH VER TAR
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
	@for fr in $(DOTDIRS); do \
	    for file in $$fr/*; do \
	        name="$${file##*/}"; \
		[[ -e $(DEST)/.$$name ]] || ln $$file $(DEST)/.$$name; \
	    done; \
	done

install-sync:
	@for fr in $(SYNCDIRS); do \
	    for dir in $$fr/*; do \
		name="$${dir##*/}"; \
		[[ -d $(DEST)/.$$name ]] || rsync -a $$dir/ $(DEST)/.$$name; \
	    done; \
	done

remove: remove-dots remove-sync

remove-dots:
	@for fr in $(DOTDIRS); do \
	    for file in $$fr/*; do \
	        name="$${file##*/}"; \
		[[ -e $(DEST)/.$$name ]] && rm $(DEST)/.$$name || :; \
	    done; \
	done

remove-sync:
	@for fr in $(SYNCDIRS); do \
	    for dir in $$fr/*; do \
		name="$${dir##*/}"; \
		[[ -d $(DEST)/.$$dest ]] && rm -r $(DEST)/.$$name ||:; \
	    done; \
	done

# ZaZ

# check AzA
check:
	@for fr in $(DOTDIRS); do \
	    echo checking $$fr; \
	    for file in $$fr/*; do \
	        name="$${file##*/}"; \
		[[ -e $(DEST)/.$$name ]] || echo missing $$file; \
	    done; \
	done
	@for fr in $(SYNCDIRS); do \
	    echo checking $$fr; \
	    for dir in $$fr/*; do \
		name="$${dir##*/}"; \
		diff -r -q $$dir $(DEST)/.$$name; \
	    done; \
	done
# ZaZ

# tararchive: AzA
tararchive:
	@tar -cvzf installed.tar.gz -P --xform='s,dotfiles[^/]*/,.,;s,^,$(DEST)/,' $(FILES)
#ZaZ

# tarinstall: AzA
tarinstall:
	@[[ -d $(DEST) ]] || mkdir -p $(DEST)
	@tar --create --file=- --xform='s,dotfiles[^/]*/,.,g' $(FILES) | \
	    tar -C $(DEST) --extract --file=-
#ZaZ

# tarcheck: AzA
tarcheck:
	@for file in $(FILES); do \
	    [[ -f $$file ]] \
		|| { echo skipping $$file; continue; }; \
	    [[ $$file =~ dotfiles ]] \
		&& xfile=$(DEST)/."$${file#dotfiles*/}" \
		|| xfile=$(DEST)/$$file; \
	    if [[ -f "$$xfile" ]]; then \
		cmp -s "$$xfile" "$$file" || echo -e $$xfile"\t"$$file > differences; \
	    else \
		echo skipping $$xfile; \
		continue; \
	    fi; \
	done
	@if [[ -s differences ]]; then \
	    echo 'the following dest files are different:'; \
	    cat differences | cut -f1; \
	    echo -e "\n"check differences for the above results; \
	else \
	    [[ -f differences ]] && rm differences; \
	fi
# ZaZ

# gitarchive AzA
gitarchive:
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
	    echo -e "\n#### $$(md5sum $$file))"; \
	    cat $$file; \
	done | \
	enscript -2 -r -f Courier8 -DDuplex:true -DTumble:true -P local
	@rm preview
#ZaZ

#ZaZ
