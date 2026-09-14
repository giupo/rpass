test_that("pass_import_pubkey stores the key under its fingerprint", {
  ctx <- local_test_store()
  kp <- local_test_keypair()
  fp <- pass_import_pubkey(kp$public_path, keyring = ctx$keyring)
  expect_true(fs::file_exists(fs::path(ctx$keyring, paste0(fp, ".asc"))))
})

test_that("pass_list_recipients lists imported keys", {
  ctx <- local_test_store()
  kp <- local_test_keypair()
  pass_import_pubkey(kp$public_path, keyring = ctx$keyring)
  recipients <- pass_list_recipients(keyring = ctx$keyring)
  expect_equal(recipients$fingerprint, kp$fingerprint)
})

test_that("lookup_pubkey matches by full fingerprint after a manual drop-in with wrong filename", {
  ctx <- local_test_store()
  kp <- local_test_keypair()
  fs::dir_create(ctx$keyring)
  fs::file_copy(kp$public_path, fs::path(ctx$keyring, "wrongname.asc"))

  armor <- lookup_pubkey(kp$fingerprint, keyring = ctx$keyring)
  expect_equal(public_key_fingerprint(armor), kp$fingerprint)
})

test_that("lookup_pubkey errors clearly when the recipient is unknown", {
  ctx <- local_test_store()
  fs::dir_create(ctx$keyring)
  expect_error(lookup_pubkey("DEADBEEF", keyring = ctx$keyring), "No public key found")
})
