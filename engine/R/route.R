# Pick the backend adapter for a validated spec, by design and template.
# Each adapter is a list with:
#   name, simulation_function, packages  for the provenance record;
#   n_step             valid sample sizes are multiples of this;
#   approximate_min_n  smallest n approximate_power() accepts;
#   simulate(n, nrep, seed, cores)  -> list(rejections, nrep);
#   approximate_power(n)            -> a fast power value for bracketing n;
#   check_run()        -> data frame: parameter, specified, recovered, ok.

route_spec <- function(spec) {
  key <- paste(spec$design, spec$template, sep = "/")
  switch(
    key,
    "factorial_anova/2x2_between" = ,
    "factorial_anova/2x2_mixed" = superpower_backend(spec),
    abort_run(sprintf(
      "Power analysis for this design (%s, template '%s') isn't available yet; it is planned for a later version of powerkit.",
      gsub("_", " ", spec$design), spec$template
    ))
  )
}

# Replications per parallel chunk: as equal as possible, at most `cores`
# chunks.
split_replications <- function(nrep, cores) {
  k <- max(1L, min(as.integer(cores), as.integer(nrep)))
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
