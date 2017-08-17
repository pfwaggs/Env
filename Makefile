
SHELL = /bin/bash

BASE = ~/Git/ENV

ENVDIR = envfiles
DOTDIR = dotfiles

ifndef DEST
    DEST = $(HOME)
endif

misc = archive
ifdef MISC
    misc = $(misc) $(MISC)
endif

envfiles = $(wildcard $(ENVDIR)/*)
head = $(addprefix $(ENVDIR)/, aliases basevars)
tail = $(addprefix $(ENVDIR)/, completes)
misc := $(addprefix $(ENVDIR)/, $(misc))
body = $(filter-out $(head) $(tail) $(misc), $(envfiles))
envfiles := $(head) $(sort $(body)) $(tail)

dotfiles := $(sort $(notdir $(wildcard $(DOTDIR)/*)))

info := dotfiles envfiles

.PHONY: $(info) $(dotfiles) clean check 

all: $(info)

$(info):
	@echo listing $@;
	@for x in $($@); do echo $$x; done

$(DEST)/.envsrc: $(envfiles)
	@cat $^ >| $@

envsrc: $(DEST)/.envsrc

link: envsrc
	@for f in $(dotfiles); do \
	    [[ $(DEST)/.$$f -ef dotfiles/$$f ]] || ln dotfiles/$$f $(DEST)/.$$f; \
	done

clean: $(addprefix $(DEST)/., envsrc $(dotfiles))
	@rm $^

check: $(dotfiles)
	@for f in $^; do [[ $(DEST)/.$$f -ef $(DOTDIR)/$$f ]] || echo missing $$f; done
	@[[ -s $(DEST)/.envsrc ]] || echo missing envsrc

archive:
	@git archive --format tar.gz -o /tmp/$(USER).tar.gz HEAD

txt:
	@echo making work copy
	@for f in Makefile $(dotfiles) $(envfiles); do \
	    echo -e "\n#### $$f <<<<<<<<<<<<<"; \
	    cat $$f; \
	done > txt

ps: txt
	@enscript -2 -r -DDuplex:true -DTumble:true -o ps txt
	@rm txt

print: ps
	@enscript -Z -P local ps
	@rm ps

