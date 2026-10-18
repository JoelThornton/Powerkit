# Start the powerkit routing prototype (app/routing/).
#
# Routing only: it shows which analysis a study needs and calculates
# nothing. See docs/routing-prototype.md for step-by-step instructions.
#
# New to R? Use run_powerkit.R instead (docs/run-it-yourself.md): it
# installs what the app needs and then starts it.
#
# In RStudio: open Powerkit.Rproj, then run source("run_routing_prototype.R")
# in the console. Nothing is installed here.

if (!dir.exists(file.path("app", "routing"))) {
  stop(
    "Run this from the Powerkit project folder: open Powerkit.Rproj in RStudio, then source(\"run_routing_prototype.R\").",
    call. = FALSE
  )
}

needed <- c("shiny", "bslib", "yaml")
missing <- needed[!vapply(needed, requireNamespace, logical(1), quietly = TRUE)]
if (length(missing) > 0) {
  stop(
    "The prototype needs these packages, which aren't installed: ",
    paste(missing, collapse = ", "), ". Install them with:\n  install.packages(c(",
    paste0("\"", needed, "\"", collapse = ", "), "))",
    call. = FALSE
  )
}

shiny::runApp(file.path("app", "routing"), launch.browser = TRUE)
