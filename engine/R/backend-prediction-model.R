# Prediction model development (design "prediction_model", template
# "development"): the minimum sample size for developing a multivariable
# prediction model, by the criteria of Riley and colleagues, computed by
# pmsampsize's pmsampsize() (Ensor, the package's own citation(); its help
# names the papers by Riley et al. that set out the criteria). There is no
# power: the answer is the largest of the criteria's sample sizes.
#
# The criteria (pmsampsize's help, Details):
#   binary and survival outcomes
#     1. small overfitting: an expected shrinkage of the predictor effects
#        of at least `goal > shrinkage` (0.9 by default)
#     2. a small absolute difference (0.05) between the model's apparent
#        and adjusted Nagelkerke R-squared
#     3. a precise estimate (within 0.05) of the overall outcome risk (at
#        the time point, for a survival outcome)
#   continuous outcomes
#     1 and 2 as above (the difference in R-squared itself), then
#     3. a precise estimate of the residual SD, and
#     4. a precise estimate of the mean outcome (the intercept), within a
#        multiplicative margin `goal > intercept_margin` (1.1 by default)
#
# A C-statistic (binary outcomes) is converted by pmsampsize into a
# Cox-Snell R-squared with the outcome proportion, by a simulation with a
# seed of its own (pmsampsize's `seed`). powerkit always passes
# pmsampsize's default seed, 123456, so its answer is the one pmsampsize
# (and its Stata version) gives by default, and records it. Every other
# input is a closed form inside pmsampsize.

prediction_goal <- function(spec) identical(spec$goal$type, "criteria")

prediction_outcome <- function(spec) {
  switch(spec$variables$Y$type %||% "binary", binary = "binary", continuous = "continuous", time_to_event = "survival")
}

prediction_defaults <- list(shrinkage = 0.9, intercept_margin = 1.1, seed = 123456L)

# The named arguments of pmsampsize(), from the spec.
prediction_args <- function(spec) {
  pop <- spec$population
  goal <- spec$goal
  outcome <- prediction_outcome(spec)
  args <- list(type = switch(outcome, binary = "b", continuous = "c", survival = "s"),
    parameters = as.integer(pop$parameters), shrinkage = goal$shrinkage %||% prediction_defaults$shrinkage)
  args <- c(args, switch(pop$metric,
    c_statistic = list(cstatistic = pop$c_statistic),
    cox_snell_r2 = list(csrsquared = pop$cox_snell_r2),
    nagelkerke_r2 = list(nagrsquared = pop$nagelkerke_r2),
    r2 = list(rsquared = pop$r2)))
  args <- c(args, switch(outcome,
    binary = list(prevalence = pop$prevalence),
    continuous = list(intercept = pop$mean, sd = pop$sd, mmoe = goal$intercept_margin %||% prediction_defaults$intercept_margin),
    survival = list(rate = pop$rate, timepoint = pop$timepoint, meanfup = pop$mean_follow_up)))
  if (identical(pop$metric, "c_statistic")) args$seed <- prediction_defaults$seed
  args
}

