#' List entries in a password store
#'
#' @param store Store root, see [pass_store()].
#' @return An `rpass_tree`: a sorted character vector of entry names
#'   (relative to `store`, without the `.gpg` extension), with a print method
#'   that renders them as a tree.
#' @export
pass_list <- function(store = pass_store()) {
  store <- fs::path_expand(store)
  if (!fs::dir_exists(store)) {
    return(structure(character(), class = "rpass_tree", store = store))
  }
  files <- fs::dir_ls(store, recurse = TRUE, type = "file", glob = "*.gpg")
  names <- fs::path_ext_remove(fs::path_rel(files, start = store))
  structure(sort(as.character(names)), class = "rpass_tree", store = store)
}

#' @export
print.rpass_tree <- function(x, ...) {
  cat(sprintf("Password Store: %s\n", attr(x, "store")))
  segments <- strsplit(unclass(x), "/", fixed = TRUE)
  .print_tree_level(segments, prefix = "")
  invisible(x)
}

#' Recursively render a list of path-segment vectors as a `tree`-style listing
#' @keywords internal
.print_tree_level <- function(segments, prefix) {
  if (length(segments) == 0) {
    return(invisible(NULL))
  }
  heads <- vapply(segments, `[[`, character(1), 1)
  for (i in seq_along(unique(heads))) {
    head <- unique(heads)[i]
    is_last <- i == length(unique(heads))
    connector <- if (is_last) "└── " else "├── "
    cat(prefix, connector, head, "\n", sep = "")

    children <- segments[heads == head]
    children <- Filter(function(s) length(s) > 1, children)
    children <- lapply(children, `[`, -1)
    if (length(children) > 0) {
      child_prefix <- paste0(prefix, if (is_last) "    " else "│   ")
      .print_tree_level(children, child_prefix)
    }
  }
}

#' Find entries by name pattern
#'
#' A thin filter over [pass_list()].
#'
#' @param pattern Regular expression matched against entry names.
#' @param store Store root, see [pass_store()].
#' @param ... Passed on to [grepl()].
#' @return Character vector of matching entry names.
#' @export
pass_find <- function(pattern, store = pass_store(), ...) {
  entries <- unclass(pass_list(store))
  entries[grepl(pattern, entries, ...)]
}
