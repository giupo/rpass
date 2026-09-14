# Throwaway Ed25519/Curve25519 keypair generation for tests, via the
# internal (non-exported) generate_test_keypair() Rust function. Never uses
# a real key or touches ~/.gnupg.

local_test_keypair <- function(user_id = "Test <test@example.com>",
                                passphrase = "correct horse battery staple",
                                env = parent.frame()) {
  dir <- withr::local_tempdir(pattern = "rpass-keys-", .local_envir = env)
  keys <- generate_test_keypair(user_id, passphrase)

  secret_path <- fs::path(dir, "secret.asc")
  public_path <- fs::path(dir, "public.asc")
  writeLines(keys$secret, secret_path)
  writeLines(keys$public, public_path)

  list(
    secret_path = secret_path,
    public_path = public_path,
    passphrase = passphrase,
    fingerprint = public_key_fingerprint(keys$public)
  )
}