check_prediction_model <- function(spec) {
  goal <- spec$goal
  if (prediction_goal(spec) && !identical(spec$design, "prediction_model")) {
    return("'goal > type' \"criteria\" is only for prediction model development ('design' \"prediction_model\"): choose 'sample_size', 'power' or 'sensitivity' here.")
  }
  if (!identical(spec$design, "prediction_model")) {
    if (!is.null(goal$shrinkage) || !is.null(goal$intercept_margin)) {
      return("'goal > shrinkage' and 'goal > intercept_margin' are only for prediction model development ('design' \"prediction_model\"); remove them.")
    }
    return(character())
  }
  pop <- spec$population
  outcome <- prediction_outcome(spec)
  problems <- character()
  allowed <- switch(outcome, binary = c("c_statistic", "cox_snell_r2", "nagelkerke_r2"), continuous = "r2",
    survival = c("cox_snell_r2", "nagelkerke_r2"))
  if (!pop$metric %in% allowed) {
    problems <- c(problems, sprintf("For a %s outcome, give the model's anticipated performance as %s ('population > metric').",
      switch(outcome, binary = "yes/no", continuous = "continuous", survival = "time-to-event"), quote_list(allowed)))
  } else if (is.null(pop[[pop$metric]])) {
    problems <- c(problems, sprintf("'population > %s' is needed: the model's anticipated performance.", pop$metric))
  }
  needed <- switch(outcome, binary = "prevalence", continuous = c("mean", "sd"), survival = c("rate", "timepoint", "mean_follow_up"))
  missing <- needed[vapply(needed, function(f) is.null(pop[[f]]), logical(1))]
  if (length(missing)) {
    problems <- c(problems, sprintf("A %s outcome needs %s.", switch(outcome, binary = "yes/no", continuous = "continuous",
      survival = "time-to-event"), paste(sprintf("'population > %s'", missing), collapse = " and ")))
  }
  others <- setdiff(c("prevalence", "mean", "sd", "rate", "timepoint", "mean_follow_up"), needed)
  given <- others[vapply(others, function(f) !is.null(pop[[f]]), logical(1))]
  if (length(given)) {
    problems <- c(problems, sprintf("%s isn't used for a %s outcome; remove it.", paste(sprintf("'population > %s'", given), collapse = " and "),
      switch(outcome, binary = "yes/no", continuous = "continuous", survival = "time-to-event")))
  }
  r2s <- c("c_statistic", "cox_snell_r2", "nagelkerke_r2", "r2")
  extra <- setdiff(r2s[vapply(r2s, function(f) !is.null(pop[[f]]), logical(1))], pop$metric)
  if (length(extra)) {
    problems <- c(problems, sprintf("Give one measure of the model's performance, the one 'population > metric' names; remove %s.",
      paste(sprintf("'population > %s'", extra), collapse = " and ")))
  }
  if (!is.null(goal$intercept_margin) && !identical(outcome, "continuous")) {
    problems <- c(problems, "'goal > intercept_margin' is for a continuous outcome only; remove it.")
  }
  if (identical(outcome, "survival") && !is.null(pop$timepoint) && !is.null(pop$mean_follow_up) && pop$timepoint > 10 * pop$mean_follow_up) {
    problems <- c(problems, "'population > timepoint' is far beyond the mean follow-up: check that both are in the same time unit.")
  }
  if (!length(problems) && pop$metric == "cox_snell_r2") {
    # The largest Cox-Snell R-squared a model can reach is below 1; the
    # anticipated value must be below it (pmsampsize stops otherwise).
    limit <- prediction_max_cox_snell(spec)
    if (!is.na(limit) && pop$cox_snell_r2 >= limit) {
      problems <- c(problems, sprintf("A Cox-Snell R-squared of %s is at or above the largest any model can reach here (%s); check the value, or give the Nagelkerke R-squared instead.",
        format_number(pop$cox_snell_r2), format_number(signif(limit, 3))))
    }
  }
  problems
}

# The largest Cox-Snell R-squared a model of this outcome can reach
# (pmsampsize's max_r2a, from the outcome proportion or event rate), or NA
# when pmsampsize doesn't report it.
prediction_max_cox_snell <- function(spec) {
  args <- prediction_args(spec)
  args$csrsquared <- 1e-6
  out <- tryCatch(prediction_call(args), error = function(e) NULL)
  as.numeric(out$max_r2a %||% NA_real_)
}

prediction_call <- function(args) {
  need_packages("pmsampsize")
  quietly(do.call(pmsampsize::pmsampsize, args))
}

# The criteria's table, in plain words.
prediction_criteria <- function(out, outcome) {
  table <- out$results_table
  rows <- grep("^Criteria", rownames(table))
  labels <- switch(outcome,
    continuous = c("Little overfitting: expected shrinkage of the predictor effects", "A small difference (0.05) between the apparent and adjusted R-squared",
      "A precise estimate of the residual SD", "A precise estimate of the mean outcome"),
    c("Little overfitting: expected shrinkage of the predictor effects", "A small difference (0.05) between the apparent and adjusted Nagelkerke R-squared",
      if (identical(outcome, "survival")) "A precise estimate (within 0.05) of the outcome risk at the time point" else "A precise estimate (within 0.05) of the overall outcome risk"))
  data.frame(criterion = labels[seq_along(rows)], n = as.numeric(table[rows, "Samp_size"]),
    shrinkage = as.numeric(table[rows, "Shrinkage"]), stringsAsFactors = FALSE)
}

