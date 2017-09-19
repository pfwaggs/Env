
SHELL = /bin/bash

ifndef DEST
    DEST = $(HOME)
endif

ifdef LINE
    CURRENT := $(shell git log -n 1 --oneline | cut -c1-7)
    COMMIT := $(shell git log -n 20 --oneline | sed -n $(LINE)p | cut -c1-7)
    LIST = $(shell git diff-tree -r --name-only $(CURRENT) $(COMMIT) | \
	perl -nl -E 'say $$_ if -f $$_')
else
    COMMIT := $(shell git log -n 1 --oneline | cut -c1-7)
    LIST = Makefile $(sort $(wildcard dotfiles/*)) $(sort $(wildcard envfiles/*))
endif

BASE = $(PWD)
NAME = $(notdir $(BASE))
BRANCH = $(shell git branch | sed -n '/*/p' | cut -c3-)
VER = $(shell git tag | sed -n '$$p')
TAR = $(NAME)_$(BRANCH)_$(VER).tgz
export COMMIT BASE NAME BRANCH VER TAR

DEST_DOTFILES = $(DEST)
DEST_ENVFILES = $(DEST)/envfiles
dotfiles := $(sort $(wildcard dotfiles/*))
envfiles := $(sort $(wildcard envfiles/*))
export dotfiles envfiles DEST_DOTFILES DEST_ENVFILES

$(shell [[ -d $(DEST_DOTFILES) ]] || mkdir $(DEST_DOTFILES))
$(shell [[ -d $(DEST_ENVFILES) ]] || mkdir $(DEST_ENVFILES))

.PHONY: clean check

status:
	@for v in COMMIT BASE NAME BRANCH VER TAR DEST_DOTFILES DEST_ENVFILES; do \
	    eval "echo $$v = $${!v}"; \
	done

list: dotfiles envfiles
	@for dir in $^; do \
	    echo $$dir; \
	    for file in $${!dir}; do \
		echo -e "\t$${file#*/}"; \
	    done; \
	    echo; \
	done

links: dotfiles envfiles
	@for dir in $^; do \
	    [[ $$dir = dotfiles ]] && d='.' || d=''; \
	    dest=DEST_$${dir^^}; dest=$${!dest}; \
	    for file in $${!dir}; do \
		to=$$dest/$$d$${file#*/}; \
		[[ $$to -ef $$file ]] || ln $$file $$to; \
	    done; \
	done

clean: dotfiles envfiles
	@for dir in $^; do \
	    [[ $$dir = dotfiles ]] && d='.' || d=''; \
	    dest=DEST_$${dir^^}; dest=$${!dest}; \
	    for file in $${!dir}; do \
		x=$$dest/$$d$${file#*/}; \
		[[ -f $$x ]] && echo $$x; \
	    done; \
	done | xargs rm

check: dotfiles envfiles
	@for dir in $^; do \
	    [[ $$dir = dotfiles ]] && d='.' || d=''; \
	    dest=DEST_$${dir^^}; dest=$${!dest}; \
	    for file in $${!dir}; do \
		x=$$dest/$$d$${file#*/}; \
		[[ $$x -ef $$file ]] || echo missing $$x; \
	    done; \
	done

archive:
	@git archive --format=tgz --prefix=$(NAME)/ --output=$(TAR) HEAD

ltxt:
	@echo listing updated files since $(COMMIT)
	@for f in $(LIST); do \
	    echo -e "\t$$f"; \
	done
flist:
	@echo making flist
	@for x in $(LIST); do echo $$x; done > flist

txt: flist
	@echo making text file
	@for f in $$(cat $^); do \
	    echo checking $$f >&2; \
	    [[ -f $$f ]] || continue; \
	    echo -e "\n#### $$f <<<<<<<<<<<<<"; \
	    cat $$f; \
	done > txt

ps: txt
	@echo converting text to ps.
	@enscript -2 -r -DDuplex:true -DTumble:true -o $@ $^
	@rm $^

print: ps
	@echo printing ps file
	@enscript -Z -P local $^
	@rm $^
