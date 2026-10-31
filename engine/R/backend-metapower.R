# Backend adapter: a planned meta-analysis, via metapower.
#
#   average effect     meta_analysis/mean_effect: the z test of the average
#                      effect size of k studies of the same size, under the
#                      fixed-effect model or the random-effects model,
#                      metapower::mpower() (Griffin, citation("metapower")):
#                      Hedges and Pigott's (2001) approach as set out by
#                      Valentine, Pigott and Rothstein (2010), with Jackson
#                      and Turner's (2017) method for the random-effects
#                      model, which allows for the between-study variance
#                      being estimated. Heterogeneity is given as I-squared.
#
# n is the number of studies (k). metapower takes the effect as Cohen's d
# or r; for r it works on Fisher's z, which it rounds to two decimals
# (Known difference 9 in docs/conventions.md, sized in
# test-backend-metapower.R). Its power for the test of heterogeneity
# (homogen_power()) disagrees with simulation and is not used
# (docs/upstream/metapower-homogeneity.R).

metapower_backend <- function(spec, seed = NULL) {
  inputs <- metapower_inputs(spec)
  power_at <- function(n) metapower_power(inputs, n)
  list(
    name = "metapower",
    packages = "metapower",
    methods = "exact",
    default_method = "exact",
    functions = c(exact = "metapower::mpower"),
    n_step = 1,
    exact_min_n = minimum_n(spec),
    exact_power = power_at,
    bracket_power = power_at,
    simulate = NULL,
    sensitivity = NULL,
    check_run = function() metapower_check_run(spec, inputs)
  )
}

# The arguments mpower() is given. Power is the same for an effect and its
# mirror image, so the size of the effect is passed; a one-sided test runs
# in the direction of the effect (validate_spec() refuses the other).
metapower_inputs <- function(spec) {
  pop <- spec$population
  tt <- spec$target_test
  list(
    effect_size = abs(pop$effect),
    study_size = pop$study_size,
    i2 = pop$i2,
    es_type = pop$metric,
    test_type = if (identical(tt$alternative %||% "two_sided", "two_sided")) "two-tailed" else "one-tailed",
    p = tt$alpha,
    model = tt$model %||% "random"
  )
}

metapower_args <- function(inputs, n) {
  list(
    effect_size = inputs$effect_size, study_size = inputs$study_size, k = n, i2 = inputs$i2,
    es_type = inputs$es_type, test_type = inputs$test_type, p = inputs$p
  )
}

metapower_output <- function(inputs, n) {
  call_backend("metapower", quietly(do.call(metapower::mpower, metapower_args(inputs, n))))
}

metapower_power <- function(inputs, n) {
  out <- metapower_output(inputs, n)$power
  if (identical(inputs$model, "fixed")) out$fixed_power else out$random_power
}

# Check run: no data are simulated, so the check confirms metapower uses
# the effect, the study size and the heterogeneity the spec gives, and
# that the fixed-effect power is the z test of Valentine, Pigott and
# Rothstein's (2010) equations 4 to 7 for that variance.
metapower_check_run <- function(spec, inputs) {
  k <- 10
  out <- metapower_output(inputs, k)
  row <- function(parameter, specified, passed) {
    data.frame(parameter = parameter, specified = specified, recovered = passed,
               ok = isTRUE(all.equal(specified, passed, tolerance = 1e-6)))
  }
  effect <- if (identical(inputs$es_type, "r")) round(atanh(inputs$effect_size), 2) else inputs$effect_size
  crit <- stats::qnorm(1 - if (identical(inputs$test_type, "two-tailed")) inputs$p / 2 else inputs$p)
  ncp <- out$effect_size / sqrt(out$variance / k)
  z_power <- stats::pnorm(ncp - crit) + if (identical(inputs$test_type, "two-tailed")) stats::pnorm(-crit - ncp) else 0
  rbind(
    row(if (identical(inputs$es_type, "r")) "Fisher's z of r, as metapower rounds it" else "Cohen's d passed to metapower",
        effect, out$effect_size),
    row("participants in a typical study (study_size)", inputs$study_size, out$study_size),
    row("heterogeneity, I-squared (i2)", inputs$i2, out$i2),
    row("fixed-effect power at 10 studies: the z test for metapower's sampling variance", z_power, out$power$fixed_power)
  )
}

