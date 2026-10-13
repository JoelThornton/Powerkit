# Start the powerkit prototype app (2x2 between and 2x2 mixed designs).
#
# In RStudio: open Powerkit.Rproj, open this file and click "Source"
# (or run source("run_app.R") in the console). The first time, any missing
# packages are installed into the project library.

if (!dir.exists("app") || !dir.exists("engine")) {
  stop(
    "Run this from the Powerkit project folder: open Powerkit.Rproj in RStudio, then source(\"run_app.R\").",
    call. = FALSE
  )
}

# The app's packages, then the engine's (engine/DESCRIPTION, Imports).
needed <- c(
  "shiny", "bslib", "pkgload",
  "digest", "jsonlite", "jsonvalidate", "Superpower"
)
missing <- needed[!vapply(needed, requireNamespace, logical(1), quietly = TRUE)]
if (length(missing) > 0) {
  message("Installing missing packages: ", paste(missing, collapse = ", "))
  if (requireNamespace("renv", quietly = TRUE) && !is.null(renv::project())) {
    renv::install(missing, prompt = FALSE)
  } else {
    utils::install.packages(missing)
  }
}

shiny::runApp("app")
