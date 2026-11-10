test_that("release discovery uses numbered versions, includes labelled prototypes and ignores drafts", {
  env <- new.env()
  sys.source(file.path(repo_dir, "scripts", "local-updates.R"), env)
  releases <- list(list(tag_name = "v0.9.0", prerelease = TRUE),
    list(tag_name = "v0.10.0", prerelease = TRUE),
    list(tag_name = "v9.0.0", draft = TRUE), list(tag_name = "main"))
  result <- env$powerkit_release_update(releases, "0.9.0")
  expect_true(result$newer)
  expect_identical(result$latest, "0.10.0")
  expect_true(result$prerelease)
  expect_identical(result$url, "https://github.com/JoelThornton/Powerkit/releases/tag/v0.10.0")
  expect_false(env$powerkit_release_update(releases, "0.11.0")$newer)
})

test_that("a failed update check leaves the installed files alone", {
  env <- new.env()
  sys.source(file.path(repo_dir, "scripts", "local-updates.R"), env)
  root <- withr::local_tempdir()
  dir.create(file.path(root, "engine"))
  path <- file.path(root, "engine", "DESCRIPTION")
  writeLines(c("Package: powerkit", "Version: 0.9.0"), path)
  before <- tools::md5sum(path)
  expect_message(result <- env$powerkit_check_updates(root, fetch = function() stop("offline")),
    "still works offline")
  expect_null(result)
  expect_identical(tools::md5sum(path), before)
})

test_that("changed local engine files require restart if the engine is loaded", {
  env <- new.env()
  sys.source(file.path(repo_dir, "scripts", "local-engine.R"), env)
  path <- withr::local_tempfile()
  writeLines("old", path)
  expect_identical(env$powerkit_local_engine_action(path, "new", "installed", TRUE), "restart")
  expect_identical(env$powerkit_local_engine_action(path, "new", "installed", FALSE), "install")
  expect_identical(env$powerkit_local_engine_action(path, "old", "installed", TRUE, dirname(path)), "reuse")
  expect_identical(env$powerkit_local_engine_action(path, "old", "installed", TRUE, "other-version/powerkit"), "restart")
  expect_identical(env$powerkit_local_engine_action(path, "old", character(), FALSE), "install")
})

test_that("researchers can discover local computing and default-method caveats", {
  html <- as.character(start_ui(tree))
  expect_match(html, "download.html", fixed = TRUE)
  withr::local_options(powerkit.local = TRUE)
  expect_match(as.character(start_ui(tree)), "Running on your computer", fixed = TRUE)
  expect_match(tree$endpoints$E2$doc_name, "Welch's by default", fixed = TRUE)
  expect_match(tree$endpoints$E2$backend, "^pwrss:")
  expect_match(tree$bayes_test_text, "approximation", fixed = TRUE)
  expect_match(tree$endpoints$E55$validation$note, "still fails", fixed = TRUE)
})
