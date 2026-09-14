#' Resolve `.gpg-id` recipients for an entry
#'
#' Mirrors `set_gpg_recipients()` from the real `pass` shell script: starting
#' at the directory containing `entry_name`, walk up towards `store` looking
#' for the first `.gpg-id` file (closest ancestor wins, like `.gitignore`
#' resolution). Returns the non-comment, non-blank lines of that file --
#' recipient identifiers (fingerprints), not key material.
#'
#' @param entry_name Entry name relative to `store` (e.g. `"Lavoro/SECRET"`,
#'   no `.gpg` extension), or a directory path for [pass_init()].
#' @param store Store root, see [pass_store()].
#' @return Character vector of recipient identifiers.
#' @keywords internal
resolve_recipients <- function(entry_name, store = pass_store()) {
  store <- fs::path_norm(store)
  dir <- fs::path_norm(fs::path(store, fs::path_dir(entry_name)))

  repeat {
    candidate <- fs::path(dir, ".gpg-id")
    if (fs::file_exists(candidate)) {
      lines <- readLines(candidate, warn = FALSE)
      lines <- trimws(sub("#.*$", "", lines))
      return(lines[nzchar(lines)])
    }
    if (dir == store || fs::path_dir(dir) == dir) {
      stop(
        "No .gpg-id found for '", entry_name, "' under ", store,
        ". Run pass_init() first.",
        call. = FALSE
      )
    }
    dir <- fs::path_dir(dir)
  }
}
