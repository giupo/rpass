# Makefile per pacchetti R

R_BIN = R
RSCRIPT_BIN = Rscript

# Target di default
.PHONY: all
all: build

# Costruisce il pacchetto .tar.gz
.PHONY: build
build:
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
changelog:
	uv run gitchangelog | grep -v "git-svn-id" > NEWS.md
	git add NEWS.md && git commit -am "Aggiorna NEWS.md"

.PHONY: autotest
autotest:
	$(RSCRIPT_BIN) -e 'testthat::auto_test_package()'

.PHONY: coverage
coverage:
	$(RSCRIPT_BIN) -e 'covr::package_coverage()'

.PHONY: zero_coverage
zero_coverage:
	$(RSCRIPT_BIN) -e 'covr::zero_coverage(covr::package_coverage())'

# Pulizia
.PHONY: clean
clean:
	rm -f *.tar.gz
	rm -rf *.Rcheck
	rm -f src/*.so src/*.o

.PHONY: install
install:
	$(R_BIN) --vanilla CMD INSTALL .

.PHONY: bump
bump:
	uv run bumpversion $(TYPE)
