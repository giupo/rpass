## Submission

This is a new release (first submission to CRAN).

## About the Rust dependency

This package embeds OpenPGP support via the Rust 'pgp' crate, compiled at
install time through 'extendr'/'rextendr' (see `SystemRequirements`). To
comply with CRAN's no-network-access-during-build policy, all Cargo
dependencies are vendored in `src/rust/vendor.tar.xz`; `src/Makevars(.win)`
builds offline (`cargo build --offline`) whenever that file is present,
which is the case in this source tarball. No network access is required to
build or check the package.

## Test environments

* local: Linux (Red Hat Enterprise Linux 8.10, x86_64), R 4.5.3 -- 0 errors | 0 warnings | 0 notes attributable to the package
* win-builder (devel) -- pending
* win-builder (release) -- pending

Three additional NOTEs/WARNINGs seen only in the local environment above are
artifacts of that machine, not of the package, and are not expected on
CRAN's own check machines:

* `checking top-level files ... WARNING`: the `checkbashisms` script is not
  installed locally; `configure`/`cleanup`/`cleanup.win` are plain POSIX
  `sh`.
* `checking compilation flags used ... NOTE` (`-march=cascadelake`): comes
  from this R installation's own `CFLAGS` (a site-tuned HPC build of R),
  not from the package's `Makevars`.
* `checking HTML version of manual ... NOTE`: the `tidy` binary is not
  installed locally.

## R CMD check results

0 errors | 0 warnings | 0 notes (environment-specific items above excluded)

* This is a new release.
