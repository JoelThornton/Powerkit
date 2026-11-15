# Prediction model validation (design "prediction_model", template
# "validation"): the minimum sample size for validating an existing
# prediction model of a yes/no outcome in new data, by the criteria of
# Riley et al. (2021), computed by pmvalsampsize's pmvalsampsize() (Ensor,
# the package's own citation(); its help names the papers by Riley et al.
# and Archer et al. that set out the criteria). There is no power: the
# answer is the largest of the criteria's sample sizes.
#
# The criteria (pmvalsampsize's help, Details), each a target width for a
# 95% confidence interval:
#   1. the observed/expected (O/E) ratio, calibration-in-the-large
#   2. the calibration slope, whose standard error pmvalsampsize works out
#      from a simulated linear predictor (a normal distribution of the
#      log-odds, or a beta distribution of the predicted probabilities)
#   3. the C-statistic
#   4. optionally, the standardised net benefit at a risk threshold
#
# The linear predictor is simulated with pmvalsampsize's own seed and
# number of draws (123456 and 1,000,000, its defaults): powerkit always
# passes those, so its answer is the one pmvalsampsize gives by default,
# and records the seed.

prediction_validation <- function(spec) {
  identical(spec$design, "prediction_model") && identical(spec$template, "validation")
}

prediction_validation_defaults <- list(oe = 1, calibration_slope = 1, oe_ci_width = 0.2, cslope_ci_width = 0.2,
  cstat_ci_width = 0.1, nb_ci_width = 0.2, seed = 123456L, simobs = 1e6)

# The named arguments of pmvalsampsize(), from the spec.
prediction_validation_args <- function(spec) {
  pop <- spec$population
  goal <- spec$goal
  d <- prediction_validation_defaults
  args <- list(type = "b", prevalence = pop$prevalence, cstatistic = pop$c_statistic,
    oe = pop$oe %||% d$oe, cslope = pop$calibration_slope %||% d$calibration_slope,
    oeciwidth = goal$oe_ci_width %||% d$oe_ci_width, csciwidth = goal$cslope_ci_width %||% d$cslope_ci_width,
    cstatciwidth = goal$cstat_ci_width %||% d$cstat_ci_width)
  args <- c(args, switch(pop$lp_distribution,
    normal = list(lpnormal = c(pop$lp_mean, pop$lp_sd)),
    beta = list(lpbeta = c(pop$beta_a, pop$beta_b))))
  if (!is.null(pop$threshold)) {
    args$threshold <- pop$threshold
    args$nbciwidth <- goal$nb_ci_width %||% d$nb_ci_width
    if (!is.null(pop$sensitivity)) {
      args$sensitivity <- pop$sensitivity
      args$specificity <- pop$specificity
    }
  }
  c(args, list(seed = d$seed, simobs = d$simobs))
}

check_prediction_validation <- function(spec) {
  pop <- spec$population
  goal <- spec$goal
  problems <- character()
  if (!is.null(goal$shrinkage) || !is.null(goal$intercept_margin)) {
    problems <- c(problems, "'goal > shrinkage' and 'goal > intercept_margin' are for developing a model ('template' \"development\"); remove them.")
  }
  needed <- switch(pop$lp_distribution, normal = c("lp_mean", "lp_sd"), beta = c("beta_a", "beta_b"))
  missing <- needed[vapply(needed, function(f) is.null(pop[[f]]), logical(1))]
  if (length(missing)) {
    problems <- c(problems, sprintf("A %s linear predictor needs %s.", pop$lp_distribution,
      paste(sprintf("'population > %s'", missing), collapse = " and ")))
  }
  unused <- setdiff(c("lp_mean", "lp_sd", "beta_a", "beta_b"), needed)
  given <- unused[vapply(unused, function(f) !is.null(pop[[f]]), logical(1))]
  if (length(given)) {
    problems <- c(problems, sprintf("%s isn't used with a %s linear predictor; remove it.",
      paste(sprintf("'population > %s'", given), collapse = " and "), pop$lp_distribution))
  }
  if (is.null(pop$threshold) && (!is.null(pop$sensitivity) || !is.null(pop$specificity) || !is.null(goal$nb_ci_width))) {
    problems <- c(problems, "Sensitivity, specificity and 'goal > nb_ci_width' are for the net benefit at a risk threshold: give 'population > threshold' too, or remove them.")
  }
  if (xor(is.null(pop$sensitivity), is.null(pop$specificity))) {
    problems <- c(problems, "Give both 'population > sensitivity' and 'population > specificity', or neither (pmvalsampsize then estimates them from the linear predictor).")
  }
  problems
}

prediction_validation_call <- function(args) {
  need_packages("pmvalsampsize")
  quietly(do.call(pmvalsampsize::pmvalsampsize, args))
}

