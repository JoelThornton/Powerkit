# Backend adapter: the Bayes factor one-way ANOVA (equal groups), by exact
# calculation, via BayesFactor.
#
# The Bayes factor is BayesFactor's one-way ANOVA Bayes factor (Rouder,
# Morey, Speckman & Province, 2012, the reference in anovaBF()'s help): a
# Cauchy prior with scale r on the standardised group effects. For a
# balanced one-way design it depends on the data only through the F
# statistic, the group size and the number of groups, and BayesFactor
# computes it from them with oneWayAOV.Fstat(F, N, J, rscale), which gives
# the same value as anovaBF() on the data (checked in the check run and in
# test-backend-bayes-anova.R). JASP's Bayesian ANOVA calls BayesFactor with
# an r scale of 0.5 for fixed effects ("r scale fixed effects", default
# 0.5, jaspAnova's inst/qml/common/bayesian/AdditionalOptions.qml), so 0.5
# is powerkit's default too, and the answer matches JASP's.
#
# BF10 rises with F, so BF10 reaches the threshold exactly when F reaches
# the F at which BF10 equals it. Power is the probability of that F: the
# noncentral F with k - 1 and n - k df and noncentrality f^2 n, Cohen's f
# from the group means and the common SD, as for the F test (pwr's
# pwr.anova.test()). No random numbers are drawn.

bfanova_test <- function(spec) {
  bayes_factor_test(spec) && identical(spec$design, "factorial_anova") && identical(spec$template, "oneway_between")
}

bfanova_defaults <- list(prior_scale = 0.5)

bfanova_inputs <- function(spec) {
  pop <- spec$population
  means <- as.numeric(unlist(pop$means))
  sd <- as.numeric(unlist(pop$sd))
  list(
    means = means, sd = sd, k = length(means),
    f = sqrt(mean((means - mean(means))^2)) / sd,
    threshold = bayes_threshold(spec),
    prior_scale = spec$target_test$prior_scale %||% bfanova_defaults$prior_scale
  )
}

# log BF10 for the F statistic(s) `f_stat` with n per group.
bfanova_log_bf10 <- function(f_stat, n_group, inputs) {
  vapply(f_stat, function(x) {
    BayesFactor::oneWayAOV.Fstat(x, N = n_group, J = inputs$k, rscale = inputs$prior_scale, simple = FALSE)[["bf"]]
  }, numeric(1))
}

# The F at which log BF10 equals `log_target`, or NA when no F reaches it
# (BF10 at F = 0 is already above it, for evidence for no effect).
bfanova_f_at <- function(log_target, n_group, inputs) {
  g <- function(x) bfanova_log_bf10(x, n_group, inputs) - log_target
  if (g(0) >= 0) return(NA_real_)
  upper <- 10
  while (g(upper) < 0) upper <- upper * 2
  stats::uniroot(g, c(0, upper), tol = 1e-10)$root
}

bfanova_df <- function(inputs, n) c(inputs$k - 1, n - inputs$k)

# The chance of strong evidence for an effect at total n, for an effect of
# size f (the spec's, by default).
bfanova_power <- function(inputs, n, f = inputs$f) {
  f_star <- bfanova_f_at(log(inputs$threshold), n / inputs$k, inputs)
  if (is.na(f_star)) return(1)
  df <- bfanova_df(inputs, n)
  stats::pf(f_star, df[1], df[2], ncp = f^2 * n, lower.tail = FALSE)
}

bfanova_backend <- function(spec, seed = NULL) {
  inputs <- bfanova_inputs(spec)
  step <- valid_n_step(spec)
  power_at <- function(n) call_backend("BayesFactor", bfanova_power(inputs, n))
  list(
    name = "BayesFactor",
    packages = "BayesFactor",
    methods = "exact",
    default_method = "exact",
    functions = c(exact = "BayesFactor::oneWayAOV.Fstat"),
    n_step = step,
    exact_min_n = step * ceiling(max(2 * inputs$k, minimum_n(spec)) / step),
    exact_power = power_at,
    bracket_power = power_at,
    simulate = NULL,
    sensitivity = NULL,
    check_run = function() bfanova_check_run(spec, inputs)
  )
}

# No effect: the central F. Strong evidence for no effect is BF10 at most
# 1 / threshold (F at most the F where BF10 is that); misleading evidence is
# BF10 reaching the threshold.
bfanova_null_side <- function(inputs, n) {
  df <- bfanova_df(inputs, n)
  f_null <- bfanova_f_at(-log(inputs$threshold), n / inputs$k, inputs)
  list(
    evidence_for_null = if (is.na(f_null)) 0 else stats::pf(f_null, df[1], df[2]),
    misleading_evidence = bfanova_power(inputs, n, f = 0)
  )
}

bfanova_hypotheses_words <- function(inputs) {
  sprintf("all %d group means equal against not all equal", inputs$k)
}

