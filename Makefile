
SHELL = /bin/bash

CURRENT = $(shell git log -n 1 --oneline | cut -c1-7)
BASE = ~/Git/ENV
NAME = $(notdir $(BASE))
BRANCH = $(shell git branch | sed -n '$$p' | cut -c3-)
VER = $(shell git tag | sed -n '$$p')
TAR = $(NAME)_$(BRANCH)_$(VER).tgz
export CURRENT BASE NAME BRANCH VER

ifndef DEST
    DEST = $(HOME)
endif

ifdef COMMIT
    LIST = $(shell git diff-tree -r --name-only $(CURRENT) $(COMMIT) | \
	perl -nl -E 'say $$_ if -f $$_')
else
    LIST = Makefile $(sort $(wildcard dotfiles/*)) $(sort $(wildcard envfiles/*))
endif

dotfiles := $(notdir $(sort $(wildcard dotfiles/*)))

.PHONY: clean check 

status:
	@for v in CURRENT BASE NAME BRANCH VER; do \
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

#full.txt: Makefile $(sort $(wildcard dotfiles/*)) $(sort $(wildcard envfiles/*))
txt:
	@echo making text file
	@for f in $(LIST); do \
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
