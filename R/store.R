#' Password store location
#'
#' The root directory of a `pass`-compatible password store: a tree of
#' `<name>.gpg` files with `.gpg-id` files marking encryption recipients per
#' directory. Defaults to the `PASSWORD_STORE_DIR` environment variable (same
#' variable used by the real `pass` CLI), falling back to `~/.password-store`.
#'
#' @param path Store root directory.
#' @return Normalized store path (not required to exist yet).
#' @export
pass_store <- function(path = Sys.getenv("PASSWORD_STORE_DIR", "~/.password-store")) {
  fs::path_expand(path)
}

#' Local public-key keyring location
#'
#' rpass does not read GnuPG's keybox (`pubring.kbx`); instead it keeps its own
#' small directory of armored public keys, indexed by fingerprint, populated
#' via [pass_import_pubkey()]. Defaults to the `RPASS_KEYRING_DIR` environment
#' variable, falling back to `~/.rpass/keyring`.
#'
#' @param path Keyring directory.
#' @return Normalized keyring directory path (not required to exist yet).
#' @export
pass_keyring_dir <- function(path = Sys.getenv("RPASS_KEYRING_DIR", "~/.rpass/keyring")) {
  fs::path_expand(path)
}
