# Put the powerkit app online at Posit Connect Cloud, so testers can open
# a link. (shinyapps.io is closing to new apps at the end of 2026 and its
# users move to Connect Cloud, so powerkit starts there.)
#
# Usually not needed: once Connect Cloud publishes from GitHub
# (docs/hosting-options.md, "Publishing from GitHub"), every merge to main
# updates the online app by itself. This script is the fallback.
#
# Run this in R or RStudio on your own computer, from the powerkit folder
# (open Powerkit.Rproj, or setwd() to the folder). It takes a few minutes
# the first time. Each later run updates the same web address.
#
# Before the first run, once:
#   1. Make a free account at https://connect.posit.cloud (sign in with
#      GitHub or Google).
#   2. In the R console, run:  install.packages("rsconnect")
#      then:                    rsconnect::connectCloudUser()
#      A browser window opens; sign in and allow access. This stays on
#      your computer.
#
# Then run this file: source("scripts/deploy-online.R")

local({
  say <- function(...) message("powerkit: ", ...)
  if (!dir.exists(file.path("app", "routing"))) {
    stop("powerkit: run this from the powerkit folder (it should contain app/routing).", call. = FALSE)
  }
  for (pkg in c("rsconnect", "remotes")) {
    if (!requireNamespace(pkg, quietly = TRUE)) install.packages(pkg)
  }
  if (utils::packageVersion("rsconnect") < "1.6.0") {
    stop("powerkit: rsconnect is too old for Connect Cloud. Run install.packages(\"rsconnect\") and try again.", call. = FALSE)
  }
  server <- "connect.posit.cloud"
  if (!server %in% rsconnect::accounts()$server) {
    stop("powerkit: no Connect Cloud account is set up in R yet. Do steps 1 and 2 at the top of this file first.", call. = FALSE)
  }

  # The server installs every package the app uses, at the versions on this
  # computer. powerkit's engine must come from GitHub (not from this folder),
  # or the server can't install it.
  say("installing powerkit's engine from GitHub (the version on main)")
  remotes::install_github("JoelThornton/Powerkit", subdir = "engine", upgrade = "never")

  say("uploading the app; Connect Cloud then installs the packages, which takes a few minutes")
  rsconnect::deployApp(
    appDir = file.path("app", "routing"),
    appName = "powerkit",
    appTitle = "powerkit (prototype, not for real studies)",
    server = server,
    forceUpdate = TRUE
  )
})
