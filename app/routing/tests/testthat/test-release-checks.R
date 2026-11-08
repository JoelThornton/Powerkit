# The checks run before a release (docs/repository-protection.md, "Checks
# before a release") aren't in CI; these keep them in step with the engine
# and the forms, on one quick design.

test_that("the property checks run on a formula design and find nothing wrong", {
  out <- withr::local_tempdir()
  withr::with_dir(repo_dir, {
    status <- callr::rscript("scripts/release-checks/property-checks.R",
      cmdargs = c("--only", "correlation", "--out", out, "--workers", "1"),
      show = FALSE, fail_on_status = FALSE, stderr = "2>&1")
  })
  expect_identical(status$status, 0L, info = status$stdout)
  expect_match(status$stdout, "1 design checked, 0 with a problem", fixed = TRUE)
  j <- jsonlite::fromJSON(file.path(out, "correlation.json"), simplifyVector = FALSE)
  expect_null(j$flags)
  # The no-effect run gives alpha, by formula.
  expect_equal(j$null$power, 0.05, tolerance = 0.01)
})

test_that("the every-card browser run gets example values for every input screen", {
  out <- withr::local_tempfile(fileext = ".json")
  withr::with_dir(repo_dir, {
    status <- callr::rscript("app/routing/walkthroughs/every-card-list.R", cmdargs = out,
      show = FALSE, fail_on_status = FALSE, stderr = "2>&1")
  })
  expect_identical(status$status, 0L, info = status$stdout)
  cards <- jsonlite::fromJSON(out, simplifyVector = FALSE)
  tree <- yaml::read_yaml(file.path(routing_dir, "tree.yaml"))
  expect_setequal(vapply(cards, `[[`, "", "id"), names(tree$endpoints))
  with_form <- Filter(function(x) isTRUE(x$has_form), cards)
  missing <- vapply(Filter(function(x) is.null(x$example), with_form), `[[`, "", "id")
  expect_identical(missing, character(), info = "add example values to tests/testthat/helper-forms.R")
})
