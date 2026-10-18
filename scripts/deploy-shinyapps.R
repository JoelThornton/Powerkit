# Put the powerkit app online at shinyapps.io, so testers can open a link.
#
# Run this in R or RStudio on your own computer, from the powerkit folder
# (open Powerkit.Rproj, or setwd() to the folder). It takes a few minutes
# the first time. Each later run updates the same web address.
#
# Before the first run, once:
#   1. Make a free account at https://www.shinyapps.io (sign in with GitHub
#      or an email address).
#   2. In shinyapps.io, find the Tokens page (under your account), show
#      the token and its secret, and copy the line of R it gives, which
#      starts rsconnect::setAccountInfo(name = ..., token = ..., secret = ...).
#      Paste it into the R console and run it. It stays on your computer;
#      don't share it or commit it.
#
# Then run this file: source("scripts/deploy-shinyapps.R")

local({
  say <- function(...) message("powerkit: ", ...)
  if (!dir.exists(file.path("app", "routing"))) {
    stop("powerkit: run this from the powerkit folder (it should contain app/routing).", call. = FALSE)
  }
  for (pkg in c("rsconnect", "remotes")) {
    if (!requireNamespace(pkg, quietly = TRUE)) install.packages(pkg)
  }
  if (nrow(rsconnect::accounts()) == 0) {
    stop("powerkit: no shinyapps.io account is set up in R yet. Do steps 1 and 2 at the top of this file first.", call. = FALSE)
  }

  # The server installs every package the app uses, at the versions on this
  # computer. powerkit's engine must come from GitHub (not from this folder),
  # or the server can't install it.
  say("installing powerkit's engine from GitHub (the version on main)")
  remotes::install_github("JoelThornton/Powerkit", subdir = "engine", upgrade = "never")

  say("uploading the app; shinyapps.io then installs the packages, which takes a few minutes")
  rsconnect::deployApp(
    appDir = file.path("app", "routing"),
    appName = "powerkit",
    appTitle = "powerkit (prototype, not for real studies)",
    forceUpdate = TRUE
  )
})
