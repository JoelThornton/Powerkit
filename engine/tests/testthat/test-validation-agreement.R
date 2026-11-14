# Validation: Bland-Altman limits of agreement (design "reliability",
# template "bland_altman").
# Backend: Spower simulation of powerkit's experiment p_bland_altman(),
# which analyses each study with SimplyAgree's agreement_limit() (MOVER or
# Bland and Altman's intervals); Lu et al.'s approximation is SimplyAgree's
# blandPowerCurve() (equality checked in test-backend-agreement.R).
#   1. agreement with an independent simulation: the limits and the outer
#      ends of their intervals written out (Bland and Altman's interval, and
#      the MOVER interval of Zou (2013) and Donner and Zou (2012) that
#      SimplyAgree's help cites), without the package
#   2. size: with one population limit exactly at the margin, the MOVER
#      analysis shows agreement close to alpha / 2 of the time (each outer
#      end is a one-sided 1 - alpha / 2 bound); Bland and Altman's
#      approximate interval does so more often at small samples
#   3. the size of the difference between Lu et al.'s approximation and the
#      analysis it approximates (docs/conventions.md, "Bland-Altman limits
#      of agreement")
#   4. published example: placeholder, for the maintainer
# Expected values below are owned by the maintainer: do not edit them.
# Skipped unless POWERKIT_FULL_VALIDATION=true.

ba_validation_spec <- function(n, bias, sd, margin, method = "mover", agree = 0.95, alpha = 0.05, seed = 6401) {
  spec <- example_spec("reliability_bland_altman")
  spec$population$bias <- bias
  spec$population$sd_difference <- sd
  spec$population$margin <- margin
  spec$target_test$method <- method
  spec$target_test$agree_level <- agree
  spec$target_test$alpha <- alpha
  spec$goal <- list(type = "power", n = n)
  spec$options <- list(nrep = validation_nrep(), seed = seed)
  spec <- validate_spec(spec)
  skip_if_no_backend(spec)
  spec
}

# The outer ends of two-sided (1 - alpha) intervals for the limits of
# agreement, mean(d) -/+ z sd(d), from one sample of differences d.
#   Bland and Altman (1999): SE of a limit s sqrt(1 / n + z^2 / (2 (n - 1))),
#     times t at 1 - alpha / 2 with n - 1 df.
#   MOVER: s sqrt(q^2 / n + z^2 (sqrt((n - 1) / chi2) - 1)^2), q the normal
#     quantile at 1 - alpha / 2 and chi2 the chi-square quantile at alpha / 2
#     with n - 1 df (the upper end of the interval for the SD, recovered).
ba_bounds_by_hand <- function(d, agree, alpha, method) {
  n <- length(d)
  z <- stats::qnorm(1 - (1 - agree) / 2)
  m <- mean(d)
  s <- stats::sd(d)
  margin_of_error <- if (method == "bland_altman") {
    stats::qt(1 - alpha / 2, n - 1) * s * sqrt(1 / n + z^2 / (2 * (n - 1)))
  } else {
    s * sqrt(stats::qnorm(1 - alpha / 2)^2 / n + z^2 * (sqrt((n - 1) / stats::qchisq(alpha / 2, n - 1)) - 1)^2)
  }
  c(lower = m - z * s - margin_of_error, upper = m + z * s + margin_of_error)
}

ba_by_hand <- function(n, bias, sd, margin, method, nrep, seed, agree = 0.95, alpha = 0.05) {
  hits <- with_seed(seed, vapply(seq_len(nrep), function(i) {
    bounds <- ba_bounds_by_hand(stats::rnorm(n, bias, sd), agree, alpha, method)
    bounds[["lower"]] > -margin && bounds[["upper"]] < margin
  }, logical(1)))
  list(power = mean(hits), mcse = sqrt(mean(hits) * (1 - mean(hits)) / nrep))
}

