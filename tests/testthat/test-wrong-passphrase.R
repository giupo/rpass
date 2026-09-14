test_that("pass_key fails immediately and clearly on a wrong passphrase", {
  kp <- local_test_keypair()
  expect_error(
    pass_key(kp$secret_path, passphrase = "definitely wrong", set_default = FALSE),
    "incorrect passphrase"
  )
})

test_that("pass_key succeeds with the correct passphrase", {
  kp <- local_test_keypair()
  key <- pass_key(kp$secret_path, passphrase = kp$passphrase, set_default = FALSE)
  expect_s3_class(key, "rpass_key")
  expect_equal(key$fingerprint, kp$fingerprint)
})

test_that("pass_key errors clearly on a missing file", {
  expect_error(
    pass_key("/no/such/file.asc", passphrase = "x", set_default = FALSE),
    "not found"
  )
})
