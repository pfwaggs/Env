
SHELL = /bin/bash

BASE = ~/Git/ENV

ifndef DEST
    DEST = $(HOME)
endif

dotfiles := $(notdir $(sort $(wildcard dotfiles/*)))

.PHONY: clean check 

list: dotfiles
	@echo $^;
	@for x in $($^); do \
	    echo -e "\t$$x"; \
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
	@git archive --format tar.gz -o /tmp/$(USER).tar.gz HEAD

txt: Makefile $(sort $(wildcard dotfiles/*)) $(sort $(wildcard envfiles/*))
	@echo making work copy
	@for f in $^; do \
	    [[ -f $$f ]] || continue; \
	    echo -e "\n#### $$f <<<<<<<<<<<<<"; \
	    cat $$f; \
	done > txt

ps: txt
	@enscript -2 -r -DDuplex:true -DTumble:true -o ps txt
	@rm txt

print: ps
	@enscript -Z -P local ps
	@rm ps

