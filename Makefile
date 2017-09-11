
SHELL = /bin/bash

ifndef DEST
    DEST = $(HOME)
endif

ifdef COMMIT
    CURRENT := $(shell git log -n 1 --oneline | cut -c1-7)
    COMMIT := $(shell git log -n 20 --oneline | sed -n $(COMMIT)p | cut -c1-7)
    LIST = $(shell git diff-tree -r --name-only $(CURRENT) $(COMMIT) | \
	perl -nl -E 'say $$_ if -f $$_')
else
    COMMIT := $(shell git log -n 1 --oneline | cut -c1-7)
    LIST = Makefile $(sort $(wildcard dotfiles/*)) $(sort $(wildcard envfiles/*))
endif

BASE = ~/Git/ENV
NAME = $(notdir $(BASE))
BRANCH = $(shell git branch | sed -n '/*/p' | cut -c3-)
VER = $(shell git tag | sed -n '$$p')
TAR = $(NAME)_$(BRANCH)_$(VER).tgz
export COMMIT BASE NAME BRANCH VER

dotfiles := $(notdir $(sort $(wildcard dotfiles/*)))

.PHONY: clean check 

status:
	@for v in COMMIT BASE NAME BRANCH VER; do \
	    eval "echo $$v = $${!v}"; \
	done

list: dotfiles
	@echo $^;
	@for f in $($^); do \
	    echo -e "\t$$f"; \
	done

links: dotfiles
	@for f in $($^); do \
	    t=$(DEST)/.$$f; \
	    f=$^/$$f; \
	    [[ $$t -ef $$f ]] || ln $$f $$t; \
	done

clean: dotfiles
	@for f in $($^); do \
	    f=$(DEST)/.$$f; \
	    [[ -f $$f ]] && d+="$$f "; \
	done; \
	[[ $$d ]] && rm $$d

check: dotfiles
	@for f in $($^); do \
	    [[ $(DEST)/.$$f -ef $^/$$f ]] || echo missing $$f; \
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
