# Backend adapter: Bland-Altman limits of agreement between two methods of
# measurement (design "reliability", template "bland_altman").
#
# Each subject is measured by both methods, and the analysis is of their
# differences: the bias (mean difference) and the limits of agreement,
# bias plus and minus z SD (z = qnorm(1 - (1 - agree_level) / 2), 1.96 for
# 95% limits). The study shows agreement when both limits, judged by the
# outer ends of their confidence intervals, lie inside plus and minus the
# largest acceptable difference (the margin, Delta): an intersection-union
# test. The confidence intervals are two-sided 1 - alpha, as Bland and
# Altman (1999) and Lu et al. (2016) report them, so each outer end is a
# one-sided 1 - alpha / 2 bound.
#
#   mover          (the default) Spower simulates the analysis: each study's
#                  differences are drawn from a normal distribution with the
#                  bias and SD given, and analysed by SimplyAgree's
#                  agreement_limit() with MOVER confidence intervals for the
#                  limits (its default, loa_calc = "mover"). agreement_limit()'s
#                  alpha is the one-sided level of each outer end, so it is
#                  given alpha / 2.
#   bland_altman   the same, with Bland and Altman's approximate intervals
#                  (loa_calc = "blandaltman").
#   lu_formula     Lu et al.'s (2016) closed-form approximation,
#                  SimplyAgree's blandPowerCurve(): power 1 - beta1 - beta2
#                  from two noncentral t probabilities. It is offered
#                  because it is the published formula, instant, and the
#                  one SimplyAgree provides, but it does not match
#                  simulated studies of the analysis closely
#                  (docs/conventions.md, Departure 27), so the simulated
#                  analysis is the default.
#
# The differences are assumed normal, as the limits of agreement assume.

bland_altman_test <- function(spec) {
  identical(spec$design, "reliability") && identical(spec$template, "bland_altman")
}

bland_altman_defaults <- list(method = "mover", agree_level = 0.95)

bland_altman_inputs <- function(spec) {
  pop <- spec$population
  tt <- spec$target_test
  agree <- tt$agree_level %||% bland_altman_defaults$agree_level
  list(
    bias = pop$bias, sd = pop$sd_difference, margin = pop$margin,
    agree = agree, z = stats::qnorm(1 - (1 - agree) / 2),
    alpha = tt$alpha %||% 0.05,
    method = tt$method %||% bland_altman_defaults$method
  )
}

# SimplyAgree's name for the confidence intervals of the limits.
bland_altman_loa_calc <- function(method) if (identical(method, "bland_altman")) "blandaltman" else "mover"

# The experiment Spower runs: one study of n subjects, both methods'
# measurements of each (the second a standard normal score, the first that
# plus a difference drawn from N(bias, sd^2)), analysed by
# SimplyAgree::agreement_limit(). TRUE when both outer confidence limits
# lie inside plus and minus the margin.
p_bland_altman <- function(n, bias, sd, margin, agree, alpha, loa_calc = "mover") {
  y <- stats::rnorm(n)
  data <- data.frame(x = y + stats::rnorm(n, bias, sd), y = y)
  loa <- SimplyAgree::agreement_limit(x = "x", y = "y", data = data, loa_calc = loa_calc,
    agree.level = agree, alpha = alpha / 2)$loa
  loa$lower_loa_ci > -margin && loa$upper_loa_ci < margin
}

# Studies (of nrep) that show agreement, at n subjects.
bland_altman_count <- function(inputs, n, nrep, seed) {
  args <- list(n = n, bias = inputs$bias, sd = inputs$sd, margin = inputs$margin, agree = inputs$agree,
    alpha = inputs$alpha, loa_calc = bland_altman_loa_calc(inputs$method))
  result <- spower_eval(as.name("p_bland_altman"), args, nrep, 0.05, seed)
  round(result$power * nrep)
}

# Lu et al.'s approximation, from SimplyAgree::blandPowerCurve(), which can
# return a negative power (1 - beta1 - beta2 below 0); it reports those as
# 0, and so does powerkit.
bland_altman_lu_power <- function(inputs, n) {
  out <- SimplyAgree::blandPowerCurve(samplesizes = n, mu = inputs$bias, SD = inputs$sd, delta = inputs$margin,
    conf.level = 1 - inputs$alpha, agree.level = inputs$agree)
  min(max(as.numeric(out$power), 0), 1)
}

