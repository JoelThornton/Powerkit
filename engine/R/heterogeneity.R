# Effects that vary between studies (Kenny & Judd, 2019, refs.bib
# Kenny2019_heterogeneity): a t-test planned for a true effect that is not
# the same in every study, but varies around the planned effect mu with
# standard deviation tau (population > tau, in d or d_z units).
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

heterogeneity_templates <- c("independent_t", "one_sample_t", "paired_t")

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
    return("How much the effect varies between studies ('population > tau') is available for the t-tests only.")
  }
  if (!is.numeric(tau) || length(tau) != 1 || is.na(tau) || tau < 0 || tau > 2) {
    return("How much the effect varies between studies ('population > tau') must be a standard deviation between 0 and 2, in d.")
  }
  if (tau == 0) return(character())
  problems <- character()
  method <- spec$target_test$method %||% ""
  if (!method %in% c("", "t_test", "student_t", "welch_t")) {
    problems <- c(problems, "Variation between studies is planned for Student's or Welch's t-test, not for rank tests or Bayes factors.")
  }
  if (identical(spec$options$method, "simulation")) {
    problems <- c(problems, "Variation between studies is worked out by Kenny and Judd's formula; remove 'options > method'.")
  }
  if (!is.null(spec$population$sd_ratio) && !isTRUE(all.equal(spec$population$sd_ratio, 1))) {
    problems <- c(problems, "Variation between studies needs the two groups' SDs to be equal (an SD ratio of 1).")
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
    ratio <- spec$options$allocation_ratio %||% 1
    n1 <- round(n / (1 + ratio))
    return(list(se = sqrt(1 / n1 + 1 / (n - n1)), df = n - 2))
  }
  list(se = sqrt(1 / n), df = n - 1)
}

# Kenny and Judd's adjustment at n: q, the effective alpha, and the d
# that gives pwr their noncentrality.
heterogeneity_adjustment <- function(spec, n, mu = NULL) {
  tau <- spec$population$tau
  mu <- mu %||% if (identical(spec$template, "paired_t")) spec$population$dz else spec$population$d
  alpha <- spec$target_test$alpha %||% 0.05
  tails <- if (identical(spec$target_test$alternative %||% "two_sided", "two_sided")) 2 else 1
  base <- heterogeneity_se0(spec, n)
  q <- base$se / sqrt(base$se^2 + tau^2)
  critical <- q * stats::qt(1 - alpha / tails, base$df)
  list(q = q, d = q * mu, alpha = tails * stats::pt(critical, base$df, lower.tail = FALSE),
    critical_t = critical, df = base$df)
}

heterogeneity_backend <- function(spec, seed = NULL) {
  student <- spec
  student$target_test$method <- if (identical(spec$template, "independent_t")) "student_t" else "t_test"
  inputs <- pwr_inputs(student)
  base_args <- inputs$args
  effect_field <- if (identical(spec$template, "paired_t")) "dz" else "d"
  power_with <- function(n, mu = NULL) {
    a <- heterogeneity_adjustment(spec, n, mu)
    adjusted <- inputs
    adjusted$alpha <- a$alpha
    adjusted$args <- function(m) {
      args <- base_args(m)
      args$d <- a$d
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
    functions = c(exact = sprintf("%s::%s with Kenny and Judd's (2019) adjustment for variation between studies (tau = %s): sig.level = the effective alpha, d = q * %s",
      inputs$package, inputs$fun, format(spec$population$tau), effect_field)),
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
  specified <- if (identical(spec$template, "paired_t")) spec$population$dz else spec$population$d
  sign <- if (identical(spec$target_test$alternative, "less") || isTRUE(specified < 0)) -1 else 1
  f <- function(mu) power_with(n, sign * mu) - target
  if (f(5) < 0) {
    abort_run("No average effect up to 5 reaches the target power at this n with this much variation between studies.")
  }
  found <- stats::uniroot(f, c(1e-6, 5), tol = 1e-8)$root
  list(effect = sign * found, effect_name = if (identical(spec$template, "paired_t")) "d_z" else "d",
    effect_description = "the average effect between studies, as Cohen's d (d_z for pairs)",
    power = power_with(n, sign * found))
}

# For the result: tau, and at the analysed n the chance a study is
# significant with no average effect (Kenny and Judd's effective alpha),
# and the power with no variation, for comparison.
heterogeneity_record <- function(spec, n = NULL) {
  if (!heterogeneity_test(spec) || is.null(n) || !is.numeric(n) || is.na(n)) return(NULL)
  a <- heterogeneity_adjustment(spec, n)
  usual <- spec
  usual$population$tau <- NULL
  if (identical(spec$template, "independent_t")) usual$target_test$method <- "student_t"
  inputs <- pwr_inputs(usual)
  list(tau = spec$population$tau, effective_alpha = a$alpha, q = a$q,
    power = heterogeneity_backend(spec)$exact_power(n), power_without = pwr_power(inputs, n), n = n,
    source = "Kenny & Judd (2019)")
}

# The R script: pwr with Kenny and Judd's adjustment, as above.
heterogeneity_script <- function(spec, result) {
  two <- identical(spec$template, "independent_t")
  ratio <- spec$options$allocation_ratio %||% 1
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
