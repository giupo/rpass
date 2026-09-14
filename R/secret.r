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
