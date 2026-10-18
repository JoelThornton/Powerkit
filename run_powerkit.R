# Start the powerkit prototype, installing what it needs the first time.
#
# One line, in R or RStudio (step-by-step guide: docs/run-it-yourself.md):
#
#   source(file.choose())     # then pick this file, run_powerkit.R
#
# or, if R is already in the powerkit folder (for example after opening
# Powerkit.Rproj in RStudio):
#
#   source("run_powerkit.R")
#
# The first run installs the package versions powerkit records (renv.lock)
# into a library inside this folder, so your other R projects are not
# touched. It can take 10 to 30 minutes. Later runs start in seconds.
#
# For automated checks only: POWERKIT_PORT sets the port, and
# POWERKIT_NO_BROWSER=true stops it opening a browser.

local({
  say <- function(...) message("powerkit: ", ...)
  stop_plain <- function(...) stop(paste0("powerkit: ", ...), call. = FALSE)

  # 1. Find the powerkit folder: the folder this file is in.
  find_self <- function() {
    for (i in rev(seq_len(sys.nframe()))) {
      f <- sys.frame(i)$ofile
      if (!is.null(f)) return(dirname(normalizePath(f)))
    }
    getwd()
  }
  root <- find_self()
  if (!dir.exists(file.path(root, "app", "routing")) || !file.exists(file.path(root, "renv.lock"))) {
    stop_plain(
      "this doesn't look like the powerkit folder (", root, "). ",
      "Unzip the download first, then choose run_powerkit.R inside the unzipped folder."
    )
  }
  setwd(root)
  say("using the folder ", root)

  # 2. Check R's version against the one powerkit records.
  head_lines <- readLines("renv.lock", n = 10, warn = FALSE)
  locked <- regmatches(head_lines, regexpr("\"Version\": \"[0-9.]+\"", head_lines))
  locked <- if (length(locked)) gsub("[^0-9.]", "", locked[[1]]) else character()
  if (getRversion() < "4.4.0") {
    stop_plain(
      "powerkit needs R 4.4 or later (you have ", getRversion(), "). ",
      "Install R ", if (length(locked)) locked else "4.5", " as described in docs/run-it-yourself.md, then try again."
    )
  }
  if (length(locked) && !identical(substr(format(getRversion()), 1, 3), substr(locked, 1, 3))) {
    say(
      "powerkit records R ", locked, " and you have R ", getRversion(), ". ",
      "It will try anyway; if installing packages fails, install R ", locked,
      " (docs/run-it-yourself.md, 'Troubleshooting')."
    )
  }

  # 3. Use powerkit's own package library (renv), and install the recorded
  # package versions if any are missing. restore() does nothing when the
  # library already matches renv.lock.
  if (!identical(Sys.getenv("RENV_PROJECT"), normalizePath(root, winslash = "/", mustWork = FALSE))) {
    source(file.path(root, "renv", "activate.R"))
  }
  if (!requireNamespace("renv", quietly = TRUE)) {
    stop_plain("couldn't set up renv, which installs powerkit's packages. Check your internet connection and try again.")
  }
  say("checking powerkit's packages (the first time, this installs them and takes a while)")
  ok <- tryCatch({
    renv::restore(project = root, prompt = FALSE)
    TRUE
  }, error = function(e) {
    message(conditionMessage(e))
    FALSE
  })
  if (!ok) {
    stop_plain(
      "installing packages failed (the message above says which). ",
      "See docs/run-it-yourself.md, 'Troubleshooting'. Running this file again carries on where it stopped."
    )
  }

  # 4. Install powerkit's engine (the folder engine/) into the same library,
  # again only when it has changed since the last install.
  engine_files <- c("engine/DESCRIPTION", "engine/NAMESPACE",
                    list.files("engine/R", full.names = TRUE),
                    list.files("engine/inst", recursive = TRUE, full.names = TRUE))
  stamp <- paste(tools::md5sum(sort(engine_files)), collapse = "")
  stamp_file <- file.path(.libPaths()[1], "powerkit", "POWERKIT_ENGINE_STAMP")
  installed <- requireNamespace("powerkit", quietly = TRUE) && file.exists(stamp_file) &&
    identical(readLines(stamp_file, warn = FALSE), stamp)
  if (!installed) {
    say("installing powerkit's engine")
    utils::install.packages("engine", repos = NULL, type = "source", lib = .libPaths()[1], quiet = TRUE)
    if (!requireNamespace("powerkit", quietly = TRUE)) {
      stop_plain("couldn't install powerkit's engine. See docs/run-it-yourself.md, 'Troubleshooting'.")
    }
    writeLines(stamp, stamp_file)
  }

  # 5. Start the app.
  port <- suppressWarnings(as.integer(Sys.getenv("POWERKIT_PORT")))
  browser <- !identical(tolower(Sys.getenv("POWERKIT_NO_BROWSER")), "true")
  say("starting. To stop it, press Esc in the R console (or the red Stop button in RStudio).")
  shiny::runApp(
    file.path(root, "app", "routing"),
    port = if (is.na(port)) getOption("shiny.port") else port,
    launch.browser = browser
  )
})
