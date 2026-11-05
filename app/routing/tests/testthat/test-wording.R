# powerkit is not only for psychology (docs/decisions.md, 5 November 2026):
# the words a visitor or a search engine sees first, and the package's own
# descriptions, must not present it as a psychology tool. Citations of
# journals with "Psychology" in their names are fine, so the check is on
# the descriptions themselves.

test_that("the page title, description, footer and guide don't call powerkit a psychology tool", {
  app <- paste(readLines(file.path(routing_dir, "app.R"), encoding = "UTF-8"), collapse = "\n")
  head_and_footer <- regmatches(app, gregexpr("tags\\$(title|meta|footer)\\([^\n]*", app))[[1]]
  expect_gt(length(head_and_footer), 0)
  expect_false(any(grepl("psycholog", head_and_footer, ignore.case = TRUE)))
  guide <- paste(readLines(file.path(routing_dir, "www", "guide.html"), encoding = "UTF-8"), collapse = "\n")
  expect_no_match(guide, "psycholog", ignore.case = TRUE)
})

test_that("the package's title, description and citation don't call it a psychology tool", {
  description <- read.dcf(file.path(repo_dir, "engine", "DESCRIPTION"), fields = c("Title", "Description"))
  expect_false(any(grepl("psycholog", description, ignore.case = TRUE)))
  cff <- readLines(file.path(repo_dir, "CITATION.cff"), encoding = "UTF-8")
  expect_false(any(grepl("psycholog", cff, ignore.case = TRUE)))
  readme_intro <- readLines(file.path(repo_dir, "README.md"), n = 12, encoding = "UTF-8")
  expect_false(any(grepl("psycholog", readme_intro, ignore.case = TRUE)))
})
