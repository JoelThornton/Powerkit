# Effects that vary between studies (Kenny & Judd, 2019, refs.bib
# Kenny2019_heterogeneity): a t-test planned for a true effect that is not
# the same in every study, but varies around the planned effect mu with
# standard deviation tau (population > tau, in d or d_z units).
#
# A correlation follows McShane and Bockenholt (2014, Appendix B,
# refs.bib McShane2014_river): tau is on Fisher's z scale; see
# heterogeneity_adjustment_r().
#
# Kenny and Judd's formula (their "Power" section and appendix function
# pow_ad()): with heterogeneity the study's estimate has standard error
# sqrt(se0^2 + tau^2), where se0 is the usual one (sqrt(4 / N) for two equal
# groups). The test of the average effect then has
#   q            = se0 / sqrt(se0^2 + tau^2)
#   critical t   = q * t_crit(alpha, df)            (the "effective alpha")
#   noncentrality = mu / sqrt(se0^2 + tau^2)
# with the usual noncentral t and df. They note that a conventional power
# program gives the same answer when given the effective alpha and the
# adjusted noncentrality, and that is how it is computed here: pwr's own
# t-test power, with sig.level = the effective alpha and d = q * mu (which
# makes pwr's noncentrality mu / sqrt(se0^2 + tau^2)). With tau = 0, q = 1
# and this is exactly the card's usual pwr call.
#
# se0 for other designs, as in pwr's own noncentrality: sqrt(1 / n1 + 1 /
# n2) for two groups of any sizes, sqrt(1 / n) for one sample or pairs.
# Kenny and Judd write the two equal groups case; the others follow the
# same rule, and each is checked against an independent simulation that
# draws every study's true effect (test-heterogeneity.R).
#
# Two consequences the result states. Power can rise rather than fall with
# heterogeneity when the usual power is below one half (Kenny & Judd), and
# with no average effect a single study is significant more often than
# alpha (their "effective alpha"), because each study's own true effect is
# rarely exactly zero.

heterogeneity_templates <- c("independent_t", "one_sample_t", "paired_t", "correlation")

# The planned effect: d, d_z for pairs, r for a correlation.
heterogeneity_effect_field <- function(spec) {
  switch(spec$template, paired_t = "dz", correlation = "r", "d")
}

heterogeneity_test <- function(spec) {
  tau <- spec$population$tau
  identical(spec$design, "basic_test") && is.numeric(tau) && length(tau) == 1 && !is.na(tau) && tau > 0
}

# In validate_spec(): the t-tests by formula only, with equal SDs for
# Welch's test, and not with what plans for no effect or a margin.
heterogeneity_problems <- function(spec) {
  tau <- spec$population$tau
  # Meta-analysis and mediation have a 'tau' of their own.
  if (is.null(tau) || !identical(spec$design, "basic_test")) return(character())
  if (!isTRUE(spec$template %in% heterogeneity_templates)) {
    return("How much the effect varies between studies ('population > tau') is available for the t-tests and a correlation only.")
  }
  if (!is.numeric(tau) || length(tau) != 1 || is.na(tau) || tau < 0 || tau > 2) {
    return("How much the effect varies between studies ('population > tau') must be a standard deviation between 0 and 2 (in d, or on Fisher's z scale for a correlation).")
  }
  if (tau == 0) return(character())
  problems <- character()
  method <- spec$target_test$method %||% ""
  allowed <- if (identical(spec$template, "correlation")) c("", "pearson") else c("", "t_test", "student_t", "welch_t")
  if (!method %in% allowed) {
    problems <- c(problems, if (identical(spec$template, "correlation")) "Variation between studies is planned for Pearson's correlation test, not for rank correlations or Bayes factors."
      else "Variation between studies is planned for Student's or Welch's t-test, not for rank tests or Bayes factors.")
  }
  if (identical(spec$options$method, "simulation")) {
    problems <- c(problems, sprintf("Variation between studies is worked out by %s formula; remove 'options > method'.",
      if (identical(spec$template, "correlation")) "McShane and Bockenholt's" else "Kenny and Judd's"))
  }
  if (!is.null(spec$population$sd_ratio) && !isTRUE(all.equal(spec$population$sd_ratio, 1))) {
    problems <- c(problems, "Variation between studies is planned for two groups with equal SDs (an SD ratio of 1). Empty 'How much might the true effect vary between studies?', or give equal SDs.")
  }
  if (identical(spec$template, "independent_t") && identical(method, "welch_t") &&
      !isTRUE(all.equal(allocation_ratio(spec), 1))) {
    problems <- c(problems, paste("Variation between studies with Welch's test currently requires equal group sizes.",
      "The variation formula uses Student's degrees of freedom, which differ from Welch's for unequal groups.",
      "Use equal allocation or plan without between-study variation; do not change your intended analysis only to obtain a number."))
  }
  if (small_telescopes_test(spec)) {
    problems <- c(problems, "Small telescopes plans for a true effect of 0, so there is no variation between studies to allow for.")
  }
  if (!spec$goal$type %in% c("power", "sample_size", "sensitivity")) {
    problems <- c(problems, "Variation between studies gives power, the sample size or the smallest detectable effect.")
  }
  problems
}

