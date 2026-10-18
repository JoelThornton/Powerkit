# Helpers for the export tests.

rscript_path <- function() {
  file.path(R.home("bin"), if (.Platform$OS.type == "windows") "Rscript.exe" else "Rscript")
}

# Set environment variables (NA unsets one) until the calling function
# returns.
local_env <- function(..., .frame = parent.frame()) {
  values <- c(...)
  old <- Sys.getenv(names(values), unset = NA, names = TRUE)
  set <- function(v) {
    for (name in names(v)) {
      if (is.na(v[[name]])) Sys.unsetenv(name) else do.call(Sys.setenv, as.list(v[name]))
    }
  }
  set(values)
  do.call(on.exit, list(substitute(set(old)), add = TRUE), envir = .frame)
  invisible(old)
}

# Export the script for `result`, run it in a fresh R session
# (R --vanilla: no powerkit, nothing from this session), and return what
# it reproduced, the numbers it compares against, and the script itself.
# The child session finds packages through R_LIBS (this session's library
# paths). R_TESTS, set by R CMD check, is unset for it.
run_exported_script <- function(spec, result) {
  dir <- tempfile("powerkit-export-")
  dir.create(dir)
  on.exit(unlink(dir, recursive = TRUE), add = TRUE)
  script <- file.path(dir, "reproduce.R")
  export_script(spec, result, script)
  runner <- file.path(dir, "runner.R")
  out <- file.path(dir, "reproduced.rds")
  writeLines(c(
    "args <- commandArgs(trailingOnly = TRUE)",
    "source(args[1])",
    "saveRDS(list(reproduced = reproduced, powerkit = powerkit_result), args[2])"
  ), runner)
  local_env(R_LIBS = paste(.libPaths(), collapse = .Platform$path.sep), R_TESTS = NA)
  log <- suppressWarnings(system2(
    rscript_path(),
    c("--vanilla", shQuote(runner), shQuote(script), shQuote(out)),
    stdout = TRUE, stderr = TRUE
  ))
  if (!file.exists(out)) {
    stop("The exported script failed:\n", paste(utils::tail(log, 20), collapse = "\n"), call. = FALSE)
  }
  c(readRDS(out), list(script = readLines(script, encoding = "UTF-8")))
}

# The exported script reproduces a simulated power value (within the
# validation tolerance, and in fact exactly: same seeds, same data sets).
expect_script_reproduces_power <- function(spec, result) {
  run <- run_exported_script(spec, result)
  expect_false(any(grepl("powerkit::|library\\(powerkit\\)", run$script)))
  p <- result$provenance
  reproduced <- if (p$method == "simulation") {
    binomial_estimate(run$reproduced$power, p$nrep)
  } else {
    exact_estimate(run$reproduced$power)
  }
  if (p$method == "simulation") {
    expect_power_agrees(reproduced, binomial_estimate(result$curve$power, p$nrep))
  } else {
    expect_power_near(reproduced, result$curve$power)
  }
  expect_equal(run$reproduced$power, result$curve$power, tolerance = 1e-10)
  expect_equal(run$reproduced, run$powerkit, tolerance = 1e-10)
  invisible(run)
}

skip_unless_scripts_can_run <- function() {
  # Each test starts a separate R session and runs a simulation.
  skip_on_cran()
  skip_if_not(file.exists(rscript_path()), "Rscript not found")
}

# A run with the "fewer than 1,000 replications" advice muffled, on one
# core unless `cores` says otherwise.
run_for_export <- function(spec, cores = 1) {
  old <- options(powerkit.cores = cores)
  on.exit(options(old))
  run_quietly(spec)
}

# A minimal result for the citation tests, which only read the provenance.
fake_result <- function(backend) {
  structure(
    list(provenance = list(
      backend = backend,
      spec_hash = "0123abcd",
      packages = stats::setNames(c("0.0.0.9000", "1.0"), c("powerkit", backend))
    )),
    class = "powerkit_result"
  )
}

# Write the run script for `spec` (export_run_script()), run it in a fresh R
# session in an empty folder, and return the result it saved and which of
# its files it wrote. Under devtools::load_all() powerkit isn't installed,
# so the script loads the same source instead.
run_exported_run_script <- function(spec) {
  dir <- tempfile("powerkit-run-")
  dir.create(dir)
  on.exit(unlink(dir, recursive = TRUE), add = TRUE)
  text <- export_run_script(spec)
  path <- getNamespaceInfo(asNamespace("powerkit"), "path")
  if (dir.exists(file.path(path, "tests"))) {
    text <- sub(
      "library(powerkit)",
      sprintf("pkgload::load_all(%s, quiet = TRUE, export_all = FALSE, helpers = FALSE)", encodeString(path, quote = "\"")),
      text,
      fixed = TRUE
    )
  }
  script <- file.path(dir, "run.R")
  writeLines(text, script)
  local_env(R_LIBS = paste(.libPaths(), collapse = .Platform$path.sep), R_TESTS = NA)
  old <- setwd(dir)
  on.exit(setwd(old), add = TRUE, after = FALSE)
  log <- suppressWarnings(system2(
    rscript_path(), c("--vanilla", shQuote(script)),
    stdout = TRUE, stderr = TRUE
  ))
  saved <- file.path(dir, "powerkit-result.rds")
  if (!file.exists(saved)) {
    stop("The run script failed:\n", paste(utils::tail(log, 20), collapse = "\n"), call. = FALSE)
  }
  files <- c("powerkit-reproduce.R", "powerkit-citations.txt")
  list(result = readRDS(saved), files = stats::setNames(file.exists(file.path(dir, files)), files))
}
