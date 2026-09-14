test_that("print.rpass_tree renders full nested paths, not just leaf names", {
  ctx <- local_test_store()
  kp <- local_test_keypair()
  pass_import_pubkey(kp$public_path, keyring = ctx$keyring)
  pass_init("", kp$fingerprint, store = ctx$store)
  pass_insert("Lavoro/SECRET", "pw", store = ctx$store, keyring = ctx$keyring)
  pass_insert("Lavoro/LDAP", "pw", store = ctx$store, keyring = ctx$keyring)
  pass_insert("top", "pw", store = ctx$store, keyring = ctx$keyring)

  out <- paste(capture.output(print(pass_list(ctx$store))), collapse = "\n")
  expect_match(out, "Lavoro")
  expect_match(out, "SECRET")
  expect_match(out, "LDAP")
  expect_match(out, "top")
})

test_that("pass_list on a nonexistent store returns an empty rpass_tree", {
  tree <- pass_list(fs::path(withr::local_tempdir(), "does-not-exist"))
  expect_length(unclass(tree), 0)
  expect_s3_class(tree, "rpass_tree")
})
