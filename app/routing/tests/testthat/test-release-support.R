test_that("the release discovery inventory describes the current expanded forms", {
  generator <- new.env(parent = globalenv())
  sys.source(file.path(repo_dir, "scripts", "release-support.R"), envir = generator)
  expected <- generator$release_support_text(repo_dir)
  # The committed file is regenerated on main after each merge
  # (scripts/after-merge.R), so a pull request is checked against the
  # inventory its own code produces.
  inventory <- jsonlite::fromJSON(expected, simplifyVector = FALSE)
  source_paths <- names(inventory$sources_md5)
  expect_lt(match("app/routing/R/forms.R", source_paths), match("app/routing/R/forms_ui.R", source_paths))
  committed <- jsonlite::fromJSON(file.path(repo_dir, "docs", "release-support-inventory.json"), simplifyVector = FALSE)
  expect_identical(committed$format_version, inventory$format_version)
  cards <- stats::setNames(inventory$cards, vapply(inventory$cards, `[[`, "", "id"))
  expect_setequal(names(cards), names(tree$endpoints))
  runnable <- names(Filter(function(x) !identical(x$access, "guidance"), cards))
  expect_setequal(runnable, tree$calculates)
  expect_identical(cards$E75$access, "full")
  method <- Filter(function(f) identical(f$id, "method"), cards$E2$selectors)[[1]]
  expect_true(all(c("welch_t", "student_t", "mann_whitney") %in% unlist(method$choices)))
  expect_identical(cards$E58$base_template, "lpa")
  expect_identical(cards$E73$base_template, "efa")
  expect_identical(cards$E74$base_template, "riclpm")
  expect_identical(inventory$evidence_registry, "engine/inst/evidence/records.json")
})
