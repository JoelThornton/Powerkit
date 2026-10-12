#' Run a power analysis
#'
#' Validates a design specification, checks that the backend reproduces the
#' specified population (the check run), then estimates power at a fixed n
#' or searches for the sample size that reaches the target power.
#'
#' Runs use `options > nrep` replications (default 1,000) and `options >
#' seed` (a random seed is drawn and recorded if none is given). Set
#' `options(powerkit.cores = k)` or the environment variable `POWERKIT_CORES`
#' to spread replications over `k` cores (Unix-alikes only).
#'
#' @param spec A spec as a named list, a JSON string or a path to a JSON file.
#'
#' @return A `powerkit_result`: a list with
#'   * `goal_type`: the spec's goal type;
#'   * `curve`: data frame of `n`, `power` and `mcse` (Monte Carlo standard
#'     error) for each sample size simulated; a single row for a fixed-n goal;
#'   * `n_required`: list of `n`, `lower` and `upper` (95% interval), or `NA`
#'     unless the goal is `sample_size`;
#'   * `sensitivity`: `NA` unless the goal is `sensitivity`;
#'   * `check_run`: data frame comparing specified and recovered population
#'     values;
#'   * `provenance`: spec hash, seed, replications, backend, R and package
#'     versions, and run time.
#' @export
#' @examples
#' \donttest{
#' spec <- read_spec(system.file("specs", "anova_2x2_mixed.json", package = "powerkit"))
#' spec$options$nrep <- 200
#' run_spec(spec)
#' }
run_spec <- function(spec) {
  spec <- validate_spec(spec)
  backend <- route_spec(spec)
  nrep <- spec$options$nrep %||% 1000L
  seed <- spec$options$seed %||% sample.int(2147483646L, 1)
  cores <- powerkit_cores()
  started <- Sys.time()

  check <- backend$check_run()
  if (!all(check$ok)) {
    abort_run(paste0(
      "powerkit's translation of this design to ", backend$name,
      " did not reproduce the population you specified (",
      paste(check$parameter[!check$ok], collapse = "; "),
      "). This is a bug in powerkit, not in your spec; please report it."
    ))
  }

  goal <- spec$goal
  outcome <- switch(
    goal$type,
    power = {
      sim <- backend$simulate(goal$n, nrep, seed, cores)
      p <- sim$rejections / sim$nrep
      list(
        curve = data.frame(n = goal$n, power = p, mcse = sqrt(p * (1 - p) / sim$nrep)),
        n_required = NA
      )
    },
    sample_size = search_n(spec, backend, goal$power, nrep, seed, cores),
    sensitivity = abort_run(
      "Sensitivity analysis (the smallest detectable effect) isn't available yet; use goal type 'power' or 'sample_size'."
    )
  )

  structure(
    list(
      goal_type = goal$type,
      curve = outcome$curve,
      n_required = outcome$n_required,
      sensitivity = NA,
      check_run = check,
      provenance = list(
        spec_hash = spec_hash(spec),
        seed = seed,
        nrep = nrep,
        cores = cores,
        backend = backend$name,
        simulation_function = backend$simulation_function,
        r_version = R.version.string,
        packages = package_versions(c("powerkit", backend$packages)),
        started = format(started, "%Y-%m-%d %H:%M:%S %Z"),
        run_time_seconds = as.numeric(difftime(Sys.time(), started, units = "secs"))
      )
    ),
    class = "powerkit_result"
  )
}

package_versions <- function(packages) {
  vapply(packages, function(p) as.character(utils::packageVersion(p)), character(1))
}

#' @export
print.powerkit_result <- function(x, ...) {
  cat("<powerkit result>\n")
  if (identical(x$goal_type, "sample_size")) {
    cat(sprintf(
      "Required n: %s (95%% interval %s to %s)\n",
      x$n_required$n, x$n_required$lower, x$n_required$upper
    ))
  }
  curve <- x$curve
  cat("Power by n:\n")
  for (i in seq_len(nrow(curve))) {
    cat(sprintf("  n = %-6s power = %.3f (MC SE %.3f)\n", curve$n[i], curve$power[i], curve$mcse[i]))
  }
  p <- x$provenance
  cat(sprintf(
    "Check run: %s\nBackend: %s %s; %s replications; seed %s\nSpec hash: %s\n",
    if (all(x$check_run$ok)) "passed" else "FAILED",
    p$backend, p$packages[[p$backend]], p$nrep, p$seed, p$spec_hash
  ))
  invisible(x)
}

abort_run <- function(message) {
  stop(structure(
    class = c("powerkit_run_error", "powerkit_error", "error", "condition"),
    list(message = message, call = NULL)
  ))
}