run_prediction_model <- function(spec, seed) {
  started <- Sys.time()
  args <- prediction_args(spec)
  out <- call_backend("pmsampsize", prediction_call(args))
  outcome <- prediction_outcome(spec)
  n <- as.numeric(out$sample_size)
  criteria <- prediction_criteria(out, outcome)
  prediction <- list(
    outcome = outcome,
    n = n,
    criteria = criteria,
    binding = criteria$criterion[which.max(criteria$n)],
    parameters = as.integer(spec$population$parameters),
    shrinkage = as.numeric(out$final_shrinkage %||% args$shrinkage),
    target_shrinkage = args$shrinkage,
    cox_snell_r2 = as.numeric(out$rsquared %||% NA_real_),
    nagelkerke_r2 = as.numeric(out$nag_r2 %||% NA_real_),
    max_cox_snell_r2 = as.numeric(out$max_r2a %||% NA_real_),
    events = as.numeric(out$events %||% NA_real_),
    events_per_parameter = as.numeric(out$EPP %||% NA_real_),
    metric = spec$population$metric,
    c_statistic = spec$population$c_statistic %||% NA_real_,
    function_used = "pmsampsize::pmsampsize"
  )
  check <- data.frame(
    parameter = c("number of candidate predictor parameters passed to pmsampsize()", "shrinkage target passed (criterion 1)",
      "the final sample size is the largest criterion's"),
    specified = c(prediction$parameters, args$shrinkage, max(criteria$n)),
    recovered = c(as.numeric(out$parameters), as.numeric(out$results_table[1, "Shrinkage"]), n),
    stringsAsFactors = FALSE
  )
  check$ok <- abs(check$specified - check$recovered) < 1e-8
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
        seed = if (identical(spec$population$metric, "c_statistic")) prediction_defaults$seed else seed,
        nrep = NA_integer_,
        cores = NA_integer_,
        batch_size = NA_integer_,
        simulations = NA,
        backend = "pmsampsize",
        backend_function = "pmsampsize::pmsampsize",
        r_version = R.version.string,
        packages = package_versions(c("powerkit", "pmsampsize")),
        started = format(started, "%Y-%m-%d %H:%M:%S %Z"),
        run_time_seconds = as.numeric(difftime(Sys.time(), started, units = "secs"))
      )
    ),
    class = "powerkit_result"
  )
}

# The R script: the same pmsampsize() call, and a check that it reproduces
# powerkit's answer.
prediction_script <- function(spec, result) {
  args <- prediction_args(spec)
  call <- paste0("pmsampsize(", paste(sprintf("%s = %s", names(args), vapply(args, r_code, character(1))), collapse = ", "), ")")
  c(
    script_header(spec, result, "pmsampsize", "pmsampsize::pmsampsize"),
    "library(pmsampsize)",
    "",
    "# The minimum sample size for developing the prediction model, by the",
    "# criteria of Riley and colleagues (pmsampsize's help, Details).",
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

prediction_design_description <- function(spec, label, levels) {
  pr <- prediction_args(spec)
  outcome <- prediction_outcome(spec)
  pop <- spec$population
  performance <- switch(pop$metric, c_statistic = sprintf("a C-statistic of %s", format_number(pop$c_statistic)),
    cox_snell_r2 = sprintf("a Cox-Snell R-squared of %s", format_number(pop$cox_snell_r2)),
    nagelkerke_r2 = sprintf("a Nagelkerke R-squared of %s", format_number(pop$nagelkerke_r2)),
    r2 = sprintf("an R-squared of %s", format_number(pop$r2)))
  sprintf(
    "Minimum sample size for developing a prediction model of %s (%s outcome) with %d candidate predictor parameters and %s, by the criteria of Riley and colleagues (pmsampsize's pmsampsize(), shrinkage target %s)",
    label("Y"), switch(outcome, binary = "a yes/no", continuous = "a continuous", survival = "a time-to-event"), pr$parameters,
    performance, format_number(pr$shrinkage)
  )
}
