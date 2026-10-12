#' Run a power analysis
#'
#' Validates a design specification, checks that the backend reproduces the
#' specified population (the check run), then computes power at a fixed n,
#' the sample size that reaches the target power, or the smallest
#' detectable effect.
#'
#' **Method.** `options > method` chooses how power is computed. For 2x2
#' ANOVA designs the default is `"exact"` (Superpower's `ANOVA_exact()`,
#' exact for the specified population); `"simulation"` uses Monte Carlo
#' simulation with `options > nrep` replications (default 1,000) and
#' `options > seed` (drawn and recorded if not given). Set
#' `options(powerkit.cores = k)` or the environment variable `POWERKIT_CORES`
#' to spread simulation replications over `k` cores (Unix-alikes only).
#'
#' **Sensitivity.** The shape of the specified pattern is kept and its size
#' scaled (for 2x2 designs, each cell mean's deviation from the grand mean)
#' until the target effect reaches the target power at n.
#'
#' @param spec A spec as a named list, a JSON string or a path to a JSON file.
#'
#' @return A `powerkit_result`: a list with
#'   * `goal_type`: the spec's goal type;
#'   * `curve`: data frame of `n`, `power` and `mcse` (Monte Carlo standard
#'     error; 0 for exact results); a single row for a fixed-n or
#'     sensitivity goal;
#'   * `n_required`: list of `n`, `lower` and `upper` (95% interval for
#'     simulation; all equal for exact results), or `NA` unless the goal is
#'     `sample_size`;
#'   * `sensitivity`: `NA` unless the goal is `sensitivity`; otherwise a list
#'     with the `scale` applied to the specified pattern, the scaled cell
#'     `means`, the target `effect` in the user's units (with an
#'     `effect_description`), its `cohen_f`, and the `power` reached;
#'   * `check_run`: data frame comparing specified and recovered population
#'     values;
#'   * `provenance`: spec hash, method, seed, replications, backend and
#'     backend function, R and package versions, and run time.
#' @export
#' @examples
#' \donttest{
#' spec <- read_spec(system.file("specs", "anova_2x2_mixed.json", package = "powerkit"))
#' run_spec(spec)
#' }
run_spec <- function(spec) {
  spec <- validate_spec(spec)
  seed <- spec$options$seed %||% sample.int(2147483646L, 1)
  backend <- route_spec(spec, seed)
  method <- spec$options$method %||% backend$default_method
  if (!method %in% backend$methods) {
    abort_run(sprintf(
      "The '%s' method isn't available for this design; use %s.",
      method, quote_list(backend$methods)
    ))
  }
  simulating <- method == "simulation"
  nrep <- if (simulating) spec$options$nrep %||% 1000L else NA_integer_
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
    power = list(
      curve = power_at_n(backend, goal$n, simulating, nrep, seed, cores),
      n_required = NA,
      sensitivity = NA
    ),
    sample_size = c(
      if (simulating) {
        search_n(spec, backend, goal$power, nrep, seed, cores)
      } else {
        search_n_exact(spec, backend, goal$power)
      },
      list(sensitivity = NA)
    ),
    sensitivity = {
      if (simulating) {
        abort_run(
          "Sensitivity analysis uses the exact method; remove 'options > method' or set it to 'exact'."
        )
      }
      found <- backend$sensitivity(goal$n, goal$power)
      list(
        curve = data.frame(n = goal$n, power = found$power, mcse = 0),
        n_required = NA,
        sensitivity = found
      )
    }
  )

  structure(
    list(
      goal_type = goal$type,
      curve = outcome$curve,
      n_required = outcome$n_required,
      sensitivity = outcome$sensitivity,
      check_run = check,
      provenance = list(
        spec_hash = spec_hash(spec),
        method = method,
        seed = seed,
        nrep = nrep,
        cores = if (simulating) cores else NA_integer_,
        backend = backend$name,
        backend_function = backend$functions[[method]],
        r_version = R.version.string,
        packages = package_versions(c("powerkit", backend$packages)),
        started = format(started, "%Y-%m-%d %H:%M:%S %Z"),
        run_time_seconds = as.numeric(difftime(Sys.time(), started, units = "secs"))
      )
    ),
    class = "powerkit_result"
  )
}

power_at_n <- function(backend, n, simulating, nrep, seed, cores) {
  if (!simulating) {
    return(data.frame(n = n, power = backend$exact_power(n), mcse = 0))
  }
  sim <- backend$simulate(n, nrep, seed, cores)
  p <- sim$rejections / sim$nrep
  data.frame(n = n, power = p, mcse = sqrt(p * (1 - p) / sim$nrep))
}

package_versions <- function(packages) {
  vapply(packages, function(p) as.character(utils::packageVersion(p)), character(1))
}

#' @export
print.powerkit_result <- function(x, ...) {
  cat("<powerkit result>\n")
  if (identical(x$goal_type, "sample_size")) {
    est <- x$n_required
    if (identical(x$provenance$method, "exact")) {
      cat(sprintf("Required n: %s (exact)\n", est$n))
    } else {
      cat(sprintf("Required n: %s (95%% interval %s to %s)\n", est$n, est$lower, est$upper))
    }
  }
  curve <- x$curve
  cat("Power by n:\n")
  for (i in seq_len(nrow(curve))) {
    cat(sprintf("  n = %-6s power = %.3f (MC SE %.3f)\n", curve$n[i], curve$power[i], curve$mcse[i]))
  }
  if (identical(x$goal_type, "sensitivity")) {
    s <- x$sensitivity
    cat(sprintf(
      "Smallest detectable effect: %s = %s (Cohen's f = %.3f)\n",
      s$effect_description, format(signif(s$effect, 4)), s$cohen_f
    ))
  }
  p <- x$provenance
  method <- if (p$method == "simulation") {
    sprintf("simulation, %s replications, seed %s", p$nrep, p$seed)
  } else {
    "exact"
  }
  cat(sprintf(
    "Check run: %s\nBackend: %s %s (%s)\nSpec hash: %s\n",
    if (all(x$check_run$ok)) "passed" else "FAILED",
    p$backend, p$packages[[p$backend]], method, p$spec_hash
  ))
  invisible(x)
}

abort_run <- function(message, class = NULL) {
  stop(structure(
    class = c(class, "powerkit_run_error", "powerkit_error", "error", "condition"),
    list(message = message, call = NULL)
  ))
}
