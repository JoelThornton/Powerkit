# Property checks over every example spec in engine/inst/specs: runs
# property-check-one.R on each, in separate R processes with a time cap,
# then prints one line per design and lists every problem. Rerun before
# each release (docs/repository-protection.md, "Checks before a
# release"); a full run with 200 replications takes about two hours on
# four cores, most of it the mediation designs.
#
# Run from the repository root, with the engine installed:
#   Rscript scripts/release-checks/property-checks.R [--out DIR] [--nrep 200]
#     [--workers 4] [--timeout 1800] [--only correlation,independent_t]
#
# It exits with status 1 when any design has a problem, so a script or a
# workflow can stop on it. Results stay in DIR (one JSON and one log per
# design) for a closer look.

args <- commandArgs(TRUE)
option <- function(name, default) {
  at <- match(paste0("--", name), args)
  if (is.na(at) || at == length(args)) default else args[at + 1]
}
out_dir <- option("out", file.path(tempdir(), "property-checks"))
nrep <- as.integer(option("nrep", "200"))
workers <- as.integer(option("workers", "4"))
timeout <- as.numeric(option("timeout", "1800"))
only <- option("only", NULL)

script_dir <- "scripts/release-checks"
if (!file.exists(file.path(script_dir, "property-check-one.R"))) {
  stop("Run this from the repository root.", call. = FALSE)
}
specs <- sort(Sys.glob("engine/inst/specs/*.json"))
names(specs) <- sub("\\.json$", "", basename(specs))
if (!is.null(only)) specs <- specs[intersect(strsplit(only, ",")[[1]], names(specs))]
dir.create(out_dir, showWarnings = FALSE, recursive = TRUE)
message(sprintf("Checking %d designs, %d at a time, into %s", length(specs), workers, out_dir))

check_one <- function(name) {
  json <- file.path(out_dir, paste0(name, ".json"))
  log <- file.path(out_dir, paste0(name, ".log"))
  unlink(c(json, file.path(out_dir, paste0(name, ".status"))))
  status <- tryCatch({
    result <- callr::rscript(file.path(script_dir, "property-check-one.R"),
      cmdargs = c(specs[[name]], json, nrep), stdout = log, stderr = "2>&1",
      timeout = timeout, show = FALSE, fail_on_status = FALSE)
    if (isTRUE(result$timeout)) sprintf("timed out after %s seconds", timeout) else result$status
  }, error = function(e) {
    if (inherits(e, "system_command_timeout_error")) sprintf("timed out after %s seconds", timeout) else conditionMessage(e)
  })
  if (!file.exists(json)) writeLines(as.character(status), file.path(out_dir, paste0(name, ".status")))
  message(name, ": ", if (file.exists(json)) "done" else status)
  invisible(status)
}
if (.Platform$OS.type == "windows" || workers <= 1) {
  invisible(lapply(names(specs), check_one))
} else {
  invisible(parallel::mclapply(names(specs), check_one, mc.cores = workers, mc.preschedule = FALSE))
}

# Summary ----
problems_of <- function(j) {
  issues <- character()
  if (!is.null(j$example_error)) issues <- c(issues, paste("the example fails:", substr(j$example_error, 1, 200)))
  if (length(j$provenance_missing)) issues <- c(issues, paste("the result doesn't record", paste(unlist(j$provenance_missing), collapse = ", ")))
  if (!is.null(j$check_run_failed)) issues <- c(issues, "the backend doesn't reproduce the population entered")
  if (!is.null(j$consistency_error)) issues <- c(issues, paste("power at the recommended n fails:", substr(j$consistency_error, 1, 200)))
  if (length(j$monotone_error)) issues <- c(issues, paste("power at n or 2n fails:", substr(paste(unlist(j$monotone_error), collapse = "; "), 1, 200)))
  if (is.list(j$null) && !is.null(j$null$error)) issues <- c(issues, paste("the no-effect run fails:", substr(j$null$error, 1, 160)))
  flags <- c(
    consistency = "power at the recommended n is below the target",
    not_smallest_n = "one fewer than the recommended n also reaches the target",
    non_monotone_n = "power at 2n is below power at n",
    not_reproducible = "the same seed gives a different power",
    hash_changes = "the same spec gives a different hash",
    null_above_alpha = "with no effect, power is above alpha",
    null_well_below_alpha = "with no effect, power is well below alpha"
  )
  c(issues, unname(flags[intersect(names(flags), names(j$flags))]))
}
lines <- character()
failed <- character()
for (name in names(specs)) {
  json <- file.path(out_dir, paste0(name, ".json"))
  if (!file.exists(json)) {
    log <- file.path(out_dir, paste0(name, ".log"))
    status_file <- file.path(out_dir, paste0(name, ".status"))
    why <- c(if (file.exists(status_file)) paste("exit", readLines(status_file, warn = FALSE)),
      if (file.exists(log)) utils::tail(readLines(log, warn = FALSE), 3))
    failed <- c(failed, sprintf("%s: no result (%s)", name, substr(paste(sub("^exit (timed)", "\\1", why), collapse = " "), 1, 300)))
    next
  }
  j <- jsonlite::fromJSON(json, simplifyVector = FALSE)
  null_text <- if (is.list(j$null) && !is.null(j$null$power)) sprintf("no effect %.3f", j$null$power) else
    if (identical(j$null, "not_tested")) "no effect not tested" else ""
  total <- sum(unlist(j$timings), na.rm = TRUE)
  lines <- c(lines, sprintf("%-34s %-12s %-10s %-22s %6.0fs", name, substr(j$backend %||% "", 1, 12),
    if (isTRUE(j$simulation)) "simulated" else "", null_text, total))
  issues <- problems_of(j)
  if (length(issues)) failed <- c(failed, sprintf("%s: %s", name, paste(issues, collapse = "; ")))
}
cat(lines, sep = "\n")
cat(sprintf("\n%d design%s checked, %d with a problem.\n", length(specs), if (length(specs) == 1) "" else "s", length(failed)))
if (length(failed)) {
  cat(paste0("- ", failed), sep = "\n")
  quit(status = 1)
}
