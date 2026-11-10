local_setup_helpers <- function() {
  env <- new.env()
  sys.source(file.path(repo_dir, "scripts", "local-setup.R"), env)
  sys.source(file.path(repo_dir, "scripts", "local-engine.R"), env)
  env
}

test_that("connection resets recover with another downloader and mirror, preserving versions", {
  env <- local_setup_helpers()
  calls <- list()
  restore <- function(project, prompt, repos = NULL, retry = NULL) {
    calls[[length(calls) + 1L]] <<- list(project = project, prompt = prompt,
      repos = repos, retry = retry, method = Sys.getenv("RENV_DOWNLOAD_METHOD"),
      ppm = getOption("renv.config.ppm.enabled"))
    if (length(calls) < 3) stop("error downloading GPArotation [curl: (35) Recv failure: Connection was reset]")
    "restored"
  }
  withr::local_envvar(RENV_DOWNLOAD_METHOD = NA_character_)
  settings <- c("timeout", "download.file.method", "renv.config.repos.override",
    "renv.config.ppm.enabled", "renv.config.connect.timeout", "renv.config.connect.retry")
  original <- stats::setNames(lapply(settings, getOption), settings)
  expect_message(value <- env$powerkit_restore("download", restore = restore,
    pause = function(x) NULL, libcurl = TRUE), "recorded package server")
  expect_identical(value, "restored")
  expect_length(calls, 3)
  expect_identical(calls[[1]]$repos, c(CRAN = "https://cloud.r-project.org"))
  expect_identical(calls[[2]]$method, "libcurl")
  expect_identical(calls[[3]]$repos, NULL)
  expect_false(calls[[1]]$ppm)
  expect_true(all(vapply(calls, function(x) identical(x$retry, FALSE), logical(1))))
  expect_identical(stats::setNames(lapply(settings, getOption), settings), original)
  expect_identical(Sys.getenv("RENV_DOWNLOAD_METHOD", unset = NA_character_), NA_character_)
})

test_that("compiler errors do not trigger network retries or install newer packages", {
  env <- local_setup_helpers()
  n <- 0L
  restore <- function(project, prompt, repos = NULL) { n <<- n + 1L; stop("compilation failed: missing Rtools") }
  expect_error(env$powerkit_restore("download", restore, pause = function(x) NULL), "missing Rtools")
  expect_identical(n, 1L)
})

test_that("individual TLS resets retry before a binary is abandoned", {
  env <- local_setup_helpers()
  path <- withr::local_tempfile()
  calls <- 0L
  download <- function(url, destfile, quiet, headers) {
    calls <<- calls + 1L
    if (calls < 3L) stop("error downloading [curl: (35) Recv failure: Connection was reset]")
    writeLines("complete", destfile)
    destfile
  }
  sentinel <- function(...) stop("unrelated override")
  withr::local_options(renv.download.override = sentinel)
  wrapped <- env$powerkit_download_override(download = download, pause = function(x) NULL)
  expect_message(value <- wrapped("https://example.org/pkg.zip", path), "retrying")
  expect_identical(value, path)
  expect_identical(readLines(path), "complete")
  expect_identical(calls, 3L)
  expect_identical(getOption("renv.download.override"), sentinel)
})

test_that("failed attempts restore custom network settings and stop after bounded retries", {
  env <- local_setup_helpers()
  withr::local_envvar(c(RENV_DOWNLOAD_METHOD = "curl", RENV_CONFIG_REPOS_OVERRIDE = "https://example.org/repo"))
  withr::local_options(timeout = 900, renv.config.repos.override = c(CRAN = "https://example.org/repo"))
  count <- 0L
  action <- function(repos) { count <<- count + 1L; stop("error downloading: Connection was reset") }
  expect_error(suppressMessages(env$powerkit_network_retry(action, "Setup",
    pause = function(x) NULL, libcurl = TRUE)), "Connection was reset")
  expect_identical(count, 3L)
  expect_identical(Sys.getenv("RENV_DOWNLOAD_METHOD"), "curl")
  expect_identical(Sys.getenv("RENV_CONFIG_REPOS_OVERRIDE"), "https://example.org/repo")
  expect_identical(getOption("timeout"), 900)
  expect_identical(getOption("renv.config.repos.override"), c(CRAN = "https://example.org/repo"))
})

test_that("a failed engine install cannot stamp an old engine as current", {
  env <- local_setup_helpers()
  root <- withr::local_tempdir()
  engine <- file.path(root, "engine")
  lib <- file.path(root, "library")
  installed <- file.path(lib, "powerkit")
  dir.create(engine); dir.create(installed, recursive = TRUE)
  writeLines(c("Package: powerkit", "Version: 0.60.0"), file.path(engine, "DESCRIPTION"))
  writeLines(c("Package: powerkit", "Version: 0.59.0"), file.path(installed, "DESCRIPTION"))
  stamp <- file.path(installed, "POWERKIT_ENGINE_STAMP")
  writeLines("old", stamp)
  expect_error(env$powerkit_install_local_engine(engine, lib, "new", install = function(...) 1L), "stamp was not updated")
  expect_identical(readLines(stamp), "old")
  expect_error(env$powerkit_install_local_engine(engine, lib, "new", install = function(...) 0L), "does not match")
  expect_identical(readLines(stamp), "old")
  file.copy(file.path(engine, "DESCRIPTION"), file.path(installed, "DESCRIPTION"), overwrite = TRUE)
  env$powerkit_install_local_engine(engine, lib, "new", install = function(...) 0L)
  expect_identical(readLines(stamp), "new")
})
