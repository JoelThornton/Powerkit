# Native side of the spike: build E2 and E10 specs from the engine's
# examples, time run_spec(), export the backend-only scripts and time them.
library(powerkit)
dir.create("spike/webr/out", showWarnings = FALSE, recursive = TRUE)

e2 <- read_spec(system.file("specs", "independent_t.json", package = "powerkit"))
e2$target_test$method <- "student_t"           # the app's default for E2 (pwr, exact)
e2$goal <- list(type = "power", n = 200)
e2$options$attrition <- NULL

e10 <- read_spec(system.file("specs", "mediation_simple.json", package = "powerkit"))
e10$goal <- list(type = "power", n = 200)
e10$options$attrition <- NULL
e10$options$nrep <- 100                        # the app's preview size

options(powerkit.cores = 1)
times <- list()
for (name in c("e2", "e10")) {
  spec <- validate_spec(get(name))
  t <- system.time(res <- run_spec(spec))[["elapsed"]]
  path <- sprintf("spike/webr/out/%s.R", name)
  export_script(spec, res, file = path)
  t_script <- system.time(source(path, local = new.env()))[["elapsed"]]
  times[[name]] <- list(engine_seconds = t, script_seconds = t_script,
                        power = res$curve$power, nrep = if (is.null(spec$options$nrep)) NA else spec$options$nrep)
  cat(sprintf("NATIVE %s: run_spec %.2f s, script %.2f s, power %.4f\n", name, t, t_script, res$curve$power))
}
times$r_version <- R.version.string
times$packages <- vapply(c("pwr", "power4mome", "lavaan", "manymome"), function(p) format(packageVersion(p)), "")
jsonlite::write_json(times, "spike/webr/out/native.json", auto_unbox = TRUE, pretty = TRUE)
