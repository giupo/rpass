test_that("full generate-key -> import -> init -> insert -> show cycle round-trips", {
  ctx <- local_test_store()
  kp <- local_test_keypair()

  key <- pass_key(kp$secret_path, passphrase = kp$passphrase, set_default = FALSE)
  fp <- pass_import_pubkey(kp$public_path, keyring = ctx$keyring)
  expect_equal(fp, kp$fingerprint)

  pass_init("Lavoro", kp$fingerprint, store = ctx$store)
  expect_true(fs::file_exists(fs::path(ctx$store, "Lavoro", ".gpg-id")))

  pass_insert(
    "Lavoro/SECRET", "s3kr1t!",
    fields = list(login = "gacito", url = "https://example.com"),
    notes = "a free-text note line",
    store = ctx$store, keyring = ctx$keyring
  )
  expect_true(fs::file_exists(fs::path(ctx$store, "Lavoro", "SECRET.gpg")))

  entry <- pass_show("Lavoro/SECRET", store = ctx$store, key = key)
  expect_equal(pass_reveal(entry$password), "s3kr1t!")
  expect_equal(entry$fields$login, "gacito")
  expect_equal(entry$fields$url, "https://example.com")
  expect_true("a free-text note line" %in% entry$notes)
})

test_that("pass_list reflects inserted entries", {
  ctx <- local_test_store()
  kp <- local_test_keypair()
  pass_import_pubkey(kp$public_path, keyring = ctx$keyring)
  pass_init("", kp$fingerprint, store = ctx$store)

  pass_insert("a/one", "p1", store = ctx$store, keyring = ctx$keyring)
  pass_insert("a/two", "p2", store = ctx$store, keyring = ctx$keyring)
  pass_insert("top", "p3", store = ctx$store, keyring = ctx$keyring)

  entries <- unclass(pass_list(ctx$store))
  expect_setequal(entries, c("a/one", "a/two", "top"))
})

test_that("pass_find filters by pattern", {
  ctx <- local_test_store()
  kp <- local_test_keypair()
  pass_import_pubkey(kp$public_path, keyring = ctx$keyring)
  pass_init("", kp$fingerprint, store = ctx$store)
  pass_insert("a/one", "p1", store = ctx$store, keyring = ctx$keyring)
  pass_insert("b/two", "p2", store = ctx$store, keyring = ctx$keyring)

  expect_equal(pass_find("^a/", store = ctx$store), "a/one")
})

test_that("multi-recipient insert can be decrypted by either recipient's key", {
  ctx <- local_test_store()
  kp1 <- local_test_keypair(user_id = "One <one@example.com>")
  kp2 <- local_test_keypair(user_id = "Two <two@example.com>")

  pass_import_pubkey(kp1$public_path, keyring = ctx$keyring)
  pass_import_pubkey(kp2$public_path, keyring = ctx$keyring)
  pass_init("", c(kp1$fingerprint, kp2$fingerprint), store = ctx$store)

  pass_insert("shared", "sharedsecret", store = ctx$store, keyring = ctx$keyring)

  key1 <- pass_key(kp1$secret_path, passphrase = kp1$passphrase, set_default = FALSE)
  key2 <- pass_key(kp2$secret_path, passphrase = kp2$passphrase, set_default = FALSE)

  expect_equal(pass_reveal(pass_show("shared", store = ctx$store, key = key1)$password), "sharedsecret")
  expect_equal(pass_reveal(pass_show("shared", store = ctx$store, key = key2)$password), "sharedsecret")
})