# Check run: anovaBF() on a data set whose groups have exactly the spec's
# means and SD (20 per group) gives the Bayes factor oneWayAOV.Fstat() gives
# from its F, and the effect size is recovered from the data.
bfanova_check_run <- function(spec, inputs) {
  n_group <- 20
  base <- stats::qnorm(seq(0.5, n_group - 0.5) / n_group)
  base <- (base - mean(base)) / stats::sd(base)
  data <- data.frame(
    group = factor(rep(seq_len(inputs$k), each = n_group)),
    y = as.vector(vapply(inputs$means, function(m) m + inputs$sd * base, numeric(n_group)))
  )
  f_stat <- stats::anova(stats::lm(y ~ group, data))[["F value"]][1]
  package <- call_backend("BayesFactor", quietly(BayesFactor::anovaBF(
    y ~ group, data = data, rscaleFixed = inputs$prior_scale, progress = FALSE
  )))
  from_f <- bfanova_log_bf10(f_stat, n_group, inputs)
  group_means <- tapply(data$y, data$group, mean)
  recovered_f <- sqrt(mean((group_means - mean(group_means))^2)) / sqrt(mean(tapply(data$y, data$group, stats::var)))
  row <- function(parameter, spec_value, got, tolerance = 1e-6) {
    data.frame(parameter = parameter, specified = spec_value, recovered = got, ok = isTRUE(all.equal(spec_value, got, tolerance = tolerance)))
  }
  rbind(
    row("Cohen's f from the group means and SD (20 per group, exactly those means and SD)", inputs$f, recovered_f),
    row("log BF10 for that data set: anovaBF() against oneWayAOV.Fstat() from its F", BayesFactor::extractBF(package, logbf = TRUE)$bf[1], from_f),
    row("r scale of the Cauchy prior on the fixed effects (rscaleFixed)", inputs$prior_scale, inputs$prior_scale)
  )
}

# Spec checks for the Bayes factor ANOVA: one SD, and no Bayes factor
# setting that belongs to another test.
check_bayes_anova <- function(spec) {
  problems <- character()
  if (length(unlist(spec$population$sd)) != 1) {
    problems <- c(problems, "The Bayes factor ANOVA takes one SD for every group ('population > sd'), as JASP's Bayesian ANOVA assumes.")
  }
  if (!identical(spec$target_test$alternative %||% "two_sided", "two_sided")) {
    problems <- c(problems, "The Bayes factor ANOVA tests whether all the group means are equal; it has no direction, so remove 'target_test > alternative'.")
  }
  if (!is.null(spec$population$effect_sd)) {
    problems <- c(problems, "'population > effect_sd' isn't used by the Bayes factor ANOVA: the effect is the group means given.")
  }
  problems
}

# The R script for the Bayes factor ANOVA: the same calculation at each
# size powerkit computed (export_script()).
bfanova_script <- function(spec, result) {
  inputs <- bfanova_inputs(spec)
  c(
    script_header(spec, result, "BayesFactor", "BayesFactor::oneWayAOV.Fstat"),
    "library(BayesFactor)",
    "",
    "# Inputs ----",
    sprintf("means <- %s # the expected group means", r_code(inputs$means)),
    sprintf("sd <- %s # the SD within each group", r_code(inputs$sd)),
    sprintf("threshold <- %s # strong evidence: BF10 at least this", r_code(inputs$threshold)),
    sprintf("rscale <- %s # r scale of the Cauchy prior on the fixed effects (JASP's default 0.5)", r_code(inputs$prior_scale)),
    bayes_goal_inputs(spec),
    "",
    "k <- length(means)",
    "f <- sqrt(mean((means - mean(means))^2)) / sd # Cohen's f",
    "# BF10 from the F statistic of a one-way ANOVA with n per group: the",
    "# value anovaBF(y ~ group, rscaleFixed = rscale) gives on the data.",
    "log_bf10 <- function(F, n) oneWayAOV.Fstat(F, N = n, J = k, rscale = rscale, simple = FALSE)[[\"bf\"]]",
    "# BF10 rises with F: the F at which it reaches the threshold, and the",
    "# chance of an F at least that large (the noncentral F).",
    "power_at <- function(n_total) {",
    "  n <- n_total / k",
    "  g <- function(F) log_bf10(F, n) - log(threshold)",
    "  if (g(0) >= 0) return(1)",
    "  upper <- 10",
    "  while (g(upper) < 0) upper <- upper * 2",
    "  f_star <- uniroot(g, c(0, upper), tol = 1e-10)$root",
    "  pf(f_star, k - 1, n_total - k, ncp = f^2 * n_total, lower.tail = FALSE)",
    "}",
    "",
    pwr_goal_section(spec, result),
    comparison_section()
  )
}

bfanova_design_description <- function(spec, label, levels) {
  inputs <- bfanova_inputs(spec)
  sprintf(
    "Bayes factor one-way ANOVA of %s across the groups of %s (%s): %s, BayesFactor's ANOVA Bayes factor with a Cauchy prior of r scale %s on the effects; strong evidence is BF10 of at least %s",
    label("Y"), label("A"), paste(levels("A"), collapse = ", "), bfanova_hypotheses_words(inputs),
    format_number(inputs$prior_scale), format_number(inputs$threshold)
  )
}
