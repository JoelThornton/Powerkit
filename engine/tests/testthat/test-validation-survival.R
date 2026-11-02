# Validation: time-to-event outcomes (E43).
# Backends: Hmisc's cpower() (the log-rank test) and powerSurvEpi's
# powerEpiCont.default() (Hsieh and Lavori's formula for a Cox model).
#   1. analytic agreement: an independent simulation of the design each
#      formula assumes (exponential times; recruitment spread over the
#      accrual period; the log-rank test by survival::survdiff() or the
#      Cox model by survival::coxph()), without either package
#   2. published examples: placeholders, for the maintainer
#   3. Type I error: the formula's power with no effect
# The formulas are large-sample approximations, so the simulation is
# allowed 0.02 beyond its Monte Carlo error, the allowance used for the
# other normal-theory formulas (helper-crosscheck.R; docs/decisions.md,
# 2 November 2026).
# Expected values below are owned by the maintainer: do not edit them.
# Skipped unless POWERKIT_FULL_VALIDATION=true.

survival_reps <- 2000L

log_rank_validation_spec <- function(p_event, time, accrual, follow_up, n, ratio = NULL) {
  validation_spec(
    design = "survival",
    template = "log_rank",
    variables = list(
      X = validation_variable("binary", "Group", levels = list("Control", "Treatment")),
      Y = validation_variable("time_to_event", "Time to the event")
    ),
    population = list(metric = "event_proportions", time = time, p_event = as.list(p_event), accrual = accrual, follow_up = follow_up),
    target_test = list(effect = "group_difference", method = "log_rank", alpha = 0.05),
    seed = 4301,
    n = n,
    options = if (!is.null(ratio)) list(allocation_ratio = ratio) else list()
  )
}

cox_validation_spec <- function(hazard_ratio, event_proportion, r2_other, n) {
  validation_spec(
    design = "survival",
    template = "cox_predictor",
    variables = list(X = validation_variable("continuous", "Score"), Y = validation_variable("time_to_event", "Time to the event")),
    population = list(metric = "hazard_ratio", hazard_ratio = hazard_ratio, event_proportion = event_proportion, r2_other = r2_other),
    target_test = list(effect = "hazard_ratio", method = "cox_regression", alpha = 0.05),
    seed = 4302,
    n = n
  )
}

# The log-rank test on simulated studies, written out without Hmisc.
log_rank_by_hand <- function(p_event, time, accrual, follow_up, sizes, nrep, seed) {
  rate <- -log(1 - p_event) / time
  group <- rep(c(0, 1), sizes)
  hits <- with_seed(seed, vapply(seq_len(nrep), function(i) {
    event_time <- stats::rexp(length(group), rate[group + 1])
    follow <- accrual + follow_up - stats::runif(length(group), 0, accrual)
    status <- event_time <= follow
    test <- survival::survdiff(survival::Surv(pmin(event_time, follow), status) ~ group)
    stats::pchisq(test$chisq, 1, lower.tail = FALSE) < 0.05
  }, logical(1)))
  list(power = mean(hits), mcse = sqrt(mean(hits) * (1 - mean(hits)) / nrep))
}

# The Cox model's Wald test of a standard normal X, with the other
# predictor correlated with X so that X's R-squared on it is r2_other,
# censored at a fixed time that gives the event proportion.
cox_by_hand <- function(hazard_ratio, event_proportion, r2_other, n, nrep, seed) {
  beta <- log(hazard_ratio)
  grid <- stats::qnorm(seq(0.5, 999.5) / 1000)
  share_at <- function(c) mean(1 - exp(-exp(beta * grid) * c))
  censor <- stats::uniroot(function(c) share_at(c) - event_proportion, c(1e-8, 1e8), tol = 1e-10)$root
  hits <- with_seed(seed, vapply(seq_len(nrep), function(i) {
    z <- stats::rnorm(n)
    x <- sqrt(r2_other) * z + sqrt(1 - r2_other) * stats::rnorm(n)
    # The other predictor has no effect of its own, so the censoring time
    # still gives the event proportion.
    event_time <- stats::rexp(n, exp(beta * x))
    status <- event_time <= censor
    fit <- survival::coxph(survival::Surv(pmin(event_time, censor), status) ~ x + z)
    summary(fit)$coefficients["x", "Pr(>|z|)"] < 0.05
  }, logical(1)))
  list(power = mean(hits), mcse = sqrt(mean(hits) * (1 - mean(hits)) / nrep))
}

