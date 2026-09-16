#' Masked secret value
#'
#' A character scalar holding a decrypted secret (a password), wrapped so
#' that accidental printing, logging, or `str()`-ing does not leak it to the
#' console. This is a basic precaution, not a security boundary: the
#' plaintext is still an ordinary R string in memory (R gives no memory
#' locking/zeroing guarantees), and [pass_reveal()] deliberately makes it
#' trivial to unmask. See the package README for the full list of
#' limitations.
#'
#' @param x A character scalar.
#' @return An object of class `rpass_secret`.
#' @keywords internal
new_rpass_secret <- function(x) {
  stopifnot(is.character(x), length(x) == 1)
  structure(x, class = "rpass_secret")
}

#' @export
print.rpass_secret <- function(x, ...) {
  cat(format(x), "\n", sep = "")
  invisible(x)
}

#' @export
format.rpass_secret <- function(x, ...) {
  sprintf("<rpass secret: %d chars>", nchar(unclass(x)))
}

#' @export
str.rpass_secret <- function(object, ...) {
  cat(format(object), "\n")
}

#' @export
as.character.rpass_secret <- function(x, ...) {
  unclass(x)
}

#' Reveal a masked secret
#'
#' Explicitly unmask an [rpass_secret][new_rpass_secret] (or any other masked
#' rpass value), returning the plain value. Deliberately as easy as
#' `as.character()` -- the masking in rpass guards against *accidental*
#' exposure (printing, logging, knitting a report), not deliberate access.
#'
#' @param x An `rpass_secret` object (or plain value, returned unchanged).
#' @return The unmasked value.
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
#' pass_insert("Lavoro/SECRET", "s3kr1t!")
#'
#' entry <- pass_show("Lavoro/SECRET", key = key)
#' entry$password        # masked: <rpass secret: 7 chars>
#' pass_reveal(entry$password)  # "s3kr1t!"
#' pass_reveal("already plain") # non-rpass_secret values pass through
#'
#' Sys.unsetenv(c("PASSWORD_STORE_DIR", "RPASS_KEYRING_DIR"))
#' @export
pass_reveal <- function(x) {
  UseMethod("pass_reveal")
}

#' @export
pass_reveal.default <- function(x) {
  x
}

#' @export
pass_reveal.rpass_secret <- function(x) {
  unclass(x)
}
