test_that("pass_generate produces a password of the requested length", {
  ctx <- local_test_store()
  kp <- local_test_keypair()
  pass_import_pubkey(kp$public_path, keyring = ctx$keyring)
  pass_init("", kp$fingerprint, store = ctx$store)

  secret <- pass_generate("gen1", length = 30, store = ctx$store, keyring = ctx$keyring)
  expect_equal(nchar(pass_reveal(secret)), 30)
})

test_that("pass_generate without symbols uses only alnum characters", {
  ctx <- local_test_store()
  kp <- local_test_keypair()
  pass_import_pubkey(kp$public_path, keyring = ctx$keyring)
  pass_init("", kp$fingerprint, store = ctx$store)

  secret <- pass_generate("gen2", length = 50, symbols = FALSE, store = ctx$store, keyring = ctx$keyring)
  expect_true(grepl("^[[:alnum:]]+$", pass_reveal(secret)))
})

test_that("pass_generate(in_place = TRUE) preserves fields and notes", {
  ctx <- local_test_store()
  kp <- local_test_keypair()
  key <- pass_key(kp$secret_path, passphrase = kp$passphrase, set_default = FALSE)
  pass_import_pubkey(kp$public_path, keyring = ctx$keyring)
  pass_init("", kp$fingerprint, store = ctx$store)

  pass_insert(
    "gen3", "oldpassword",
    fields = list(login = "someone"), notes = "keep me",
    store = ctx$store, keyring = ctx$keyring
  )
  old_entry <- pass_show("gen3", store = ctx$store, key = key)

  new_secret <- pass_generate(
    "gen3", length = 20, in_place = TRUE,
    store = ctx$store, key = key, keyring = ctx$keyring
  )
  new_entry <- pass_show("gen3", store = ctx$store, key = key)

  expect_false(identical(pass_reveal(new_secret), pass_reveal(old_entry$password)))
  expect_equal(new_entry$fields, old_entry$fields)
  expect_equal(new_entry$notes, old_entry$notes)
})
