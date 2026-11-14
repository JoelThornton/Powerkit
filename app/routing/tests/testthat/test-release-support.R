test_that("the release discovery inventory matches the current expanded forms", {
  generator <- new.env(parent = globalenv())
  sys.source(file.path(repo_dir, "scripts", "release-support.R"), envir = generator)
  expected <- generator$release_support_text(repo_dir)
  actual <- paste0(paste(readLines(file.path(repo_dir, "docs", "release-support-inventory.json"),
    encoding = "UTF-8", warn = FALSE), collapse = "\n"), "\n")
  inventory <- jsonlite::fromJSON(actual, simplifyVector = FALSE)
  regenerated <- jsonlite::fromJSON(expected, simplifyVector = FALSE)
  expect_identical(inventory$format_version, regenerated$format_version)
  expect_identical(inventory$sources_md5, regenerated$sources_md5)
  source_paths <- names(regenerated$sources_md5)
  expect_lt(match("app/routing/R/forms.R", source_paths), match("app/routing/R/forms_ui.R", source_paths))
  expect_identical(inventory$limits, regenerated$limits)
  expect_identical(inventory$evidence_registry, regenerated$evidence_registry)
  for (i in seq_along(regenerated$cards)) {
    expect_identical(inventory$cards[[i]], regenerated$cards[[i]],
      info = paste("Regenerate release inventory; card", regenerated$cards[[i]]$id))
  }
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
