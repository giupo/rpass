# rpass 0.0.0.9000

* Initial version: native OpenPGP client for `pass`-compatible password
  stores. Read/write support (`pass_show()`, `pass_list()`, `pass_insert()`,
  `pass_generate()`, `pass_rm()`, `pass_mv()`, `pass_cp()`, `pass_init()`),
  built on the Rust `pgp` crate via `extendr`/`rextendr` -- no dependency on
  the `pass` or `gpg` binaries at runtime.
