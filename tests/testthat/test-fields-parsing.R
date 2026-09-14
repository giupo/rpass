test_that("parse_entry_body splits password from notes", {
  parsed <- parse_entry_body("hunter2\nlogin: foo\nurl: bar")
  expect_equal(parsed$password, "hunter2")
  expect_equal(parsed$notes, c("login: foo", "url: bar"))
  expect_equal(parsed$fields, list(login = "foo", url = "bar"))
})

test_that("parse_entry_body handles a password-only entry", {
  parsed <- parse_entry_body("justapassword")
  expect_equal(parsed$password, "justapassword")
  expect_equal(parsed$notes, character())
  expect_equal(parsed$fields, list())
})

test_that("parse_entry_body keeps non key:value lines out of fields but in notes", {
  parsed <- parse_entry_body("pw\nsome freeform note without a colon\nlogin: x")
  expect_equal(parsed$notes, c("some freeform note without a colon", "login: x"))
  expect_equal(parsed$fields, list(login = "x"))
})

test_that("build_entry_body is the inverse of parse_entry_body for notes", {
  body <- build_entry_body("pw", notes = c("free text", "login: x"))
  expect_equal(body, "pw\nfree text\nlogin: x")
})

test_that("build_entry_body renders fields as key: value lines", {
  body <- build_entry_body("pw", fields = list(login = "foo", url = "bar"))
  expect_equal(body, "pw\nlogin: foo\nurl: bar")
})

test_that("build_entry_body rejects unnamed fields", {
  expect_error(build_entry_body("pw", fields = list("x")), "fully named")
})
