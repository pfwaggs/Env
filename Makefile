
SHELL = /bin/bash

BASE = ~/Git/ENV

ifndef DEST
    DEST = $(HOME)
endif

#misc = archive
#ifdef MISC
#    misc = $(misc) $(MISC)
#endif

#envfiles = $(wildcard $(ENVDIR)/*)
#head = $(addprefix $(ENVDIR)/, aliases basevars)
#tail = $(addprefix $(ENVDIR)/, completes)
#misc := $(addprefix $(ENVDIR)/, $(misc))
#body = $(filter-out $(head) $(tail) $(misc), $(envfiles))
#envfiles := $(head) $(sort $(body)) $(tail)

envfiles := $(notdir $(sort $(wildcard envfiles/envsrc*)))
dotfiles := $(notdir $(sort $(wildcard dotfiles/*)))
files := dotfiles envfiles

.PHONY: clean check 

lists: $(addprefix list, $(files))

list%: %
	@echo $^;
	@for x in $($^); do echo -e "\t$$x"; done

links: $(addprefix link, $(files))

link%: %
	@for f in $($^); do \
	    t=$(DEST)/.$$f; \
	    f=$^/$$f; \
	    [[ $$t -ef $$f ]] || ln $$f $$t; \
	done

clean: $(addprefix clean, $(files))

clean%: %
	@d=; for f in $($^); do f=$(DEST)/.$$f; [[ -f $$f ]] && d+="$$f "; done; rm $$d

checks: $(addprefix check, $(files))

check%: %
	@for f in $($^); do [[ $(DEST)/.$$f -ef $^/$$f ]] || echo missing $$f; done

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