# The usual standard error of d (or d_z) at total sample size n, and the
# test's degrees of freedom.
heterogeneity_se0 <- function(spec, n) {
  if (identical(spec$template, "independent_t")) {
    ratio <- allocation_ratio(spec)
    n1 <- round(n / (1 + ratio))
    return(list(se = sqrt(1 / n1 + 1 / (n - n1)), df = n - 2))
  }
  list(se = sqrt(1 / n), df = n - 1)
}

# Kenny and Judd's adjustment at n: q, the effective alpha, and the d
# that gives pwr their noncentrality.
heterogeneity_adjustment <- function(spec, n, mu = NULL) {
  if (identical(spec$template, "correlation")) return(heterogeneity_adjustment_r(spec, n, mu))
  tau <- spec$population$tau
  mu <- mu %||% spec$population[[heterogeneity_effect_field(spec)]]
  alpha <- spec$target_test$alpha %||% 0.05
  tails <- if (identical(spec$target_test$alternative %||% "two_sided", "two_sided")) 2 else 1
  base <- heterogeneity_se0(spec, n)
  q <- base$se / sqrt(base$se^2 + tau^2)
  critical <- q * stats::qt(1 - alpha / tails, base$df)
  list(q = q, effect = q * mu, alpha = tails * stats::pt(critical, base$df, lower.tail = FALSE),
    critical_t = critical, df = base$df)
}

# A correlation (McShane & Bockenholt, 2014, Appendix B): with
# heterogeneity the estimate's Fisher z has variance 1 / (n - 3) + tau^2,
# while the test's critical region is the usual one. pwr.r.test() works on
# Fisher's z: it compares z_r = atanh(r) + r / (2 (n - 1)) with the
# critical z_c = atanh(r_c), r_c from the t test's critical value, scaled
# by sqrt(n - 3). Scaling both by q = se0 / sqrt(se0^2 + tau^2) gives the
# power with heterogeneity, so pwr.r.test() is given the r whose z_r is
# q z_r, and the significance level whose z_c is q z_c (the effective
# alpha, as Kenny and Judd's for t). With tau = 0 both are unchanged.
heterogeneity_adjustment_r <- function(spec, n, mu = NULL) {
  tau <- spec$population$tau
  r <- mu %||% spec$population$r
  alpha <- spec$target_test$alpha %||% 0.05
  tails <- if (identical(spec$target_test$alternative %||% "two_sided", "two_sided")) 2 else 1
  df <- n - 2
  se0 <- 1 / sqrt(n - 3)
  q <- se0 / sqrt(se0^2 + tau^2)
  z_of <- function(x) atanh(x) + x / (2 * (n - 1))
  ttt <- stats::qt(alpha / tails, df, lower.tail = FALSE)
  zc <- atanh(sqrt(ttt^2 / (ttt^2 + df)))
  rc <- tanh(q * zc)
  critical <- sqrt(df * rc^2 / (1 - rc^2))
  target <- q * z_of(r)
  adjusted <- if (abs(target) < 1e-12) 0 else
    stats::uniroot(function(x) z_of(x) - target, sort(c(0, sign(target) * (1 - 1e-12))), tol = 1e-12)$root
  list(q = q, effect = adjusted, alpha = tails * stats::pt(critical, df, lower.tail = FALSE), critical_t = critical, df = df)
}