bland_altman_function <- function(inputs) {
  if (identical(inputs$method, "lu_formula")) {
    return("SimplyAgree::blandPowerCurve() (Lu et al.'s 2016 approximation)")
  }
  sprintf("Spower::Spower(p_bland_altman()) (SimplyAgree::agreement_limit(loa_calc = \"%s\") on each simulated study)",
    bland_altman_loa_calc(inputs$method))
}

bland_altman_backend <- function(spec, seed = NULL) {
  inputs <- bland_altman_inputs(spec)
  min_n <- minimum_n(spec)
  common <- list(
    name = "SimplyAgree",
    n_step = 1,
    exact_min_n = min_n,
    sensitivity = NULL,
    check_run = function() bland_altman_check_run(inputs, seed)
  )
  if (identical(inputs$method, "lu_formula")) {
    power_at <- function(n) call_backend("SimplyAgree", bland_altman_lu_power(inputs, n))
    return(c(common, list(
      packages = "SimplyAgree",
      methods = "exact",
      default_method = "exact",
      functions = c(exact = bland_altman_function(inputs)),
      exact_power = power_at,
      bracket_power = power_at,
      simulate = NULL
    )))
  }
  c(common, list(
    packages = c("SimplyAgree", "Spower", "SimDesign"),
    methods = "simulation",
    default_method = "simulation",
    functions = c(simulation = bland_altman_function(inputs)),
    simulate = function(n, nrep, seed, cores) {
      simulate_in_chunks(nrep, seed, cores, function(k, chunk_seed) bland_altman_count(inputs, n, k, chunk_seed))
    }
  ))
}

# Check run: one large study drawn as the experiment draws them gives back
# the bias and the SD of the differences, and its upper limit of agreement
# (mean plus z SD) is the population's.
bland_altman_check_run <- function(inputs, seed) {
  n <- check_run_n()
  d <- with_seed(seed %||% 1L, {
    y <- stats::rnorm(n)
    (y + stats::rnorm(n, inputs$bias, inputs$sd)) - y
  })
  limit <- inputs$bias + inputs$z * inputs$sd
  upper <- mean(d) + inputs$z * stats::sd(d)
  data.frame(
    parameter = c("bias (mean difference, method 1 minus method 2)", "SD of the differences",
      "upper limit of agreement (bias + z SD)"),
    specified = c(inputs$bias, inputs$sd, limit),
    recovered = c(mean(d), stats::sd(d), upper),
    ok = c(
      abs(mean(d) - inputs$bias) < 5 * inputs$sd / sqrt(n),
      abs(stats::sd(d) - inputs$sd) < 5 * inputs$sd / sqrt(2 * n),
      abs(upper - limit) < 5 * inputs$sd * sqrt(1 / n + inputs$z^2 / (2 * n))
    )
  )
}

check_bland_altman <- function(spec) {
  pop <- spec$population
  problems <- character()
  if (is.null(pop$bias) || is.null(pop$sd_difference) || is.null(pop$margin)) {
    return(problems)
  }
  inputs <- bland_altman_inputs(spec)
  # A limit exactly at the margin is allowed: power is then alpha / 2 at
  # any n, the size check of test-validation-agreement.R. Beyond it (by
  # more than rounding), power falls towards 0 as n grows.
  if (abs(inputs$bias) + inputs$z * inputs$sd > inputs$margin * (1 + 1e-8)) {
    problems <- c(problems, sprintf(paste0(
      "With a bias of %s and an SD of the differences of %s, the %s%% limits of agreement themselves reach %s, ",
      "outside the largest acceptable difference ('population > margin', %s): no sample size can show agreement. ",
      "Check the margin, or whether the methods can be expected to agree this closely."),
      format_number(inputs$bias), format_number(inputs$sd), format_number(100 * inputs$agree),
      format_number(signif(abs(inputs$bias) + inputs$z * inputs$sd, 3)), format_number(signif(inputs$margin, 3))))
  }
  if (identical(inputs$method, "lu_formula") && identical(spec$options$method, "simulation")) {
    problems <- c(problems, "Lu et al.'s formula is not simulated; choose 'mover' or 'bland_altman' in 'target_test > method' to simulate the analysis, or remove 'options > method'.")
  }
  if (!identical(inputs$method, "lu_formula") && identical(spec$options$method, "exact")) {
    problems <- c(problems, "The limits of agreement are simulated (no formula gives their power exactly); remove 'options > method', or choose Lu et al.'s approximation ('target_test > method' \"lu_formula\").")
  }
  problems
}

