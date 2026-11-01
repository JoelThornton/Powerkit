# Which validation chunks the scheduled validation runs
# (.github/workflows/nightly-validation.yaml).
#
#   Rscript scripts/validation-plan.R --all            every chunk (weekly)
#   git diff --name-only A B | Rscript scripts/validation-plan.R
#                                                      chunks for those changes
#
# Prints a JSON list for a GitHub Actions matrix: one entry per long chunk,
# and one entry holding every short chunk (each takes minutes, so they share
# a job). An empty list means nothing that the validation tests depend on
# changed.
#
# For changed files: nothing runs unless a file the validation depends on
# changed (the engine, renv.lock, the CI image or the validation runner).
# Then the short chunks always run, and a long chunk runs when its own test
# files or the backend it calls changed, or when something every chunk
# depends on changed (renv.lock, the CI image, run.R, search_n.R, the
# validation helpers). The weekly run of every chunk catches the rest.

source(file.path("scripts", "run-validation.R"), local = TRUE)

# Chunks of about a quarter of an hour or more per test.
long_chunks <- function() {
  minutes <- validation_minutes()
  names(minutes)[minutes >= 15]
}

# Engine files, beyond a chunk's own test files, whose change reruns it.
chunk_sources <- function() {
  power4mome <- "engine/R/backend-power4mome.R"
  list(
    anova = "engine/R/backend-superpower.R",
    anova_mixed_unequal = "engine/R/backend-superpower.R",
    process_4 = power4mome, process_4_binary = power4mome, process_6 = power4mome,
    process_7 = power4mome, process_14 = power4mome,
    modmed_parallel = power4mome, modmed_binary = power4mome, modmed_difference = power4mome,
    mediation_crosscheck = c(power4mome, "engine/tests/testthat/helper-crosscheck.R"),
    mediation_crosscheck_parallel = c(power4mome, "engine/tests/testthat/helper-crosscheck.R"),
    mediation_crosscheck_serial = c(power4mome, "engine/tests/testthat/helper-crosscheck.R"),
    whole_study = c(power4mome, "engine/R/whole-study.R"),
    mixed_model = "engine/R/backend-simr.R"
  )
}

shared_sources <- c(
  "renv.lock", "engine/R/run.R", "engine/R/search_n.R",
  "engine/tests/testthat/helper-validation.R",
  "engine/tests/testthat/helper-validation-specs.R",
  "engine/tests/testthat/helper-direct-calls.R"
)

validation_depends_on <- function(path) {
  startsWith(path, "engine/") | startsWith(path, ".github/ci/") |
    path %in% c("renv.lock", "scripts/run-validation.R")
}

plan_chunks <- function(changed = NULL, all = FALSE) {
  chunks <- validation_chunks()
  long <- long_chunks()
  if (!all) {
    changed <- changed[nzchar(changed)]
    if (!any(validation_depends_on(changed))) {
      return(character())
    }
    if (!any(changed %in% shared_sources | startsWith(changed, ".github/ci/"))) {
      sources <- chunk_sources()
      touched <- vapply(long, function(chunk) {
        own <- file.path("engine/tests/testthat", chunks[[chunk]])
        any(changed %in% c(own, sources[[chunk]]))
      }, logical(1))
      long <- long[touched]
    }
  }
  c(setdiff(names(chunks), long_chunks()), long)
}

# The matrix: the short chunks together, then each long chunk on its own
# (full-validation.yaml sets the cores per test from the chunk's name).
plan_matrix <- function(chunks) {
  long <- intersect(chunks, long_chunks())
  short <- setdiff(chunks, long)
  entry <- function(name, only) list(name = name, only = paste(only, collapse = ","))
  rows <- c(
    if (length(short) > 0) list(entry("short-chunks", short)),
    lapply(long, function(chunk) entry(chunk, chunk))
  )
  jsonlite::toJSON(rows, auto_unbox = TRUE)
}

if (!interactive() && sys.nframe() == 0) {
  args <- commandArgs(trailingOnly = TRUE)
  changed <- if ("--all" %in% args) NULL else readLines(file("stdin"), warn = FALSE)
  cat(plan_matrix(plan_chunks(changed, all = "--all" %in% args)), "\n", sep = "")
}