heterogeneity_backend <- function(spec, seed = NULL) {
  student <- spec
  student$target_test$method <- switch(spec$template, independent_t = "student_t", correlation = "pearson", "t_test")
  # The correlation's method is defined on Fisher's z (pwr.r.test()), at
  # every level of variation, none included.
  if (identical(spec$template, "correlation")) student$options$correlation_formula <- "fisher_z"
  inputs <- pwr_inputs(student)
  base_args <- inputs$args
  effect_field <- heterogeneity_effect_field(spec)
  power_with <- function(n, mu = NULL) {
    a <- heterogeneity_adjustment(spec, n, mu)
    adjusted <- inputs
    adjusted$alpha <- a$alpha
    adjusted$args <- function(m) {
      args <- base_args(m)
      args[[if (identical(spec$template, "correlation")) "r" else "d"]] <- a$effect
      args
    }
    pwr_power(adjusted, n)
  }
  power_at <- function(n) power_with(n)
  step <- valid_n_step(spec)
  list(
    name = "pwr",
    packages = "pwr",
    methods = "exact",
    default_method = "exact",
    functions = c(exact = if (identical(spec$template, "correlation")) {
      sprintf("%s::%s with McShane and Bockenholt's (2014) variation between studies (tau = %s on Fisher's z): sig.level = the effective alpha, r with Fisher's z scaled by q",
        inputs$package, inputs$fun, format(spec$population$tau))
    } else {
      sprintf("%s::%s with Kenny and Judd's (2019) adjustment for variation between studies (tau = %s): sig.level = the effective alpha, d = q * %s",
        inputs$package, inputs$fun, format(spec$population$tau), effect_field)
    }),
    n_step = step,
    exact_min_n = step * ceiling(max(minimum_n(spec), 4) / step),
    exact_power = power_at,
    bracket_power = power_at,
    simulate = NULL,
    # The smallest average effect with the target power at n.
    sensitivity = function(n, power) heterogeneity_sensitivity(spec, n, power, power_with),
    check_run = function() data.frame(parameter = "tau", specified = spec$population$tau,
      recovered = spec$population$tau, ok = TRUE)
  )
}

heterogeneity_sensitivity <- function(spec, n, target, power_with) {
  r <- identical(spec$template, "correlation")
  specified <- spec$population[[heterogeneity_effect_field(spec)]]
  sign <- if (identical(spec$target_test$alternative, "less") || isTRUE(specified < 0)) -1 else 1
  top <- if (r) 0.999 else 5
  f <- function(mu) power_with(n, sign * mu) - target
  if (f(0) >= 0) {
    abort_run(paste("The target chance is already reached with an average effect of zero because effects vary between studies.",
      "There is no positive smallest detectable average effect for this target. Use power at your fixed sample size",
      "and compare the variation assumptions; significance here does not establish a nonzero average effect."))
  }
  if (f(top) < 0) {
    abort_run(sprintf("No average effect up to %s reaches the target power at this n with this much variation between studies.", top))
  }
  found <- stats::uniroot(f, c(0, top), tol = 1e-8)$root
  list(effect = sign * found, effect_name = switch(spec$template, paired_t = "d_z", correlation = "r", "d"),
    effect_description = if (r) "the average correlation between studies" else "the average effect between studies, as Cohen's d (d_z for pairs)",
    power = power_with(n, sign * found))
}

# For the result: tau, and at the analysed n the chance a study is
# significant with no average effect (Kenny and Judd's effective alpha),
# and the power with no variation, for comparison.
heterogeneity_record <- function(spec, n = NULL) {
  if (!heterogeneity_test(spec) || is.null(n) || !is.numeric(n) || is.na(n)) return(NULL)
  record <- heterogeneity_record_at(spec, n)
  # What the range gives: the goal's own answer.
  record$range <- heterogeneity_range(spec, n)
  record$range_goal <- spec$goal$type
  record
}

# Small, medium and large variation: Kenny and Judd's (2019) 25% of a
# small, medium and large effect, d = 0.2, 0.5 and 0.8 (0.05, 0.125 and
# 0.20, their values) or r = .1, .3 and .5 (0.025, 0.075 and 0.125, close
# to Fisher's z for these sizes).
heterogeneity_levels <- function(spec) {
  values <- if (identical(spec$template, "correlation")) c(0.025, 0.075, 0.125) else c(0.05, 0.125, 0.20)
  c(none = 0, small = values[1], medium = values[2], large = values[3])
}

# The result's range: the goal's answer (power, the sample size or the
# smallest detectable average effect) with no, small, medium and large
# variation and with the value entered, so the cost of the assumption is
# shown rather than one answer that hides it.
heterogeneity_range <- function(spec, n) {
  levels <- heterogeneity_levels(spec)
  tau <- spec$population$tau
  if (!any(abs(levels - tau) < 1e-12)) levels <- c(levels, entered = tau)
  levels <- sort(levels)
  goal <- spec$goal
  rows <- lapply(names(levels), function(name) {
    s <- spec
    s$population$tau <- levels[[name]]
    backend <- heterogeneity_backend(s)
    value <- tryCatch(switch(goal$type,
      power = backend$exact_power(n),
      sample_size = search_n_exact(s, backend, goal$power)$n_required$n,
      sensitivity = backend$sensitivity(n, goal$power)$effect,
      NA_real_), powerkit_run_error = function(e) NA_real_)
    data.frame(level = name, tau = levels[[name]], entered = abs(levels[[name]] - tau) < 1e-12, value = value)
  })
  do.call(rbind, rows)
}

