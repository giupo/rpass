test_that("pass_rm removes an entry", {
  ctx <- local_test_store()
  kp <- local_test_keypair()
  pass_import_pubkey(kp$public_path, keyring = ctx$keyring)
  pass_init("", kp$fingerprint, store = ctx$store)
  pass_insert("todelete", "pw", store = ctx$store, keyring = ctx$keyring)

  pass_rm("todelete", store = ctx$store)
  expect_false(fs::file_exists(fs::path(ctx$store, "todelete.gpg")))
})

test_that("pass_rm errors on a missing entry unless force = TRUE", {
  ctx <- local_test_store()
  expect_error(pass_rm("nope", store = ctx$store), "No such entry")
  expect_no_error(pass_rm("nope", store = ctx$store, force = TRUE))
})

test_that("pass_rm(recursive = TRUE) removes a whole directory", {
  ctx <- local_test_store()
  kp <- local_test_keypair()
  pass_import_pubkey(kp$public_path, keyring = ctx$keyring)
  pass_init("", kp$fingerprint, store = ctx$store)
  pass_insert("dir/one", "pw", store = ctx$store, keyring = ctx$keyring)
  pass_insert("dir/two", "pw", store = ctx$store, keyring = ctx$keyring)

  pass_rm("dir", store = ctx$store, recursive = TRUE)
  expect_false(fs::dir_exists(fs::path(ctx$store, "dir")))
})

test_that("pass_mv moves an entry", {
  ctx <- local_test_store()
  kp <- local_test_keypair()
  key <- pass_key(kp$secret_path, passphrase = kp$passphrase, set_default = FALSE)
  pass_import_pubkey(kp$public_path, keyring = ctx$keyring)
  pass_init("", kp$fingerprint, store = ctx$store)
  pass_insert("old/loc", "pw", store = ctx$store, keyring = ctx$keyring)

  pass_mv("old/loc", "new/loc", store = ctx$store)
  expect_false(fs::file_exists(fs::path(ctx$store, "old", "loc.gpg")))
  expect_equal(pass_reveal(pass_show("new/loc", store = ctx$store, key = key)$password), "pw")
})

test_that("pass_cp copies an entry, leaving the original intact", {
  ctx <- local_test_store()
  kp <- local_test_keypair()
  key <- pass_key(kp$secret_path, passphrase = kp$passphrase, set_default = FALSE)
  pass_import_pubkey(kp$public_path, keyring = ctx$keyring)
  pass_init("", kp$fingerprint, store = ctx$store)
  pass_insert("orig", "pw", store = ctx$store, keyring = ctx$keyring)

  pass_cp("orig", "copy", store = ctx$store)
  expect_true(fs::file_exists(fs::path(ctx$store, "orig.gpg")))
  expect_equal(pass_reveal(pass_show("copy", store = ctx$store, key = key)$password), "pw")
})

test_that("pass_init warns when the gpg_id isn't in the local keyring yet", {
  ctx <- local_test_store()
  expect_warning(
    pass_init("", "0000000000000000000000000000000000000000", store = ctx$store),
    "not found in the local keyring"
  )
})