test_that("Bland-Altman: powerkit agrees with the analysis written out (simulation)", {
  skip_unless_full_validation()
  # The intervals written out give SimplyAgree's outer bounds (its alpha is
  # one-sided, so it is given alpha / 2).
  for (seed in 1:3) {
    y <- with_seed(seed, stats::rnorm(35))
    data <- data.frame(x = y + with_seed(seed + 10, stats::rnorm(35, 0.5, 2)), y = y)
    for (method in c("mover", "bland_altman")) {
      loa <- SimplyAgree::agreement_limit(x = "x", y = "y", data = data, loa_calc = bland_altman_loa_calc(method),
        agree.level = 0.95, alpha = 0.025)$loa
      expect_equal(unname(ba_bounds_by_hand(data$x - data$y, 0.95, 0.05, method)),
        c(loa$lower_loa_ci, loa$upper_loa_ci), tolerance = 1e-8)
    }
  }
  cases <- list(
    list(n = 30, bias = 0.5, sd = 2.5, margin = 8, method = "mover"),
    list(n = 60, bias = 1, sd = 2, margin = 6, method = "bland_altman")
  )
  for (case in cases) {
    spec <- ba_validation_spec(case$n, case$bias, case$sd, case$margin, case$method)
    reference <- ba_by_hand(case$n, case$bias, case$sd, case$margin, case$method, 20000L, 64)
    expect_power_agrees_within(engine_power(spec), reference, allowance = 0)
  }
})

test_that("Bland-Altman: with one limit at the margin, agreement is shown about alpha / 2 of the time (simulation)", {
  skip_unless_full_validation()
  # Bias 1 and SD 1: the population's upper limit, 1 + 1.96, is the margin,
  # and the lower limit is far inside it, so showing agreement is a Type I
  # error of the upper limit's one-sided test at alpha / 2 = 0.025.
  z <- stats::qnorm(0.975)
  expect_type1_near(engine_power(ba_validation_spec(100, 1, 1, 1 + z)), alpha = 0.025)
  # Bland and Altman's approximate interval is too narrow at small samples:
  # about 0.05 at n = 30 (twice the nominal 0.025) in 40,000 studies
  # written out, and the engine's run agrees.
  by_hand <- ba_by_hand(30, 1, 1, 1 + z, "bland_altman", 40000L, 65)
  expect_gt(by_hand$power, 0.04)
  expect_power_agrees_within(engine_power(ba_validation_spec(30, 1, 1, 1 + z, "bland_altman")), by_hand, allowance = 0)
})

test_that("Bland-Altman: the size of the difference between Lu et al.'s approximation and the analysis (simulation)", {
  skip_unless_full_validation()
  # Lu et al.'s formula (SimplyAgree's blandPowerCurve()) approximates the
  # power of Bland and Altman's analysis; against that analysis simulated
  # (40,000 studies each) it is off by several points in both directions.
  lu <- function(n, bias, sd, margin) {
    as.numeric(SimplyAgree::blandPowerCurve(samplesizes = n, mu = bias, SD = sd, delta = margin,
      conf.level = 0.95, agree.level = 0.95)$power)
  }
  over <- ba_by_hand(30, 0.5, 2.5, 8, "bland_altman", 40000L, 66)
  under <- ba_by_hand(100, 0, 3.3, 8, "bland_altman", 40000L, 67)
  expect_gt(lu(30, 0.5, 2.5, 8) - over$power, 0.02)
  expect_gt(under$power - lu(100, 0, 3.3, 8), 0.05)
  # Departure 27: against powerkit's default, the MOVER analysis, the
  # formula is further off. For the example (bias 0.5, SD of the
  # differences 2.5, margin 8) it gives 82% power at 26 subjects, its
  # answer for 80%; the MOVER analysis has about 69% there.
  expect_gte(lu(26, 0.5, 2.5, 8), 0.8)
  expect_lt(lu(25, 0.5, 2.5, 8), 0.8)
  mover <- ba_by_hand(26, 0.5, 2.5, 8, "mover", 40000L, 68)
  expect_gt(lu(26, 0.5, 2.5, 8) - mover$power, 0.1)
})

test_that("Bland-Altman: compared with a published example (published)", {
  skip_unless_full_validation()
  # Source: TODO (maintainer: a published power or sample-size example for
  # the Bland-Altman limits of agreement; source, section, page).
  bias <- TODO_PUBLISHED_VALUE
  sd_difference <- TODO_PUBLISHED_VALUE
  margin <- TODO_PUBLISHED_VALUE
  n <- TODO_PUBLISHED_VALUE
  published_power <- TODO_PUBLISHED_VALUE
  skip_if_todo(bias, sd_difference, margin, n, published_power)
  spec <- ba_validation_spec(n, bias, sd_difference, margin, "bland_altman")
  expect_power_near(engine_power(spec), published_power)
})