heterogeneity_record_at <- function(spec, n) {
  a <- heterogeneity_adjustment(spec, n)
  usual <- spec
  usual$population$tau <- NULL
  if (identical(spec$template, "independent_t")) usual$target_test$method <- "student_t"
  # The comparison isolates the variation between studies, so the
  # correlation without it is on Fisher's z too.
  if (identical(spec$template, "correlation")) usual$options$correlation_formula <- "fisher_z"
  inputs <- pwr_inputs(usual)
  list(tau = spec$population$tau, effective_alpha = a$alpha, q = a$q,
    power = heterogeneity_backend(spec)$exact_power(n), power_without = pwr_power(inputs, n), n = n,
    scale = if (identical(spec$template, "correlation")) "Fisher's z" else "d",
    source = if (identical(spec$template, "correlation")) "McShane & Bockenholt (2014)" else "Kenny & Judd (2019)")
}

# The R script: pwr with Kenny and Judd's adjustment, as above.
heterogeneity_script <- function(spec, result) {
  if (identical(spec$template, "correlation")) return(heterogeneity_script_r(spec, result))
  two <- identical(spec$template, "independent_t")
  ratio <- allocation_ratio(spec)
  mu <- if (identical(spec$template, "paired_t")) spec$population$dz else spec$population$d
  alternative <- pwr_alternative(spec$target_test$alternative %||% "two_sided")
  tails <- if (identical(alternative, "two.sided")) 2 else 1
  n <- spec$goal$n %||% result$n_required$n
  call <- if (two && isTRUE(all.equal(ratio, 1))) {
    sprintf("pwr::pwr.t.test(n = n / 2, d = q * mu, sig.level = effective_alpha, type = \"two.sample\", alternative = \"%s\")$power", alternative)
  } else if (two) {
    sprintf("pwr::pwr.t2n.test(n1 = round(n / (1 + %s)), n2 = n - round(n / (1 + %s)), d = q * mu, sig.level = effective_alpha, alternative = \"%s\")$power",
      format(ratio), format(ratio), alternative)
  } else {
    sprintf("pwr::pwr.t.test(n = n, d = q * mu, sig.level = effective_alpha, type = \"%s\", alternative = \"%s\")$power",
      if (identical(spec$template, "paired_t")) "paired" else "one.sample", alternative)
  }
  c(
    "# A t-test when the true effect varies between studies (Kenny & Judd, 2019):",
    "# the usual pwr call, given Kenny and Judd's effective alpha and adjusted effect.",
    sprintf("mu <- %s     # the average effect", format(mu)),
    sprintf("tau <- %s    # its SD between studies", format(spec$population$tau)),
    sprintf("alpha <- %s", format(spec$target_test$alpha %||% 0.05)),
    sprintf("n <- %s      # in total", format(n)),
    if (two) sprintf("se0 <- sqrt(1 / round(n / (1 + %s)) + 1 / (n - round(n / (1 + %s)))); df <- n - 2", format(ratio), format(ratio))
    else "se0 <- sqrt(1 / n); df <- n - 1",
    "q <- se0 / sqrt(se0^2 + tau^2)",
    sprintf("effective_alpha <- %s * pt(q * qt(1 - alpha / %s, df), df, lower.tail = FALSE)", tails, tails),
    call
  )
}

heterogeneity_script_r <- function(spec, result) {
  alternative <- pwr_alternative(spec$target_test$alternative %||% "two_sided")
  tails <- if (identical(alternative, "two.sided")) 2 else 1
  n <- spec$goal$n %||% result$n_required$n
  c(
    "# A correlation when the true correlation varies between studies (McShane & Bockenholt, 2014):",
    "# pwr.r.test() given the r and significance level that scale its Fisher's z by q.",
    sprintf("r <- %s     # the average correlation", format(spec$population$r)),
    sprintf("tau <- %s   # its SD between studies, on Fisher's z", format(spec$population$tau)),
    sprintf("alpha <- %s", format(spec$target_test$alpha %||% 0.05)),
    sprintf("n <- %s", format(n)),
    "q <- (1 / sqrt(n - 3)) / sqrt(1 / (n - 3) + tau^2)",
    "z_of <- function(x) atanh(x) + x / (2 * (n - 1))   # pwr.r.test()'s Fisher z",
    sprintf("ttt <- qt(alpha / %s, n - 2, lower.tail = FALSE)", tails),
    "rc <- tanh(q * atanh(sqrt(ttt^2 / (ttt^2 + n - 2))))",
    sprintf("effective_alpha <- %s * pt(sqrt((n - 2) * rc^2 / (1 - rc^2)), n - 2, lower.tail = FALSE)", tails),
    "r_adjusted <- uniroot(function(x) z_of(x) - q * z_of(r), sort(c(0, sign(r) * (1 - 1e-12))), tol = 1e-12)$root",
    sprintf("pwr::pwr.r.test(n = n, r = r_adjusted, sig.level = effective_alpha, alternative = \"%s\")$power", alternative)
  )
}
