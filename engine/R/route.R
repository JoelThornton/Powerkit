# Pick the backend adapter for a validated spec, by design and template.
# Each adapter is a list with:
#   name, packages      for the provenance record;
#   methods, default_method  "exact" and/or "simulation";
#   functions           the backend function used by each method;
#   n_step              valid sample sizes are multiples of this;
#   exact_min_n         smallest n exact_power() (or bracket_power()) accepts;
#   exact_power(n)      exact power at n (only if "exact" is a method);
#   bracket_power(n)    fast power at n, used only to bracket the required n
#                       before simulating (exact or analytic); NULL means
#                       bracket with a coarse simulation;
#   simulate(n, nrep, seed, cores)  -> list(rejections, nrep);
#   batch_size          most replications simulated in one backend call
#                       (bounds memory; simulate_in_chunks()), or NULL if
#                       the backend runs one call per core;
#   sensitivity(n, power)           -> smallest detectable effect, or NULL
#                       if sensitivity isn't available for the design;
#   check_run()         -> data frame: parameter, specified, recovered, ok;
#   sawtooth            optional; TRUE when exact power goes up and down
#                       with n (exact tests of counts), so search_n_exact()
#                       checks every smaller n.

route_spec <- function(spec, seed = NULL) {
  key <- paste(spec$design, spec$template, sep = "/")
  switch(
    key,
    "factorial_anova/2x2_between" = ,
    "factorial_anova/2x2_mixed" = ,
    "factorial_anova/mixed" = ,
    "factorial_anova/oneway_between" = ,
    "factorial_anova/oneway_within" = ,
    "factorial_anova/factorial_between" = ,
    "factorial_anova/factorial_within" = superpower_backend(spec, seed),
    "factorial_anova/oneway_ancova" = ,
    "factorial_anova/oneway_contrast" = ,
    "basic_test/one_proportion" = ,
    "basic_test/mcnemar" = ,
    "basic_test/chi_square_gof" = ,
    "basic_test/two_correlations" = ,
    "basic_test/overlapping_correlations" = ,
    "basic_test/nonoverlapping_correlations" = ,
    "multiple_regression/r2_zero" = ,
    "multiple_regression/r2_increase" = ,
    "logistic_regression/single_predictor" = ,
    "poisson_regression/single_predictor_count" = pwrss_backend(spec, seed),
    "basic_test/independent_t" = if (pwrss_covers(spec)) {
      pwrss_backend(spec, seed)
    } else if (basic_test_method(spec) == "exact") {
      pwr_backend(spec, seed)
    } else {
      spower_backend(spec, seed)
    },
    "basic_test/one_sample_t" = ,
    "basic_test/paired_t" = ,
    "basic_test/correlation" = ,
    "basic_test/two_proportions" = if (pwrss_covers(spec)) {
      pwrss_backend(spec, seed)
    } else if (basic_test_method(spec) == "exact") {
      pwr_backend(spec, seed)
    } else {
      spower_backend(spec, seed)
    },
    "equivalence_test/tost_independent" = ,
    "equivalence_test/tost_paired" = ,
    "equivalence_test/tost_one_sample" = toster_backend(spec, seed),
    "basic_test/one_variance" = ,
    "basic_test/two_variances" = spower_backend(spec, seed),
    "basic_test/chi_square_independence" = if (basic_test_method(spec) == "exact") {
      pwr_backend(spec, seed)
    } else {
      spower_backend(spec, seed)
    },
    "regression_interaction/two_way" = interactionpower_backend(spec, seed),
    "mediation/process_4" = ,
    "mediation/process_6" = ,
    "moderated_mediation/process_7" = ,
    "moderated_mediation/process_14" = power4mome_backend(spec, seed),
    "cluster_trial/cluster_randomised" = ,
    "cluster_trial/multisite" = ,
    "cluster_trial/group_treatment" = powertools_backend(spec, seed),
    "sem/model_fit" = sempower_backend(spec, seed),
    abort_not_available(sprintf(
      "Power analysis for this design (%s, template '%s') isn't available yet; it is planned for a later version of powerkit.",
      gsub("_", " ", spec$design), spec$template
    ))
  )
}

# Basic tests use pwr's exact formula unless simulation is requested or
# the test isn't one pwr covers (Welch's t-test, and the variance tests,
# which no formula backend covers at all), when Spower simulates.
# Welch's t-test by formula (pwrss) only when options > method = "exact".
basic_test_method <- function(spec) {
  spec$options$method %||% if (pwr_covers(spec)) "exact" else "simulation"
}

abort_not_available <- function(message) {
  abort_run(message, class = "powerkit_not_available")
}

