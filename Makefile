
SHELL = /bin/bash

BASE = ~/Git/ENV

ENVDIR = envfiles

ifndef DEST
    DEST = $(HOME)
endif

# this section needs to pull filenames from envsrc file
#fs = fs_*
#fs := $(sort $(wildcard $(fs)))
#envsrc := aliases basevars $(fs)

filter = $(addprefix $(ENVDIR)/, aliases basevars archive)
envfiles = $(sort $(filter-out $(filter), $(wildcard $(ENVDIR)/*)))
envsrc := $(addprefix $(ENVDIR)/, aliases basevars) $(envfiles)

dots = dotfiles/*
dots := $(sort $(notdir $(wildcard $(dots))))

info := dots envsrc 

.PHONEY = $(info) $(addprefix dotfiles/, $(envsrc)) functions $(fs) breakenv

all: $(info)

$(info) :
	@echo listing $@;
	@for x in $($@); do echo $$x; done

dotfiles/envsrc: $(envsrc)
	@cat $^ >| $@

link: dotfiles/envsrc
	@for f in $(dots) envsrc; do \
	    [[ $(DEST)/.$$f -ef dotfiles/$$f ]] || ln dotfiles/$$f $(DEST)/.$$f; \
	done

unlink:
	@for f in $(dots) envsrc; do \
	    [[ ! $(DEST)/.$$f -ef dotfiles/$$f ]] || rm $(DEST)/.$$f; \
	done

archive:
	@git archive --format tar.gz -o /tmp/$(USER).tar.gz HEAD

breakenv2:
	@csplit dotfiles/envsrc '/#>>>> /' {*}
	@perl -anl -E 'say join(" ",$$ARGV, $$F[-1]) if $$F[0]=~/#>>>>/' $(ls -Ixx00 xx*) | \
	    while read x n; do mv $$x $$n; done
	@for d in fns_*; do \
	    d=$$d.wrk; \
	    mkdir $$d; \
	    echo creating $$d files; \
	    csplit --prefix=$$d/xx $${d/.wrk} '/#>>> /' {*}; \
	    cd $$d; \
	    perl -anl -E 'say join(" ",$$ARGV, $$F[-1]) if $$F[0]=~/#>>>/' $(ls -Ixx00 xx*) | \
		while read x n; do mv $$x $$n; done; \
	    cd ..; \
	done

breakenv:
	@csplit dotfiles/envsrc '/#>>>> /' {*}
	@perl -anl -E 'say join(" ",$$ARGV, $$F[-1]) if $$F[0]=~/#>>>>/' xx* | \
	    while read x n; do mv $$x $$n; done
	@for d in fns_*; do \
	    d=$$d.wrk; \
	    mkdir $$d; \
	    echo creating $$d files; \
	    csplit --prefix=$$d/xx $${d/.wrk} '/#>>> /' {*}; \
	    cd $$d; \
	    perl -anl -E 'say join(" ",$$ARGV, $$F[-1]) if $$F[0]=~/#>>>/' xx* | \
		while read x n; do mv $$x $$n; done; \
	    cd ..; \
	done

buildenv:
	@for d in *.wrk; do \
	    f=$${d/wrk/new}
	    if [[ -d $$d ]]; then \
		echo making $$f; \
		cd $$d; \
		cat xx00 $$(ls -Ixx00) > ../$$f; \
		cd ..; \
	    fi; \
	done
	@cat aliases basevars *.new > envsrc.new

txt:
	@echo making work copy
	@for f in Makefile $(dots) $(fs); do \
	    echo -e "\n#### $$f <<<<<<<<<<<<<"; \
	    cat $$f; \
	done > txt

ps: txt
	@enscript -2 -r -DDuplex:true -DTumble:true -o ps txt
	@rm txt

print: ps
	@enscript -Z -P local ps
	@rm ps

