# Load the engine and the app's helper files (not app.R, which starts the
# app). Paths are relative to app/tests/testthat.
app_dir <- normalizePath(file.path("..", ".."))
library(shiny)
for (f in c("engine-bridge.R", "forms/form_2x2.R", "confirm/confirm_2x2.R", "results/results_2x2.R", "checks/benchmarks.R")) {
  source(file.path(app_dir, f), local = FALSE)
}
load_engine(file.path(app_dir, "..", "engine"))

example_values <- function(template) {
  ex <- examples_2x2[[template]]
  list(
    template = template, a_label = ex$a_label, a1 = ex$a1, a2 = ex$a2,
    b_label = ex$b_label, b1 = ex$b1, b2 = ex$b2, y_label = ex$y_label,
    m11 = ex$means[1], m12 = ex$means[2], m21 = ex$means[3], m22 = ex$means[4],
    sd = ex$sd, r = ex$r, effect = ex$effect, alpha = ex$alpha, power = ex$power,
    just_type = ex$just_type, just_source = ex$just_source, just_adjustment = ""
  )
}
