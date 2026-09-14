#' Load and unlock a GPG secret key
#'
#' Reads an OpenPGP secret key exported with
#' `gpg --export-secret-keys --armor > mykey.asc` and unlocks it with a
#' passphrase. The passphrase is validated immediately (a wrong passphrase
#' fails here, not on the first [pass_show()]). rpass never reads GnuPG's
#' live agent-managed keyring (`~/.gnupg/private-keys-v1.d`) -- only an
#' explicitly exported armored key file.
#'
#' @param path Path to an armored (`--armor`) exported OpenPGP secret key.
#' @param passphrase Passphrase for the key. Defaults to a hidden prompt via
#'   [getPass::getPass()] -- avoid passing it as a literal argument in a
#'   script, since that can leak into shell/R history.
#' @param set_default If `TRUE` (default), sets this as the session's default
#'   key so `key=` does not need to be supplied to other `pass_*()` calls.
#' @return An `rpass_key` object.
#' @export
pass_key <- function(path,
                      passphrase = getPass::getPass("GPG passphrase: "),
                      set_default = TRUE) {
  path <- fs::path_expand(path)
  if (!fs::file_exists(path)) {
    stop("Secret key file not found: ", path, call. = FALSE)
  }
  handle <- SecretKeyHandle$new(path, passphrase)
  key <- structure(
    list(handle = handle, fingerprint = handle$fingerprint(), path = path),
    class = "rpass_key"
  )
  if (isTRUE(set_default)) {
    assign("default_key", key, envir = .rpass_env)
  }
  key
}

#' @export
print.rpass_key <- function(x, ...) {
  cat(sprintf("<rpass_key %s>\n", x$fingerprint))
  invisible(x)
}

#' Retrieve the session's default key
#'
#' The key most recently set via `pass_key(..., set_default = TRUE)`.
#'
#' @return An `rpass_key` object.
#' @export
pass_default_key <- function() {
  key <- mget("default_key", envir = .rpass_env, ifnotfound = list(NULL))[[1]]
  if (is.null(key)) {
    stop(
      "No default key set. Call pass_key() first, or pass key= explicitly.",
      call. = FALSE
    )
  }
  key
}
