test_that("Labs history distinguishes its menu and individual tools", {
  key <- function(tool) nav_key("start", NULL, NULL, 0, labs_tab_title, tool)
  expect_false(identical(key(""), key("picture")))
  expect_false(identical(key("picture"), key("bayes")))
  expect_identical(key("picture"), key("picture"))
  expect_identical(nav_key("start", NULL, NULL, 0, "About", "picture"),
    nav_key("start", NULL, NULL, 0, "About", "bayes"))
})
