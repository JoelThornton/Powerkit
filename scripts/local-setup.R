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

# CRAN keeps a ready-made (binary) download of only the newest version of
# each package for Windows and macOS. Once CRAN publishes a newer version
# than renv.lock records, the recorded version exists there only as source
# code, which needs compilers (Rtools, Xcode and gfortran) that most people
# have not installed. Posit Public Package Manager keeps dated snapshots of
# CRAN with Windows and macOS binaries, so for each such package this finds
# a snapshot date on which its recorded version was CRAN's current one, and
# adds that snapshot as an extra repository. renv still installs exactly the
# recorded versions, and prefers CRAN where CRAN has them.
powerkit_snapshot_url <- "https://packagemanager.posit.co/cran/"

powerkit_read_lines <- function(url) {
  tryCatch(suppressWarnings(readLines(url, warn = FALSE)), error = function(e) character())
}

# Release dates of every version of a package on CRAN: archived versions
# from the archive listing, the current one from its CRAN page.
powerkit_cran_release_dates <- function(package, cran = "https://cloud.r-project.org",
  read = powerkit_read_lines) {
  archive <- paste(read(paste0(cran, "/src/contrib/Archive/", package, "/")), collapse = "\n")
  pattern <- paste0("href=\"", gsub(".", "\\.", package, fixed = TRUE),
    "_([^\"]+)\\.tar\\.gz\".*?([0-9]{4}-[0-9]{2}-[0-9]{2})")
  hits <- regmatches(archive, gregexpr(pattern, archive, perl = TRUE))[[1]]
  versions <- sub(pattern, "\\1", hits, perl = TRUE)
  dates <- sub(pattern, "\\2", hits, perl = TRUE)
  page <- paste(read(paste0(cran, "/web/packages/", package, "/index.html")), collapse = "\n")
  current <- regmatches(page, regexec("Version:</td>\\s*<td>([^<]+)</td>", page))[[1]]
  published <- regmatches(page, regexec("Published:</td>\\s*<td>([0-9]{4}-[0-9]{2}-[0-9]{2})", page))[[1]]
  if (length(current) == 2L && length(published) == 2L) {
    versions <- c(versions, current[[2]])
    dates <- c(dates, published[[2]])
  }
  keep <- !duplicated(versions) & !is.na(suppressWarnings(as.Date(dates)))
  data.frame(version = versions[keep], date = as.Date(dates[keep]), stringsAsFactors = FALSE)
}

# The days on which `version` was CRAN's current version, less the first
# two (the snapshot needs time to build binaries) and on weekdays only
# (snapshots are taken on working days). NULL when there are none.
powerkit_current_window <- function(version, releases) {
  if (!nrow(releases) || !version %in% releases$version) return(NULL)
  newer <- releases$date[package_version(releases$version) > package_version(version)]
  if (!length(newer)) return(NULL)
  start <- releases$date[releases$version == version][[1]] + 2L
  end <- min(newer) - 1L
  if (end < start) return(NULL)
  days <- seq(start, end, by = 1L)
  days <- days[!format(days, "%u") %in% c("6", "7")]
  if (length(days)) days else NULL
}

# As few snapshot dates as cover every window: pick the last day of the
# window that ends first, drop the windows it falls in, and repeat.
powerkit_cover_windows <- function(windows) {
  windows <- Filter(length, windows)
  picked <- as.Date(character())
  while (length(windows)) {
    ends <- vapply(windows, function(w) as.numeric(max(w)), numeric(1))
    day <- max(windows[[which.min(ends)]])
    picked <- c(picked, day)
    windows <- Filter(function(w) !day %in% w, windows)
  }
  sort(picked)
}

powerkit_binary_snapshots <- function(root, sysname = Sys.info()[["sysname"]],
  records = NULL, binaries = NULL, bundled = NULL,
  releases = powerkit_cran_release_dates, cran = "https://cloud.r-project.org") {
  if (!sysname %in% c("Darwin", "Windows")) return(character())
  tryCatch({
    if (is.null(records)) records <- renv::lockfile_read(file.path(root, "renv.lock"))$Packages
    if (is.null(binaries)) {
      listing <- suppressWarnings(utils::available.packages(
        contriburl = utils::contrib.url(cran, "binary"), filters = list()))
      binaries <- stats::setNames(listing[, "Version"], listing[, "Package"])
    }
    if (is.null(bundled)) {
      base <- utils::installed.packages(.Library)
      bundled <- stats::setNames(base[, "Version"], base[, "Package"])
    }
    windows <- list()
    for (record in records) {
      package <- record$Package
      # renv itself is installed by renv/activate.R, not by restore().
      if (!identical(record$Source, "Repository") || identical(package, "renv")) next
      if (identical(unname(binaries[package]), record$Version)) next
      if (identical(unname(bundled[package]), record$Version)) next
      windows[[package]] <- powerkit_current_window(record$Version, releases(package, cran = cran))
    }
    days <- format(powerkit_cover_windows(windows))
    stats::setNames(paste0(powerkit_snapshot_url, days), paste0("P3M-", days))
  }, error = function(e) character())
}

powerkit_restore <- function(root, restore = renv::restore,
  snapshots = powerkit_binary_snapshots(root), ...) {
  # The public CRAN mirror avoids the observed intermittent TLS resets on
  # Posit's Windows binary redirects. Versions still come from renv.lock.
  message("powerkit: downloading recorded package versions from cloud.r-project.org; the lockfile is unchanged.")
  if (length(snapshots)) {
    message("powerkit: some recorded versions have no ready-made download on CRAN now; ",
      "fetching those from Posit Package Manager's CRAN snapshot(s) of ",
      paste(sub("^P3M-", "", names(snapshots)), collapse = ", "), ", so nothing needs compiling.")
  }
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
  }, "Installing packages", initial_repos = c(CRAN = "https://cloud.r-project.org", snapshots), ...)
}
