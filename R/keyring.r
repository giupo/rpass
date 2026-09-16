#' Import a public key into the local rpass keyring
#'
#' `pass`/GnuPG resolve a `.gpg-id` recipient identifier against GnuPG's local
#' keyring (`pubring.kbx`), which rpass intentionally does not parse. Instead,
#' rpass keeps its own small directory of armored public keys (see
#' [pass_keyring_dir()]), populated explicitly via this function, once per
#' recipient.
#'
#' @param armor_file Path to an armored (`--armor`) exported OpenPGP public
#'   key, e.g. from `gpg --export --armor <id> > recipient.asc`.
#' @param keyring Local keyring directory, see [pass_keyring_dir()].
#' @return The recipient's fingerprint, invisibly.
#' @examples
#' keys <- rpass:::generate_test_keypair("Demo <demo@example.com>", "hunter2")
#' public_path <- tempfile(fileext = ".asc")
#' writeLines(keys$public, public_path)
#'
#' keyring <- tempfile("rpass-keyring-")
#' fingerprint <- pass_import_pubkey(public_path, keyring = keyring)
#' fingerprint
#' @export
pass_import_pubkey <- function(armor_file, keyring = pass_keyring_dir()) {
  armor_file <- fs::path_expand(armor_file)
  if (!fs::file_exists(armor_file)) {
    stop("Public key file not found: ", armor_file, call. = FALSE)
  }
  armor_text <- paste(readLines(armor_file, warn = FALSE), collapse = "\n")
  fingerprint <- public_key_fingerprint(armor_text)

  fs::dir_create(keyring, recurse = TRUE)
  dest <- fs::path(keyring, paste0(fingerprint, ".asc"))
  fs::file_copy(armor_file, dest, overwrite = TRUE)
  .refresh_keyring_index(keyring)

  invisible(fingerprint)
}

#' List public keys in the local rpass keyring
#'
#' @param keyring Local keyring directory, see [pass_keyring_dir()].
#' @return A data frame with columns `fingerprint` and `path`.
#' @examples
#' keys <- rpass:::generate_test_keypair("Demo <demo@example.com>", "hunter2")
#' public_path <- tempfile(fileext = ".asc")
#' writeLines(keys$public, public_path)
#'
#' keyring <- tempfile("rpass-keyring-")
#' pass_import_pubkey(public_path, keyring = keyring)
#' pass_list_recipients(keyring)
#' @export
pass_list_recipients <- function(keyring = pass_keyring_dir()) {
  if (!fs::dir_exists(keyring)) {
    return(data.frame(fingerprint = character(), path = character()))
  }
  files <- fs::dir_ls(keyring, glob = "*.asc")
  data.frame(
    fingerprint = fs::path_ext_remove(fs::path_file(files)),
    path = as.character(files),
    stringsAsFactors = FALSE
  )
}

#' Normalize a `.gpg-id` recipient identifier for keyring lookups
#' @keywords internal
.normalize_id <- function(id) {
  toupper(gsub("[^A-Fa-f0-9]", "", id))
}

#' Look up an armored public key by `.gpg-id` recipient identifier
#'
#' Tries an exact filename match first (`<id>.asc`); on a miss, scans every
#' `.asc` file in the keyring, computes its real fingerprint, and matches by
#' suffix (so a short key id or a full fingerprint both work), rebuilding the
#' cached index as it goes.
#'
#' @param id A `.gpg-id` recipient identifier (fingerprint or key id).
#' @param keyring Local keyring directory, see [pass_keyring_dir()].
#' @return Armored public key text.
#' @keywords internal
lookup_pubkey <- function(id, keyring = pass_keyring_dir()) {
  norm_id <- .normalize_id(id)
  direct <- fs::path(keyring, paste0(norm_id, ".asc"))
  if (fs::file_exists(direct)) {
    return(paste(readLines(direct, warn = FALSE), collapse = "\n"))
  }

  if (!fs::dir_exists(keyring)) {
    stop(
      "No public key found for recipient '", id, "' (keyring ", keyring,
      " does not exist). Use pass_import_pubkey() first.",
      call. = FALSE
    )
  }

  files <- fs::dir_ls(keyring, glob = "*.asc")
  index <- lapply(files, function(f) {
    armor_text <- paste(readLines(f, warn = FALSE), collapse = "\n")
    list(fingerprint = public_key_fingerprint(armor_text), armor = armor_text, path = f)
  })
  .write_keyring_index(keyring, vapply(index, `[[`, character(1), "fingerprint"), files)

  match <- Filter(function(e) endsWith(e$fingerprint, norm_id), index)
  if (length(match) == 0) {
    stop(
      "No public key found for recipient '", id, "' in keyring ", keyring,
      ". Use pass_import_pubkey() to add it.",
      call. = FALSE
    )
  }
  if (length(match) > 1) {
    stop(
      "Recipient id '", id, "' matches more than one key in the keyring; ",
      "use the full fingerprint.",
      call. = FALSE
    )
  }
  match[[1]]$armor
}

.refresh_keyring_index <- function(keyring) {
  files <- fs::dir_ls(keyring, glob = "*.asc")
  fingerprints <- fs::path_ext_remove(fs::path_file(files))
  .write_keyring_index(keyring, fingerprints, files)
}

.write_keyring_index <- function(keyring, fingerprints, files) {
  index <- data.frame(
    fingerprint = fingerprints,
    path = as.character(files),
    stringsAsFactors = FALSE
  )
  saveRDS(index, fs::path(keyring, "index.rds"))
  invisible(index)
}
