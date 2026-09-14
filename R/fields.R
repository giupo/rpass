#' Parse a decrypted entry body
#'
#' Follows `pass` convention: the first line is the password/secret; the
#' remaining lines are freeform notes, commonly (but not necessarily)
#' `key: value` pairs. `notes` is kept verbatim (authoritative for
#' round-tripping, e.g. [pass_generate()] with `in_place = TRUE`); `fields`
#' is a best-effort parse of the same lines for convenient access.
#'
#' @param text Decrypted plaintext of an entry.
#' @return A list with `password` (character scalar), `fields` (named list),
#'   `notes` (character vector, one element per line).
#' @keywords internal
parse_entry_body <- function(text) {
  lines <- strsplit(text, "\n", fixed = TRUE)[[1]]
  if (length(lines) == 0) lines <- ""

  password <- lines[1]
  notes <- if (length(lines) > 1) lines[-1] else character()

  field_re <- "^([[:alnum:]_ -]+):[[:space:]]*(.*)$"
  matches <- regmatches(notes, regexec(field_re, notes))
  fields <- list()
  for (m in matches) {
    if (length(m) == 3) {
      fields[[trimws(m[2])]] <- m[3]
    }
  }

  list(password = password, fields = fields, notes = notes)
}

#' Build an entry body from a password, fields, and notes
#'
#' Inverse of [parse_entry_body()]. `fields` are rendered as `key: value`
#' lines appended after `notes`.
#'
#' @param password Password/secret (first line).
#' @param fields Named list of extra `key: value` fields.
#' @param notes Additional freeform lines (character vector).
#' @return A single string, newline-joined, ready to encrypt.
#' @keywords internal
build_entry_body <- function(password, fields = list(), notes = character()) {
  field_lines <- character()
  if (length(fields) > 0) {
    if (is.null(names(fields)) || any(!nzchar(names(fields)))) {
      stop("`fields` must be a fully named list", call. = FALSE)
    }
    field_lines <- sprintf("%s: %s", names(fields), unlist(fields, use.names = FALSE))
  }
  paste(c(password, notes, field_lines), collapse = "\n")
}
