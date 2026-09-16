#' Generate a random password store entry
#'
#' @param name Entry name relative to `store`.
#' @param length Password length.
#' @param symbols If `TRUE` (default), include punctuation symbols in the
#'   character set; otherwise letters and digits only.
#' @param in_place If `TRUE`, decrypt the existing entry first (via `key`)
#'   and preserve its `fields`/`notes` verbatim, replacing only the password
#'   line -- mirrors `pass generate -i`. If `FALSE` (default), creates a new
#'   entry with no extra fields/notes.
#' @param store Store root, see [pass_store()].
#' @param key An `rpass_key`, only needed when `in_place = TRUE`. Defaults to
#'   the session's default key.
#' @param keyring Local public-key keyring, see [pass_keyring_dir()].
#' @param force If `FALSE` (default), refuses to overwrite an existing entry
#'   (ignored when `in_place = TRUE`, which always overwrites).
#' @return The generated [rpass_secret][new_rpass_secret], invisibly.
#' @examples
#' store <- tempfile("rpass-store-")
#' keyring <- tempfile("rpass-keyring-")
#' Sys.setenv(PASSWORD_STORE_DIR = store, RPASS_KEYRING_DIR = keyring)
#'
#' keys <- rpass:::generate_test_keypair("Demo <demo@example.com>", "hunter2")
#' secret_path <- tempfile(fileext = ".asc")
#' public_path <- tempfile(fileext = ".asc")
#' writeLines(keys$secret, secret_path)
#' writeLines(keys$public, public_path)
#'
#' key <- pass_key(secret_path, passphrase = "hunter2")
#' fp <- pass_import_pubkey(public_path)
#' pass_init("", fp)
#'
#' pass_generate("Lavoro/NEW", length = 24)
#' pass_generate("Lavoro/NEW", in_place = TRUE) # rotate, keeping fields/notes
#'
#' Sys.unsetenv(c("PASSWORD_STORE_DIR", "RPASS_KEYRING_DIR"))
#' @export
pass_generate <- function(name,
                           length = 25,
                           symbols = TRUE,
                           in_place = FALSE,
                           store = pass_store(),
                           key = NULL,
                           keyring = pass_keyring_dir(),
                           force = FALSE) {
  password <- .random_password(length, symbols)

  if (isTRUE(in_place)) {
    key <- key %||% pass_default_key()
    existing <- pass_show(name, store = store, key = key)
    # existing$notes is the verbatim, authoritative source for round-tripping;
    # existing$fields is only a best-effort *view* of those same lines, so it
    # must not also be passed here (it would duplicate the field lines).
    return(pass_insert(
      name, password,
      notes = existing$notes,
      store = store, keyring = keyring, force = TRUE
    ))
  }

  pass_insert(name, password, store = store, keyring = keyring, force = force)
}

`%||%` <- function(x, y) if (is.null(x)) y else x

#' @keywords internal
.random_password <- function(length, symbols = TRUE) {
  charset <- c(letters, LETTERS, 0:9)
  if (isTRUE(symbols)) {
    charset <- c(charset, strsplit("!@#$%^&*()-_=+[]{}", "")[[1]])
  }
  idx <- as.integer(openssl::rand_bytes(length)) %% length(charset) + 1L
  paste(charset[idx], collapse = "")
}
