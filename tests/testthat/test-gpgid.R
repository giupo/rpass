test_that("resolve_recipients finds .gpg-id at entry directory", {
  ctx <- local_test_store()
  fs::dir_create(fs::path(ctx$store, "Lavoro"))
  writeLines("AAAA1111BBBB2222CCCC3333DDDD4444EEEE5555", fs::path(ctx$store, "Lavoro", ".gpg-id"))

  expect_equal(
    resolve_recipients("Lavoro/SECRET", ctx$store),
    "AAAA1111BBBB2222CCCC3333DDDD4444EEEE5555"
  )
})

test_that("resolve_recipients walks up to an ancestor .gpg-id", {
  ctx <- local_test_store()
  fs::dir_create(fs::path(ctx$store, "a", "b", "c"))
  writeLines("ROOTID", fs::path(ctx$store, ".gpg-id"))

  expect_equal(resolve_recipients("a/b/c/entry", ctx$store), "ROOTID")
})

test_that("resolve_recipients prefers the closest ancestor", {
  ctx <- local_test_store()
  fs::dir_create(fs::path(ctx$store, "a", "b"))
  writeLines("ROOTID", fs::path(ctx$store, ".gpg-id"))
  writeLines("NESTEDID", fs::path(ctx$store, "a", ".gpg-id"))

  expect_equal(resolve_recipients("a/b/entry", ctx$store), "NESTEDID")
})

test_that("resolve_recipients strips comments and blank lines", {
  ctx <- local_test_store()
  writeLines(c("# comment", "", "REALID  ", "# trailing"), fs::path(ctx$store, ".gpg-id"))

  expect_equal(resolve_recipients("entry", ctx$store), "REALID")
})

test_that("resolve_recipients errors when no .gpg-id exists", {
  ctx <- local_test_store()
  expect_error(resolve_recipients("entry", ctx$store), "No \\.gpg-id found")
})
