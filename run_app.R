# Start the powerkit prototype app (2x2 between and 2x2 mixed designs).
#
# In RStudio: open Powerkit.Rproj, open this file and click "Source"
# (or run source("run_app.R") in the console). Nothing is installed here;
# see "Run the demo" in app/README.md for the packages the demo needs.

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
  stop(
    "The demo needs these packages, which aren't installed: ",
    paste(missing, collapse = ", "), ". Install them with:\n  install.packages(c(",
    paste0("\"", needed, "\"", collapse = ", "), "))",
    call. = FALSE
  )
}

shiny::runApp("app")