# The standalone script: metapower's own call, with the inputs powerkit
# used (export_script()). n_total in the shared goal section is the number
# of studies.
metapower_script <- function(spec, result) {
  inputs <- metapower_inputs(spec)
  goal <- spec$goal
  c(
    script_header(spec, result, "metapower", "metapower::mpower"),
    "library(metapower)",
    "",
    "# Inputs ----",
    sprintf("effect_size <- %s # the average effect, as %s (its size: the test is symmetric)",
      r_code(inputs$effect_size), if (identical(inputs$es_type, "r")) "r" else "Cohen's d"),
    sprintf("es_type <- %s", r_code(inputs$es_type)),
    sprintf("study_size <- %s # participants in a typical study%s", r_code(inputs$study_size),
      if (identical(inputs$es_type, "d")) " (both groups together, split equally)" else ""),
    sprintf("i2 <- %s # heterogeneity, I-squared", r_code(inputs$i2)),
    sprintf("test_type <- %s", r_code(inputs$test_type)),
    sprintf("alpha <- %s", r_code(inputs$p)),
    sprintf("model <- %s # %s", r_code(inputs$model),
      if (identical(inputs$model, "fixed")) "the fixed-effect model" else "the random-effects model"),
    switch(
      goal$type,
      sample_size = sprintf("target_power <- %s", r_code(goal$power)),
      power = sprintf("n_total <- %s # the number of studies (k)", r_code(goal$n))
    ),
    "# metapower's calculations draw no random numbers, so powerkit's seed isn't used.",
    "",
    "# Power of the test of the average effect with k studies.",
    "power_at <- function(k) {",
    "  out <- mpower(effect_size = effect_size, study_size = study_size, k = k, i2 = i2,",
    "    es_type = es_type, test_type = test_type, p = alpha)$power",
    "  if (model == \"fixed\") out$fixed_power else out$random_power",
    "}",
    "",
    "# Below, n means the number of studies (k).",
    pwr_goal_section(spec, result),
    comparison_section()
  )
}

# The design line of the script header for a meta-analysis.
meta_design_description <- function(spec, label) {
  inputs <- metapower_inputs(spec)
  sprintf(
    "%s meta-analysis of %s, the %s of the average effect (%s) in studies of %s participants with I-squared %s%s",
    if (identical(inputs$model, "fixed")) "fixed-effect" else "random-effects",
    label("Y"), if (hartung_knapp_test(spec)) "Hartung-Knapp test" else "z test",
    if (identical(inputs$es_type, "r")) "r" else "Cohen's d",
    format_number(inputs$study_size), format_number(inputs$i2),
    if (identical(inputs$test_type, "one-tailed")) ", one-sided" else ""
  )
}

# The Hartung-Knapp test (target_test > test "hartung_knapp", the default
# for the random-effects model; Departure 18): no package computes its
# power, so it is simulated with Spower and powerkit's own experiment,
# p_meta_hk(), which draws k study estimates and fits metafor's
# rma(method = "DL", test = "knha"): DerSimonian and Laird's tau^2, the
# Hartung-Knapp-Sidik-Jonkman variance and a t test with k - 1 df
# (IntHout, Ioannidis & Borm, 2014). The studies follow the same model as
# metapower's: each estimate has the sampling variance v of a typical
# study (Cohen's d from two equal groups, or Fisher's z of r, exact) and
# the true effects vary with tau^2 = I^2 v / (1 - I^2).

hartung_knapp_test <- function(spec) {
  identical(spec$design, "meta_analysis") && !identical(spec$target_test$model, "fixed") &&
    !identical(spec$target_test$test, "z")
}

# The average effect on the analysis scale (Fisher's z for r) and a
# typical study's sampling variance.
meta_study_model <- function(spec) {
  pop <- spec$population
  n <- pop$study_size
  if (identical(pop$metric, "r")) {
    theta <- atanh(pop$effect)
    v <- 1 / (n - 3)
  } else {
    theta <- pop$effect
    v <- 4 / n + pop$effect^2 / (2 * n)
  }
  list(theta = theta, v = v, tau2 = pop$i2 * v / (1 - pop$i2))
}

# k studies' estimates: true effects from N(theta, tau2), each estimated
# with sampling variance v.
meta_estimates <- function(k, theta, v, tau2) {
  data.frame(yi = stats::rnorm(k, stats::rnorm(k, theta, sqrt(tau2)), sqrt(v)), vi = v)
}

# Spower experiment: the p-value of the Hartung-Knapp test of the average
# effect (two-sided, or one-sided from its t statistic with k - 1 df).
p_meta_hk <- function(k, theta, v, tau2, alternative = "two.sided") {
  studies <- meta_estimates(k, theta, v, tau2)
  fit <- metafor::rma(yi = studies$yi, vi = studies$vi, method = "DL", test = "knha")
  if (identical(alternative, "two.sided")) {
    fit$pval
  } else {
    stats::pt(fit$zval, k - 1, lower.tail = identical(alternative, "less"))
  }
}

