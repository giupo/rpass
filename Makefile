# Makefile per pacchetti R

R_BIN ?= R
RSCRIPT_BIN ?= Rscript

# Estrazione nome e versione dal file DESCRIPTION
PKG_NAME := $(shell grep -i '^Package:' DESCRIPTION | sed 's/.*: *//')
PKG_VERSION := $(shell grep -i '^Version:' DESCRIPTION | sed 's/.*: *//')
PKG_FILE := $(PKG_NAME)_$(PKG_VERSION).tar.gz

# Target di default
.PHONY: all
all: build

# Costruisce il pacchetto .tar.gz
.PHONY: build
build: $(PKG_FILE)

$(PKG_FILE): DESCRIPTION NAMESPACE $(wildcard R/*.R) $(wildcard man/*) $(wildcard src/*)
	$(R_BIN) --vanilla CMD build .

# Check del pacchetto
.PHONY: check
check:
	$(RSCRIPT_BIN) -e 'devtools::check()'

# Esegue i test
.PHONY: test
test:
	$(RSCRIPT_BIN) -e 'devtools::test()'

# Genera la documentazione (NAMESPACE + man/)
.PHONY: document
document:
	$(RSCRIPT_BIN) -e 'devtools::document()'

# Changelog con gitchangelog → NEWS.md
.PHONY: changelog
changelog: NEWS.md

NEWS.md: DESCRIPTION NAMESPACE $(wildcard R/*.R) $(wildcard man/*) $(wildcard src/*)
	uv run gitchangelog | grep -v "git-svn-id" > NEWS.md
	git add NEWS.md && git commit -am "Aggiorna NEWS.md"

autotest:
	$(RSCRIPT_BIN) -e 'testthat::auto_test_package()'

coverage:
	$(RSCRIPT_BIN) -e 'covr::package_coverage()'

zero_coverage:
	$(RSCRIPT_BIN) -e 'covr::zero_coverage(covr::package_coverage())'

# Pulizia
.PHONY: clean
clean:
	rm -f $(PKG_FILE)
	rm -rf $(PKG_NAME).Rcheck
	rm -f src/*.so src/*.o

install: $(PKG_FILE)
	$(R_BIN) --vanilla CMD INSTALL $(PKG_FILE)

bump:
	uv run bumpversion $(TYPE)