test_that("log-rank test: cpower() agrees with simulated log-rank tests (analytic)", {
  skip_unless_full_validation()
  cases <- list(
    list(p = c(0.4, 0.25), time = 12, accrual = 6, follow_up = 12, n = 300, ratio = NULL),
    list(p = c(0.3, 0.15), time = 1, accrual = 0, follow_up = 1, n = 402, ratio = 2)
  )
  for (case in cases) {
    spec <- log_rank_validation_spec(case$p, case$time, case$accrual, case$follow_up, case$n, case$ratio)
    ratio <- case$ratio %||% 1
    sizes <- c(case$n / (1 + ratio), case$n * ratio / (1 + ratio))
    reference <- log_rank_by_hand(case$p, case$time, case$accrual, case$follow_up, sizes, survival_reps, 99)
    expect_power_agrees_within(engine_power(spec), reference, allowance = 0.02)
  }
})

test_that("Cox predictor: Hsieh and Lavori's formula agrees with simulated Cox models (analytic)", {
  skip_unless_full_validation()
  for (case in list(list(hr = 0.75, psi = 0.3, r2 = 0.1, n = 350), list(hr = 1.4, psi = 0.6, r2 = 0, n = 150))) {
    spec <- cox_validation_spec(case$hr, case$psi, case$r2, case$n)
    reference <- cox_by_hand(case$hr, case$psi, case$r2, case$n, survival_reps, 98)
    expect_power_agrees_within(engine_power(spec), reference, allowance = 0.02)
  }
})

test_that("Cox predictor: power matches Hsieh and Lavori's worked example (published)", {
  skip_unless_full_validation()
  # Source: Hsieh, F. Y., & Lavori, P. W. (2000). Sample-size calculation
  # for the Cox proportional hazards regression model with nonbinary
  # covariates. Controlled Clinical Trials, 21, 552-560; the example on
  # p. 557 (the one powerSurvEpi's help reproduces). It is one-sided, so
  # alpha here is twice the published one.
  n <- TODO_PUBLISHED_VALUE # number of subjects
  log_hazard_ratio <- TODO_PUBLISHED_VALUE # log hazard ratio per unit of the covariate
  covariate_sd <- TODO_PUBLISHED_VALUE # SD of the covariate
  psi <- TODO_PUBLISHED_VALUE # proportion of subjects with the event
  r2 <- TODO_PUBLISHED_VALUE # R-squared of the covariate on the other covariates
  one_sided_alpha <- TODO_PUBLISHED_VALUE # significance level (one-sided)
  published_power <- TODO_PUBLISHED_VALUE # power as printed
  skip_if_todo(n, log_hazard_ratio, covariate_sd, psi, r2, one_sided_alpha, published_power)

  spec <- cox_validation_spec(exp(log_hazard_ratio * covariate_sd), psi, r2, n)
  spec$target_test$alpha <- 2 * one_sided_alpha
  expect_power_exact(engine_power(spec), published_power)
})

test_that("log-rank test: required n matches a published worked example (published)", {
  skip_unless_full_validation()
  # Source: TODO (maintainer: a published example for the log-rank test with
  # exponential times, accrual and follow-up; source, section, page).
  p_control <- TODO_PUBLISHED_VALUE # proportion with the event by `time`, control
  p_treatment <- TODO_PUBLISHED_VALUE # the same, treatment
  time <- TODO_PUBLISHED_VALUE # when the proportions are given
  accrual <- TODO_PUBLISHED_VALUE # recruitment period
  follow_up <- TODO_PUBLISHED_VALUE # minimum follow-up
  published_n <- TODO_PUBLISHED_VALUE # total sample size as printed
  skip_if_todo(p_control, p_treatment, time, accrual, follow_up, published_n)

  spec <- log_rank_validation_spec(c(p_control, p_treatment), time, accrual, follow_up, n = NULL)
  spec$goal <- list(type = "sample_size", power = 0.8)
  expect_n_near(engine_function("run_spec")(spec)$n_required, published_n)
})

test_that("time-to-event formulas' rejection rate with no effect (Type I error)", {
  skip_unless_full_validation()
  # The spec checks refuse a zero effect, so the packages are called
  # directly at no effect. cpower() counts both tails, so gives alpha;
  # Hsieh and Lavori's formula counts only the tail in the effect's
  # direction, so gives alpha / 2 at no effect (the other tail is
  # negligible at the effects it is used for).
  expect_equal(unname(Hmisc::cpower(12, 300, 0.4, 0, 6, 12, alpha = 0.05, pr = FALSE)), 0.05, tolerance = 1e-12)
  expect_equal(powerSurvEpi::powerEpiCont.default(300, 1, 1, 0.3, 0.1, 0.05), 0.025, tolerance = 1e-12)
})
