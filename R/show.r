#' Decrypt and show a password store entry
#'
#' @param name Entry name relative to `store` (e.g. `"Lavoro/SECRET"`, no
#'   `.gpg` extension).
#' @param store Store root, see [pass_store()].
#' @param key An `rpass_key`, see [pass_key()]. Defaults to the session's
#'   default key set by the most recent `pass_key()` call.
#' @return An `rpass_entry`: a list with `name`, `password` (a masked
#'   [rpass_secret][new_rpass_secret]), `fields` (named list), and `notes`
#'   (character vector, the raw lines after the password).
#' @export
pass_show <- function(name, store = pass_store(), key = pass_default_key()) {
  path <- .entry_path(name, store)
  if (!fs::file_exists(path)) {
    stop("No such entry: ", name, call. = FALSE)
  }
  raw_bytes <- readBin(path, what = "raw", n = fs::file_size(path))
  plaintext_raw <- decrypt_message(key$handle, raw_bytes)
  text <- rawToChar(plaintext_raw)
  Encoding(text) <- "UTF-8"

  parsed <- parse_entry_body(text)
  structure(
    list(
      name = name,
      password = new_rpass_secret(parsed$password),
      fields = parsed$fields,
      notes = parsed$notes
    ),
    class = "rpass_entry"
  )
}

#' @export
print.rpass_entry <- function(x, ...) {
  cat(sprintf("<rpass_entry %s>\n", x$name))
  cat("  password:", format(x$password), "\n")
  if (length(x$fields) > 0) {
    for (nm in names(x$fields)) {
      cat(sprintf("  %s: %s\n", nm, x$fields[[nm]]))
    }
  }
  invisible(x)
}

#' @keywords internal
.entry_path <- function(name, store = pass_store()) {
  fs::path(fs::path_expand(store), paste0(name, ".gpg"))
}
