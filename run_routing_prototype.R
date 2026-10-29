# Start the powerkit app (app/routing/) from an R session that already has
# the packages. See docs/routing-prototype.md for step-by-step instructions.
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

# The design finder works without the engine; the input screens don't.
engine_ready <- requireNamespace("powerkit", quietly = TRUE) || local({
  imports <- read.dcf(file.path("engine", "DESCRIPTION"), fields = "Imports")[1, "Imports"]
  imports <- trimws(sub("\\(.*", "", strsplit(imports, ",")[[1]]))
  all(vapply(c("pkgload", imports), requireNamespace, logical(1), quietly = TRUE))
})
if (!engine_ready) {
  warning(
    "powerkit's engine can't be loaded, so the design finder works but nothing will calculate. ",
    "Run renv::restore() to install the engine's packages, or start powerkit with run_powerkit.R instead.",
    call. = FALSE, immediate. = TRUE
  )
}

shiny::runApp(file.path("app", "routing"), launch.browser = TRUE)