# Rejections out of nrep, splitting the replications into seeded chunks
# (number_of_chunks()) that run on up to `cores` cores. For a backend with
# a batch size, the chunks are the fewest batches of at most batch_size
# replications (as equal as possible), whatever the number of cores, so
# the seed and batch size alone determine the result; cores only change
# how fast it runs (some may be idle on small runs). Other backends get
# one chunk per core. `run_chunk(nrep, seed)` returns the chunk's
# rejections, or c(rejections, valid) if some replications can fail; only
# these counts are kept, so memory is bounded by one chunk per core,
# whatever nrep. Chunk seeds are seed, seed + 1, ...; with
# nrep <= batch_size (or one core, unbatched) this is a single
# run_chunk(nrep, seed) call, so it equals one direct call to the backend
# with that seed.
simulate_in_chunks <- function(nrep, seed, cores, run_chunk, batch_size = Inf) {
  chunks <- split_replications(nrep, number_of_chunks(nrep, cores, batch_size))
  seeds <- offset_seed(seed, seq_along(chunks) - 1)
  results <- run_in_parallel(
    seq_along(chunks),
    function(i) {
      out <- run_chunk(chunks[i], seeds[i])
      if (length(out) == 1) c(out, chunks[i]) else out
    },
    cores
  )
  results <- matrix(results, nrow = 2)
  valid <- sum(results[2, ])
  if (valid == 0) {
    abort_run("None of the simulated data sets could be analysed. Check the population values, or try a larger n.")
  }
  list(rejections = sum(results[1, ]), nrep = valid)
}

# Check runs for simulation backends: a recovered value from one large
# simulated data set agrees with the specified value if it is within 5
# standard errors of it. Chance alone puts a correct translation outside
# 5 SEs about once in 1.7 million checks; a translation error (a swapped
# sign, group or path) is many SEs out at n = 100,000.
check_run_rows <- function(parameter, specified, recovered, se) {
  data.frame(
    parameter = parameter,
    specified = specified,
    recovered = recovered,
    ok = abs(recovered - specified) <= 5 * se
  )
}

check_run_n <- function() 100000L

# Smallest step between valid sample sizes (1 unless groups must split
# evenly); every multiple of it is valid.
valid_n_step <- function(spec) {
  groups <- group_split(spec)
  if (is.null(groups)) {
    return(1)
  }
  Find(groups$valid, seq_len(1000)) %||% 1
}

# Run `expr` for its value only: silence a backend's console output,
# messages and warnings. Errors still propagate (to call_backend()).
quietly <- function(expr) {
  result <- NULL
  utils::capture.output(
    result <- suppressWarnings(suppressMessages(suppressPackageStartupMessages(expr)))
  )
  result
}

# Chunks for nrep replications. With a batch size: the fewest chunks with
# at most batch_size replications each, never depending on the cores.
# Without one (batch_size = Inf): one chunk per core.
number_of_chunks <- function(nrep, cores, batch_size = Inf) {
  if (is.finite(batch_size)) {
    return(as.integer(max(1, ceiling(nrep / batch_size))))
  }
  as.integer(max(1, cores))
}

# Replications per chunk: as equal as possible, at most `chunks` chunks.
split_replications <- function(nrep, chunks) {
  k <- max(1L, min(as.integer(chunks), as.integer(nrep)))
  base <- nrep %/% k
  base + c(rep(1L, nrep %% k), rep(0L, k - nrep %% k))
}

# Deterministic, distinct seeds derived from one seed, kept in R's valid
# range (1 to 2^31 - 1).
offset_seed <- function(seed, offset) {
  as.integer((seed - 1 + offset) %% 2147483646 + 1)
}

run_in_parallel <- function(x, f, cores) {
  if (cores > 1 && .Platform$OS.type == "unix") {
    results <- parallel::mclapply(x, f, mc.cores = cores, mc.set.seed = FALSE)
    failed <- vapply(results, inherits, logical(1), what = "try-error")
    if (any(failed)) {
      abort_run(paste0(
        "The power simulation failed: ",
        conditionMessage(attr(results[[which(failed)[1]]], "condition"))
      ))
    }
    return(unlist(results))
  }
  unlist(lapply(x, f))
}

# Cores for simulation: option powerkit.cores, else the POWERKIT_CORES
# environment variable, else 1.
powerkit_cores <- function() {
  cores <- getOption("powerkit.cores", Sys.getenv("POWERKIT_CORES", "1"))
  cores <- suppressWarnings(as.integer(cores))
  if (is.na(cores) || cores < 1) 1L else cores
}

# Evaluate a backend call, turning its errors into a plain-English powerkit
# error and silencing its console messages.
call_backend <- function(backend, expr) {
  tryCatch(
    suppressMessages(expr),
    error = function(e) {
      abort_run(sprintf(
        "%s could not run this design. It reported: %s",
        backend, trimws(conditionMessage(e))
      ))
    }
  )
}

# Evaluate `expr` with the random-number generator seeded, then restore the
# caller's RNG state. With seed = NULL, just evaluate `expr`.
with_seed <- function(seed, expr) {
  if (is.null(seed)) {
    return(expr)
  }
  env <- globalenv()
  old <- if (exists(".Random.seed", envir = env, inherits = FALSE)) get(".Random.seed", envir = env)
  on.exit(
    if (is.null(old)) {
      rm(".Random.seed", envir = env)
    } else {
      assign(".Random.seed", old, envir = env)
    }
  )
  set.seed(seed)
  expr
}
