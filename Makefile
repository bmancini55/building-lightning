gitbranch = $(shell git branch --show-current)
foo = ok

all:
	$(info Using git branch: $(gitbranch))
ifneq ($(gitbranch), gh-pages)
	$(error Need to be on gh-pages branch)
	exit 1
endif
	git merge main
	rm -rf docs
	mdbook build
	mv book docs


