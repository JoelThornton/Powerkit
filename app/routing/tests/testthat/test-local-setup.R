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

test_that("recorded versions CRAN no longer builds come from a dated snapshot with binaries", {
  env <- local_setup_helpers()
  pages <- list(
    "https://cran.test/src/contrib/Archive/Hmisc/" = c(
      '<a href="Hmisc_5.2-6.tar.gz">Hmisc_5.2-6.tar.gz</a>   2026-06-19 10:00  900K',
      '<a href="Hmisc_5.3-0.tar.gz">Hmisc_5.3-0.tar.gz</a>   2026-09-06 12:40  918K'),
    "https://cran.test/web/packages/Hmisc/index.html" = c(
      "<tr><td>Version:</td>", "<td>5.3-1</td></tr>", "<tr><td>Published:</td>", "<td>2026-11-15</td></tr>"),
    "https://cran.test/src/contrib/Archive/xfun/" = c(
      '<a href="xfun_0.9.tar.gz">xfun_0.9.tar.gz</a> 2019-08-21 10:00 1K',
      '<a href="xfun_0.61.tar.gz">xfun_0.61.tar.gz</a> 2026-09-16 10:00 1K'),
    "https://cran.test/web/packages/xfun/index.html" = c(
      "<td>Version:</td>", "<td>0.62</td>", "<td>Published:</td>", "<td>2026-10-16</td>"))
  read <- function(url) pages[[url]] %||% character()
  releases <- function(package, cran) env$powerkit_cran_release_dates(package, cran, read = read)
  records <- list(
    Hmisc = list(Package = "Hmisc", Version = "5.3-0", Source = "Repository", Repository = "RSPM"),
    xfun = list(Package = "xfun", Version = "0.61", Source = "Repository", Repository = "CRAN"),
    shiny = list(Package = "shiny", Version = "1.11.0", Source = "Repository", Repository = "CRAN"),
    MASS = list(Package = "MASS", Version = "7.3-65", Source = "Repository", Repository = "CRAN"),
    renv = list(Package = "renv", Version = "1.0.3", Source = "Repository", Repository = "CRAN"))
  binaries <- c(Hmisc = "5.3-1", xfun = "0.62", shiny = "1.11.0", MASS = "7.3-66", renv = "1.3.1")
  snapshots <- function(sysname) env$powerkit_binary_snapshots("x", sysname = sysname,
    records = records, binaries = binaries, bundled = c(MASS = "7.3-65"),
    releases = releases, cran = "https://cran.test")
  # xfun 0.61 was current until 15 October and Hmisc 5.3-0 until
  # 14 November: one snapshot, on the last weekday both were current, covers both.
  expect_identical(snapshots("Darwin"),
    c("P3M-2026-10-15" = "https://packagemanager.posit.co/cran/2026-10-15"))
  expect_identical(snapshots("Windows"), snapshots("Darwin"))
  expect_identical(snapshots("Linux"), character())
  # A version current for less than the two days binaries take has no window.
  expect_null(env$powerkit_current_window("1.0", data.frame(version = c("1.0", "1.1"),
    date = as.Date(c("2026-11-02", "2026-11-03")))))
  # The snapshots join CRAN as extra repositories; versions still come from the lockfile.
  seen <- NULL
  restore <- function(project, prompt, repos = NULL, retry = NULL) { seen <<- repos; "ok" }
  expect_message(env$powerkit_restore("x", restore, snapshots = snapshots("Darwin")), "2026-10-15")
  expect_identical(seen, c(CRAN = "https://cloud.r-project.org",
    "P3M-2026-10-15" = "https://packagemanager.posit.co/cran/2026-10-15"))
  # When CRAN can't be reached, no snapshots are added and nothing fails.
  expect_identical(env$powerkit_binary_snapshots("x", sysname = "Darwin", records = records,
    binaries = binaries, bundled = character(), releases = function(...) stop("offline")), character())
})
