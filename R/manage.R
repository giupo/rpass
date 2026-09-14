#' Remove a password store entry (or directory of entries)
#'
#' @param name Entry name, or a directory prefix when `recursive = TRUE`.
#' @param store Store root, see [pass_store()].
#' @param recursive If `TRUE`, `name` is treated as a directory and all
#'   entries under it are removed.
#' @param force If `FALSE` (default), errors when there is nothing to remove.
#' @return `NULL`, invisibly.
#' @export
pass_rm <- function(name, store = pass_store(), recursive = FALSE, force = FALSE) {
  if (isTRUE(recursive)) {
    dir <- fs::path(fs::path_expand(store), name)
    if (!fs::dir_exists(dir)) {
      if (!isTRUE(force)) stop("No such directory: ", name, call. = FALSE)
      return(invisible(NULL))
    }
    fs::dir_delete(dir)
    return(invisible(NULL))
  }

  path <- .entry_path(name, store)
  if (!fs::file_exists(path)) {
    if (!isTRUE(force)) stop("No such entry: ", name, call. = FALSE)
    return(invisible(NULL))
  }
  fs::file_delete(path)
  invisible(NULL)
}

#' Move (rename) a password store entry
#'
#' Note: this moves the ciphertext file as-is; it does not re-encrypt to a
#' new `.gpg-id` even if `to` falls under a directory with different
#' recipients. Use [pass_rm()] + [pass_insert()] if re-encryption is needed.
#'
#' @param from,to Entry names relative to `store`.
#' @param store Store root, see [pass_store()].
#' @param force If `FALSE` (default), refuses to overwrite an existing `to`.
#' @return `NULL`, invisibly.
#' @export
pass_mv <- function(from, to, store = pass_store(), force = FALSE) {
  from_path <- .entry_path(from, store)
  to_path <- .entry_path(to, store)
  if (!fs::file_exists(from_path)) {
    stop("No such entry: ", from, call. = FALSE)
  }
  if (fs::file_exists(to_path) && !isTRUE(force)) {
    stop("Entry already exists: ", to, " (use force = TRUE to overwrite)", call. = FALSE)
  }
  fs::dir_create(fs::path_dir(to_path), recurse = TRUE)
  fs::file_move(from_path, to_path)
  invisible(NULL)
}

#' Copy a password store entry
#'
#' Like [pass_mv()], copies the ciphertext as-is without re-encrypting.
#'
#' @inheritParams pass_mv
#' @return `NULL`, invisibly.
#' @export
pass_cp <- function(from, to, store = pass_store(), force = FALSE) {
  from_path <- .entry_path(from, store)
  to_path <- .entry_path(to, store)
  if (!fs::file_exists(from_path)) {
    stop("No such entry: ", from, call. = FALSE)
  }
  if (fs::file_exists(to_path) && !isTRUE(force)) {
    stop("Entry already exists: ", to, " (use force = TRUE to overwrite)", call. = FALSE)
  }
  fs::dir_create(fs::path_dir(to_path), recurse = TRUE)
  fs::file_copy(from_path, to_path, overwrite = isTRUE(force))
  invisible(NULL)
}

#' Set the `.gpg-id` recipients for a store directory
#'
#' Unlike upstream `pass`, `gpg_id` must be full fingerprint(s) -- rpass has
#' no keyring-resolution engine to turn a name/email into a fingerprint.
#'
#' @param path Directory relative to `store` (use `""` for the store root).
#' @param gpg_id One or more recipient fingerprints.
#' @param store Store root, see [pass_store()].
#' @return `NULL`, invisibly.
#' @export
pass_init <- function(path, gpg_id, store = pass_store()) {
  gpg_id <- .normalize_id(gpg_id)
  dir <- fs::path(fs::path_expand(store), path)
  fs::dir_create(dir, recurse = TRUE)
  writeLines(gpg_id, fs::path(dir, ".gpg-id"))

  keyring <- pass_keyring_dir()
  missing <- gpg_id[!vapply(gpg_id, function(id) {
    fs::file_exists(fs::path(keyring, paste0(id, ".asc")))
  }, logical(1))]
  if (length(missing) > 0) {
    warning(
      "gpg_id(s) not found in the local keyring (", pass_keyring_dir(), "): ",
      paste(missing, collapse = ", "),
      ". Import them with pass_import_pubkey() before inserting entries.",
      call. = FALSE
    )
  }
  invisible(NULL)
}