meta_hk_backend <- function(spec, seed = NULL) {
  model <- meta_study_model(spec)
  alternative <- switch(spec$target_test$alternative %||% "two_sided",
    two_sided = "two.sided", greater = "greater", less = "less")
  args <- function(k) list(k = k, theta = model$theta, v = model$v, tau2 = model$tau2, alternative = alternative)
  list(
    name = "Spower",
    packages = c("Spower", "SimDesign", "metafor"),
    methods = "simulation",
    default_method = "simulation",
    functions = c(simulation = "Spower::Spower(p_meta_hk()) (metafor::rma(method = \"DL\", test = \"knha\"), the Hartung-Knapp test)"),
    n_step = 1,
    exact_min_n = minimum_n(spec),
    simulate = function(n, nrep, seed, cores) {
      simulate_in_chunks(nrep, seed, cores, function(chunk, chunk_seed) {
        result <- spower_eval(as.name("p_meta_hk"), args(n), chunk, spec$target_test$alpha, chunk_seed)
        round(result$power * chunk)
      })
    },
    sensitivity = NULL,
    check_run = function() meta_hk_check_run(spec, model, seed)
  )
}

# Check run: many simulated studies recover the average effect and the
# spread of their estimates (sampling variance plus tau^2).
meta_hk_check_run <- function(spec, model, seed) {
  k <- check_run_n()
  studies <- with_seed(seed %||% 1, meta_estimates(k, model$theta, model$v, model$tau2))
  total <- model$v + model$tau2
  rbind(
    check_run_rows(if (identical(spec$population$metric, "r")) "average effect (Fisher's z of r)" else "average effect (Cohen's d)",
                   model$theta, mean(studies$yi), sqrt(total / k)),
    check_run_rows("variance of the studies' estimates (sampling variance plus tau-squared)",
                   total, stats::var(studies$yi), total * sqrt(2 / (k - 1)))
  )
}

# The standalone script for the Hartung-Knapp test: Spower with the same
# experiment, written out, and metafor (export_script()).
meta_hk_script <- function(spec, result) {
  model <- meta_study_model(spec)
  alternative <- switch(spec$target_test$alternative %||% "two_sided",
    two_sided = "two.sided", greater = "greater", less = "less")
  c(
    script_header(spec, result, "Spower", result$provenance$backend_function),
    "library(Spower)",
    "library(metafor)",
    "",
    "# Inputs ----",
    sprintf("theta <- %s # the average effect%s", r_code(model$theta),
      if (identical(spec$population$metric, "r")) sprintf(", as Fisher's z of r = %s", format(spec$population$effect)) else " (Cohen's d)"),
    sprintf("v <- %s # a typical study's sampling variance (%s)", r_code(model$v),
      if (identical(spec$population$metric, "r")) "1 / (n - 3)" else "4 / n + d^2 / (2 n), two equal groups of n / 2"),
    sprintf("tau2 <- %s # between-study variance: I-squared %s times v / (1 - I-squared)", r_code(model$tau2), format(spec$population$i2)),
    sprintf("alternative <- %s", r_code(alternative)),
    "# n_total below is the number of studies (k).",
    goal_inputs(spec, result),
    "",
    "# k studies' estimates, and the p-value of the Hartung-Knapp test of their",
    "# average (DerSimonian and Laird's tau^2; t test with k - 1 df).",
    "p_meta_hk <- function(k, theta, v, tau2, alternative = \"two.sided\") {",
    "  yi <- rnorm(k, rnorm(k, theta, sqrt(tau2)), sqrt(v))",
    "  fit <- rma(yi = yi, vi = rep(v, k), method = \"DL\", test = \"knha\")",
    "  if (alternative == \"two.sided\") fit$pval else pt(fit$zval, k - 1, lower.tail = alternative == \"less\")",
    "}",
    "",
    "# One batch of simulated meta-analyses: rejections and analysable ones.",
    "run_batch <- function(batch_n, batch_replications, batch_seed) {",
    "  set.seed(batch_seed) # Spower draws its own seeds from R's random-number generator",
    "  result <- Spower(",
    "    p_meta_hk(k = batch_n, theta = theta, v = v, tau2 = tau2, alternative = alternative),",
    "    sig.level = alpha,",
    "    replications = batch_replications,",
    "    parallel = FALSE,",
    "    verbose = FALSE",
    "  )",
    "  c(round(result$power * batch_replications), batch_replications)",
    "}",
    "",
    batch_section(result, "Spower()"),
    simulation_goal_section(spec, result, 1),
    comparison_section()
  )
}
