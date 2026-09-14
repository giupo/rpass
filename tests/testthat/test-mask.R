test_that("rpass_secret never leaks via print/format/str/capture.output", {
  secret <- new_rpass_secret("hunter2")

  expect_false(grepl("hunter2", format(secret), fixed = TRUE))
  expect_false(grepl("hunter2", paste(capture.output(print(secret)), collapse = "\n"), fixed = TRUE))
  expect_false(grepl("hunter2", paste(capture.output(str(secret)), collapse = "\n"), fixed = TRUE))
})

test_that("pass_reveal / as.character deliberately unmask", {
  secret <- new_rpass_secret("hunter2")
  expect_equal(pass_reveal(secret), "hunter2")
  expect_equal(as.character(secret), "hunter2")
})

test_that("pass_reveal.default passes plain values through unchanged", {
  expect_equal(pass_reveal("plain"), "plain")
  expect_equal(pass_reveal(42), 42)
})

test_that("pass_show's returned entry masks the password", {
  ctx <- local_test_store()
  kp <- local_test_keypair()
  key <- pass_key(kp$secret_path, passphrase = kp$passphrase, set_default = FALSE)
  pass_import_pubkey(kp$public_path, keyring = ctx$keyring)
  pass_init("", kp$fingerprint, store = ctx$store)

  pass_insert("secret1", "topsecretvalue", store = ctx$store, keyring = ctx$keyring)
  entry <- pass_show("secret1", store = ctx$store, key = key)

  expect_s3_class(entry$password, "rpass_secret")
  out <- paste(capture.output(print(entry)), collapse = "\n")
  expect_false(grepl("topsecretvalue", out, fixed = TRUE))
  expect_equal(pass_reveal(entry$password), "topsecretvalue")
})
