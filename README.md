# rpass

A native R client for [`pass`](https://www.passwordstore.org/)-compatible
password stores. rpass reads and writes the same `~/.password-store` tree of
`.gpg` files that `pass` uses, but does its own OpenPGP parsing, decryption
and encryption -- it never shells out to the `pass` or `gpg` binaries, and
never reads GnuPG's live agent-managed keyring.

OpenPGP support comes from the Rust [`pgp`](https://docs.rs/pgp)
crate (aka [`rpgp`](https://github.com/rpgp/rpgp)), embedded via
[`extendr`](https://extendr.rs/)/`rextendr` and compiled when the
package is installed. Installing rpass therefore requires a Rust toolchain
(`rustc`/`cargo`) at build time, but nothing extra at runtime.

## Installation

```r
# install.packages("remotes")
remotes::install_github("<your-username>/rpass")
```

Requires `rustc` >= 1.88 and `cargo` available at install time.

## Setup

rpass never reads your GPG secret key from GnuPG's live keyring. Export it
once, as armored text:

```sh
gpg --export-secret-keys --armor your-key-id > mykey.asc
```

rpass also keeps its own tiny local keyring of *public* keys (it does not
parse GnuPG's `pubring.kbx`), used to resolve the recipients listed in a
store directory's `.gpg-id` file when encrypting new entries:

```sh
gpg --export --armor your-key-id > mypublic.asc
```

```r
library(rpass)

key <- pass_key("mykey.asc")          # prompts for the passphrase (getPass)
pass_import_pubkey("mypublic.asc")    # populates ~/.rpass/keyring
```

## Usage

```r
pass_list()
#> Password Store: ~/.password-store
#> └── Lavoro
#>     ├── LDAP
#>     └── SECRET

entry <- pass_show("Lavoro/SECRET")
entry$password        # masked: <rpass secret: 12 chars>
pass_reveal(entry$password)   # explicit unmask
entry$fields$login

pass_insert("Lavoro/NEW", "a-password", fields = list(login = "me"))
pass_generate("Lavoro/NEW", length = 24, in_place = TRUE)
pass_mv("Lavoro/NEW", "Lavoro/RENAMED")
pass_rm("Lavoro/RENAMED")
```

## Compatibility notes (vs. upstream `pass`)

- **`.gpg-id` recipients must be full fingerprints.** Upstream `pass`/GnuPG
  can resolve a name or email against GnuPG's keyring; rpass has no such
  resolution engine, so [`pass_init()`] requires the complete fingerprint.
- **Recipient public keys must be imported once via [`pass_import_pubkey()`]**
  before you can encrypt to them -- rpass does not parse GnuPG's keybox
  (`pubring.kbx`) format.
- **`pass_insert()` takes structured arguments** (`password=`, `fields=`,
  `notes=`) instead of `pass insert -m`'s interactive multi-line prompt.
- **No git integration.** Real `pass` can auto-commit changes to a git repo
  backing the store; rpass does not do this (yet).
- Entries created by rpass are never compressed (matching `pass`'s own
  `--compress-algo=none`), but rpass *reads* compressed entries fine (e.g.
  ones created by plain `gpg -e`, which compresses by default).

## Security limitations

rpass takes basic precautions, but is not a hardened secrets manager:

- Decrypted passwords are wrapped in a masked `rpass_secret` class so they
  are not accidentally printed, logged, or included in a knitted report --
  but [`pass_reveal()`]/`as.character()` deliberately make unmasking trivial.
  This guards against *accidental* exposure, not deliberate access.
- Passphrases are read via [`getPass::getPass()`] (hidden input) by default;
  avoid passing one as a literal function argument in a script, since that
  can end up in shell/R history or process listings.
- **R gives no memory-locking or zeroing guarantees.** Decrypted plaintext
  and unlocked private key material are ordinary R/Rust values in process
  memory for the life of the session; nothing in rpass (or R itself)
  prevents them from being paged to disk (swap) or lingering in memory after
  use. Don't use rpass in a threat model that requires that guarantee.
- rpass never writes decrypted plaintext to disk or to any log.

## Development

```r
devtools::load_all()
devtools::test()
```

Tests generate throwaway OpenPGP keys and stores in temporary directories on
every run; they never touch a real `~/.password-store` or `~/.gnupg`.
