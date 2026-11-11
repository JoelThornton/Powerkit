# Local setup only. Never change the lockfile or weaken HTTPS checks.
powerkit_network_error <- function(error) {
  grepl(paste(c("error downloading", "failed to download", "download.*fail",
    "cannot open URL", "connection.*(reset|closed|refused)", "recv failure",
    "timed? ?out", "timeout", "could not resolve", "couldn't resolve",
    "curl: \\((5|6|7|18|28|35|52|55|56)\\)"), collapse = "|"),
    conditionMessage(error), ignore.case = TRUE)
}

powerkit_network_scope <- function(action, method = NULL, repos = NULL) {
  settings <- c("timeout", "download.file.method", "renv.config.connect.timeout",
    "renv.config.connect.retry", "renv.config.repos.override", "renv.config.ppm.enabled")
  old <- stats::setNames(lapply(settings, getOption), settings)
  vars <- c("RENV_DOWNLOAD_METHOD", "RENV_CONFIG_REPOS_OVERRIDE")
  previous <- Sys.getenv(vars, unset = NA_character_)
  on.exit({
    options(old)
    for (name in vars) {
      if (is.na(previous[[name]])) Sys.unsetenv(name)
      else do.call(Sys.setenv, stats::setNames(list(previous[[name]]), name))
    }
  }, add = TRUE)
  options(timeout = max(300, getOption("timeout", 60)),
    renv.config.connect.timeout = max(30, getOption("renv.config.connect.timeout", 20)),
    renv.config.connect.retry = 3L)
  if (!is.null(method)) {
    options(download.file.method = method)
    Sys.setenv(RENV_DOWNLOAD_METHOD = method)
  }
  if (!is.null(repos)) {
    options(renv.config.repos.override = repos, renv.config.ppm.enabled = FALSE)
    # The checked-in renv 1.0.3 bootstrap reads this environment variable.
    Sys.setenv(RENV_CONFIG_REPOS_OVERRIDE = unname(repos[[1]]))
  }
  action(repos)
}

powerkit_network_retry <- function(action, stage,
  say = function(...) message("powerkit: ", ...), pause = Sys.sleep,
  libcurl = isTRUE(capabilities("libcurl")), initial_repos = NULL) {
  attempts <- list(list(method = NULL, repos = initial_repos))
  if (libcurl) attempts <- c(attempts, list(list(method = "libcurl", repos = initial_repos)))
  attempts <- c(attempts, list(list(method = if (libcurl) "libcurl" else NULL,
    repos = if (is.null(initial_repos)) c(CRAN = "https://cloud.r-project.org") else NULL)))
  for (i in seq_along(attempts)) {
    attempt <- attempts[[i]]
    result <- tryCatch(list(value = powerkit_network_scope(action, attempt$method, attempt$repos)),
      error = function(e) list(error = e))
    if (is.null(result$error)) return(invisible(result$value))
    if (!powerkit_network_error(result$error) || i == length(attempts)) {
      stop(paste0("powerkit: ", stage, " failed.\n", conditionMessage(result$error),
        "\nDownloaded packages are kept for another attempt. Restart R and run run_powerkit.R again. ",
        "If it still fails, copy the final error and package name; see docs/run-it-yourself.md."), call. = FALSE)
    }
    next_attempt <- attempts[[i + 1L]]
    say(stage, ": a package download failed; retrying ",
      if (!is.null(next_attempt$repos)) "through the cloud.r-project.org CRAN mirror"
      else if (!is.null(initial_repos)) "through the recorded package server"
      else "with R's built-in libcurl downloader",
      ". Recorded package versions and HTTPS verification are unchanged.")
    pause(2)
  }
}

powerkit_activate <- function(root) {
  powerkit_network_retry(function(repos) {
    source(file.path(root, "renv", "activate.R"), local = FALSE)
  }, "Setting up the package installer")
}

# renv 1.0.3's download override calls its normal downloader
# with the override temporarily removed. That retains renv's archive
# checks and partial-file handling while retrying TLS resets per file,
# before renv falls back from an available binary to source compilation.
powerkit_download_override <- function(original = NULL, download = NULL, pause = Sys.sleep) {
  force(original)
  function(url, destfile, quiet = FALSE, mode = "wb", headers = NULL) {
    saved <- getOption("renv.download.override")
    options(renv.download.override = original)
    on.exit(options(renv.download.override = saved), add = TRUE)
    action <- function(repos) {
      if (is.function(original)) return(original(url = url, destfile = destfile,
        quiet = quiet, mode = mode, headers = headers))
      downloader <- if (is.null(download)) getFromNamespace("download", "renv") else download
      downloader(url = url, destfile = destfile, quiet = quiet, headers = headers)
    }
    for (i in seq_len(3L)) {
      result <- tryCatch(list(value = powerkit_network_scope(action,
        method = if (i > 1L && isTRUE(capabilities("libcurl"))) "libcurl" else NULL)),
        error = function(e) list(error = e))
      if (is.null(result$error)) return(result$value)
      if (!powerkit_network_error(result$error) || i == 3L) stop(result$error)
      message("powerkit: retrying an interrupted package download (", i + 1L, "/3).")
      pause(i)
    }
  }
}

powerkit_restore <- function(root, restore = renv::restore, ...) {
  # The public CRAN mirror avoids the observed intermittent TLS resets on
  # Posit's Windows binary redirects. Versions still come from renv.lock.
  message("powerkit: downloading recorded package versions from cloud.r-project.org; the lockfile is unchanged.")
  original <- getOption("renv.download.override")
  options(renv.download.override = powerkit_download_override(original))
  on.exit(options(renv.download.override = original), add = TRUE)
  powerkit_network_retry(function(repos) {
    # renv 1.0.3 restores exact lockfile versions. Do not use the newer
    # restore(retry = TRUE), which permits substituting newer versions.
    args <- list(project = root, prompt = FALSE)
    if ("retry" %in% names(formals(restore))) args$retry <- FALSE
    if (!is.null(repos)) args$repos <- repos
    do.call(restore, args)
  }, "Installing packages", initial_repos = c(CRAN = "https://cloud.r-project.org"), ...)
}
