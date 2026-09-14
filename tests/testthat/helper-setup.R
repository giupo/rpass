# Every test runs against isolated temp directories, never the real
# ~/.password-store or ~/.rpass/keyring. This is autouse (helper- prefix) so
# it applies to every test file without opting in.

local_test_store <- function(env = parent.frame()) {
  store <- withr::local_tempdir(pattern = "rpass-store-", .local_envir = env)
  keyring <- withr::local_tempdir(pattern = "rpass-keyring-", .local_envir = env)

  real_home_store <- fs::path_expand("~/.password-store")
  stopifnot(!identical(fs::path_norm(store), fs::path_norm(real_home_store)))

  withr::local_envvar(
    c(PASSWORD_STORE_DIR = store, RPASS_KEYRING_DIR = keyring),
    .local_envir = env
  )

  list(store = store, keyring = keyring)
}