prediction_validation_criteria <- function(out) {
  table <- out$results_table
  rows <- grep("^Criteria", rownames(table))
  labels <- c(
    `Criteria 1 - O/E` = "A precise estimate of the observed/expected ratio (calibration-in-the-large)",
    `Criteria 2 - C-slope` = "A precise estimate of the calibration slope",
    `Criteria 3 - C statistic` = "A precise estimate of the C-statistic",
    `Criteria 4 - St Net Benefit` = "A precise estimate of the standardised net benefit at the risk threshold")
  names <- rownames(table)[rows]
  data.frame(criterion = ifelse(names %in% names(labels), labels[names], names), n = as.numeric(table[rows, "Samp_size"]),
    ci_width = as.numeric(table[rows, "CI width"]), stringsAsFactors = FALSE, row.names = NULL)
}

run_prediction_validation <- function(spec, seed) {
  started <- Sys.time()
  args <- prediction_validation_args(spec)
  out <- call_backend("pmvalsampsize", prediction_validation_call(args))
  n <- as.numeric(out$sample_size)
  criteria <- prediction_validation_criteria(out)
  prediction <- list(
    outcome = "binary",
    validation = TRUE,
    n = n,
    criteria = criteria,
    binding = criteria$criterion[which.max(criteria$n)],
    events = as.numeric(out$events %||% NA_real_),
    c_statistic = spec$population$c_statistic,
    prevalence = spec$population$prevalence,
    function_used = "pmvalsampsize::pmvalsampsize"
  )
  check <- data.frame(
    parameter = c("anticipated C-statistic passed to pmvalsampsize()", "outcome proportion passed",
      "target width of the C-statistic's interval reached (criterion 3)", "the final sample size is the largest criterion's"),
    specified = c(args$cstatistic, args$prevalence, args$cstatciwidth, max(criteria$n)),
    recovered = c(as.numeric(out$cstatistic), as.numeric(out$prevalence),
      criteria$ci_width[grepl("C-statistic", criteria$criterion)], n),
    stringsAsFactors = FALSE
  )
  # pmvalsampsize reports the widths it reached to two or three decimals.
  check$ok <- abs(check$specified - check$recovered) < c(1e-8, 1e-8, 0.005, 1e-8)
  structure(
    list(
      goal_type = "criteria",
      curve = data.frame(n = n, power = NA_real_, mcse = 0),
      n_required = list(n = n, lower = n, upper = n),
      sensitivity = NA,
      prediction = prediction,
      recruitment = recruitment_target(spec, n),
      check_run = check,
      provenance = list(
        evidence = analysis_evidence(spec, computation_method = "exact"),
        spec_hash = spec_hash(spec),
        method = "exact",
        seed = prediction_validation_defaults$seed,
        nrep = NA_integer_,
        cores = NA_integer_,
        batch_size = NA_integer_,
        simulations = NA,
        backend = "pmvalsampsize",
        backend_function = "pmvalsampsize::pmvalsampsize",
        r_version = R.version.string,
        packages = package_versions(c("powerkit", "pmvalsampsize")),
        started = format(started, "%Y-%m-%d %H:%M:%S %Z"),
        run_time_seconds = as.numeric(difftime(Sys.time(), started, units = "secs"))
      )
    ),
    class = "powerkit_result"
  )
}

prediction_validation_script <- function(spec, result) {
  args <- prediction_validation_args(spec)
  call <- paste0("pmvalsampsize(", paste(sprintf("%s = %s", names(args), vapply(args, r_code, character(1))), collapse = ", "), ")")
  c(
    script_header(spec, result, "pmvalsampsize", "pmvalsampsize::pmvalsampsize"),
    "library(pmvalsampsize)",
    "",
    "# The minimum sample size for validating the existing prediction model in",
    "# new data, by the criteria of Riley and colleagues (pmvalsampsize's help,",
    "# Details). The linear predictor is simulated with pmvalsampsize's default",
    "# seed and number of draws.",
    paste0("result <- ", call),
    "result",
    "",
    "n_total <- result$sample_size",
    "reproduced <- list(n = n_total)",
    sprintf("powerkit_result <- list(n = %s)", r_code(result$prediction$n)),
    "",
    comparison_section()
  )
}

prediction_validation_description <- function(spec, label) {
  pop <- spec$population
  sprintf(
    "Minimum sample size for validating an existing prediction model of %s (a yes/no outcome, proportion %s) with an anticipated C-statistic of %s, by the criteria of Riley and colleagues (pmvalsampsize's pmvalsampsize())%s",
    label("Y"), format_number(pop$prevalence), format_number(pop$c_statistic),
    if (!is.null(pop$threshold)) sprintf(", with the net benefit at a risk threshold of %s", format_number(pop$threshold)) else ""
  )
}
