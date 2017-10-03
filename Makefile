# initializing system AzA
SHELL = /bin/bash

ifndef DEST
    DEST = $(HOME)
endif

ifndef DIRS
    DIRS := $(sort $(wildcard dotfiles*)) envfiles
endif

ifndef MISC
    DIRS := $(filter-out %misc%, $(DIRS))
endif

DOTDIRS  := $(sort $(filter dotfiles%, $(DIRS)))
XDIRS    := $(sort $(filter-out dotfiles%, $(DIRS)))
DIRS     := $(DOTDIRS) $(XDIRS)
FILES    := $(foreach dir, $(DIRS), $(sort $(wildcard $(dir)/*)))
#DOTFILES := $(sort $(filter dotfiles%, $(FILES)))
export DIRS FILES DOTDIRS XDIRS

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
STATUS = DIRS COMMIT BASE NAME BRANCH VER TAR
export STATUS $(STATUS)

.PHONY: clean check $(DIRS)

#ZaZ

# targets AzA

# help: AzA
help:
	@echo 'status   : shows current variables'
	@echo 'list     : shows current files to be installed'
	@echo 'install  : will install files in designated DEST'
	@echo 'tarchive : create an arcive of the installed files'
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

# md5sum AzA
md5sum:
	@for dir in $(DIRS); do \
	    echo $$dir; \
	    for file in $$(echo $(FILES) | xargs -n 1 | grep $$dir); do \
		[[ -f $$file ]] || continue; \
		echo -e "\t$$(md5sum $$file)"; \
	    done | sed -e s,$$dir/,,; \
	    echo; \
	done
#ZaZ

# tar archive: AzA
tarchive:
	@tar -cvzf installed.tar.gz -P --xform='s,dotfiles[^/]*/,.,;s,^,$(DEST)/,' $(FILES)
#ZaZ

# install: AzA
install:
	@[[ -d $(DEST) ]] || mkdir -p $(DEST)
	@tar --create --file=- --xform='s,dotfiles[^/]*/,.,g' $(FILES) | \
	    tar -C $(DEST) --extract --file=-
#ZaZ

# check: AzA
check:
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

difference: check

diffs: difference
	@if [[ -f differences ]]; then \
	    cat differences | while read d l; do \
	    diff -y $$d $$l | less; \
	    done; \
	fi

# clean: AzA
clean:
	@echo cleaning up dotfiles:
	@for file in $(FILES); do \
	    if [[ $$file =~ dotfiles ]]; then \
		xfile="$(DEST)/.$${file#dotfiles*/}"; \
	    else \
		xfile="$(DEST)/$$file"; \
	    fi; \
	    echo $$file to $$xfile >&2; \
	    [[ -d $$xfile || -f $$xfile ]] || continue; \
	    [[ -d $$xfile ]] && rm -r "$$xfile" || rm "$$xfile"; \
	done; \
# ZaZ

# git archive AzA
garchive:
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