bland_altman_design_description <- function(spec, label) {
  inputs <- bland_altman_inputs(spec)
  sprintf(paste0(
    "Bland-Altman limits of agreement for %s (method 1 minus method 2): %s%% limits, bias %s and SD of the differences %s, ",
    "agreement shown when both limits' %s%% confidence intervals lie within plus and minus %s (%s)"),
    label("Y"), format_number(100 * inputs$agree), format_number(inputs$bias), format_number(inputs$sd),
    format_number(100 * (1 - inputs$alpha)), format_number(inputs$margin),
    switch(inputs$method, mover = "MOVER confidence intervals, simulated",
      bland_altman = "Bland and Altman's confidence intervals, simulated",
      lu_formula = "Lu et al.'s approximation"))
}

# The R script: the same simulation with Spower and agreement_limit(), in
# powerkit's batches, so it reproduces the run's counts; or Lu et al.'s
# formula at each size.
bland_altman_script <- function(spec, result) {
  inputs <- bland_altman_inputs(spec)
  goal <- spec$goal
  prov <- result$provenance
  shared <- c(
    sprintf("bias <- %s # expected mean difference, method 1 minus method 2", r_code(inputs$bias)),
    sprintf("sd_difference <- %s # expected SD of the differences", r_code(inputs$sd)),
    sprintf("margin <- %s # largest acceptable difference: both limits must lie within plus and minus this", r_code(inputs$margin)),
    sprintf("agree_level <- %s # the share of differences the limits of agreement cover", r_code(inputs$agree)),
    "# alpha: each limit's confidence interval is two-sided 1 - alpha."
  )
  if (identical(inputs$method, "lu_formula")) {
    return(c(
      script_header(spec, result, "SimplyAgree", "SimplyAgree::blandPowerCurve"),
      "library(SimplyAgree)",
      "",
      "# Inputs ----",
      goal_inputs(spec, result),
      shared,
      "",
      "# Lu et al.'s (2016) approximation; a negative power is reported as 0.",
      "power_at <- function(n_total) {",
      "  power <- blandPowerCurve(samplesizes = n_total, mu = bias, SD = sd_difference, delta = margin,",
      "    conf.level = 1 - alpha, agree.level = agree_level)$power",
      "  min(max(power, 0), 1)",
      "}",
      "",
      pwr_goal_section(spec, result),
      comparison_section()
    ))
  }
  c(
    script_header(spec, result, "SimplyAgree", "Spower::Spower, SimplyAgree::agreement_limit"),
    "library(Spower)",
    "library(SimplyAgree)",
    "",
    "# Inputs ----",
    sprintf("alpha <- %s # significance level", r_code(inputs$alpha)),
    shared,
    switch(goal$type,
      sample_size = sprintf("target_power <- %s # target probability of showing agreement", r_code(goal$power)),
      power = sprintf("n_total <- %s # subjects measured by both methods", r_code(goal$n))),
    sprintf("replications <- %s # simulated studies per sample size", r_code(prov$nrep)),
    sprintf("seed <- %s # powerkit's seed for this run", r_code(prov$seed)),
    "",
    "# One simulated study: each subject measured by both methods, the",
    "# differences normal with the bias and SD above, analysed by",
    sprintf("# agreement_limit() with %s confidence intervals. Its alpha is the",
      if (identical(inputs$method, "bland_altman")) "Bland and Altman's" else "MOVER"),
    "# one-sided level of each outer limit, so it is given alpha / 2.",
    "p_bland_altman <- function(n, bias, sd, margin, agree, alpha) {",
    "  y <- rnorm(n)",
    "  data <- data.frame(x = y + rnorm(n, bias, sd), y = y)",
    sprintf("  loa <- agreement_limit(x = \"x\", y = \"y\", data = data, loa_calc = \"%s\",", bland_altman_loa_calc(inputs$method)),
    "    agree.level = agree, alpha = alpha / 2)$loa",
    "  loa$lower_loa_ci > -margin && loa$upper_loa_ci < margin",
    "}",
    "",
    "# One batch: studies showing agreement, and studies run.",
    "run_batch <- function(batch_n, batch_replications, batch_seed) {",
    "  set.seed(batch_seed)",
    "  # Spower reads its experiment's arguments unevaluated, so each is a name.",
    "  result <- Spower(p_bland_altman(n = batch_n, bias = bias, sd = sd_difference, margin = margin,",
    "    agree = agree_level, alpha = alpha), replications = batch_replications, parallel = FALSE, verbose = FALSE)",
    "  c(round(result$power * batch_replications), batch_replications)",
    "}",
    "",
    batch_section(result, "Spower()"),
    simulation_goal_section(spec, result, 1)
  )
}
