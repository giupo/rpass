#' Insert a new password store entry
#'
#' Encrypts `password` (plus optional `fields`/`notes`) to the recipients
#' configured for this location (the nearest ancestor `.gpg-id`, see
#' [pass_init()]), whose public keys must already be present in the local
#' rpass keyring (see [pass_import_pubkey()]).
#'
#' Unlike `pass insert -m`'s interactive multi-line prompt, this takes
#' structured arguments -- more scriptable, and avoids terminal-raw-mode
#' handling in a library context.
#'
#' @param name Entry name relative to `store` (e.g. `"Lavoro/SECRET"`).
#' @param password Password/secret (first line of the entry). May be a plain
#'   string or an [rpass_secret][new_rpass_secret].
#' @param fields Named list of extra `key: value` fields.
#' @param notes Additional freeform lines (character vector).
#' @param store Store root, see [pass_store()].
#' @param keyring Local public-key keyring, see [pass_keyring_dir()].
#' @param force If `FALSE` (default), refuses to overwrite an existing entry.
#' @return The written [rpass_secret][new_rpass_secret], invisibly.
#' @export
pass_insert <- function(name,
                         password,
                         fields = list(),
                         notes = character(),
                         store = pass_store(),
                         keyring = pass_keyring_dir(),
                         force = FALSE) {
  path <- .entry_path(name, store)
  if (fs::file_exists(path) && !isTRUE(force)) {
    stop("Entry already exists: ", name, " (use force = TRUE to overwrite)", call. = FALSE)
  }

  password <- pass_reveal(password)
  recipients <- resolve_recipients(name, store)
  armors <- vapply(recipients, lookup_pubkey, character(1), keyring = keyring)

  body <- build_entry_body(password, fields, notes)
  encrypted <- encrypt_message(charToRaw(enc2utf8(body)), unname(armors))

  fs::dir_create(fs::path_dir(path), recurse = TRUE)
  writeBin(encrypted, path)

  invisible(new_rpass_secret(password))
}
