# Validation: a planned meta-analysis, the test of the average effect.
# Backend: metapower's mpower(), the z test of the weighted average effect
# under the fixed-effect model, and Jackson and Turner's (2017) equation 9
# under the random-effects model (refs.bib, metapower_method). Build guide
# section 6:
#   1. published examples: Valentine, Pigott and Rothstein (2010)
#      (placeholders for the maintainer)
#   2. agreement with simulated meta-analyses: k studies of the same size,
#      true effects drawn from N(average, tau^2) with tau^2 from I-squared
#      (Jackson and Turner's I^2 = tau^2 / (sigma^2 + tau^2)), the
#      fixed-effect average, and the random-effects average with
#      DerSimonian and Laird's tau^2, each tested with a z test; so the
#      check doesn't rely on metapower's formulas
# Expected values below are owned by the maintainer: do not edit them.
# Skipped unless POWERKIT_FULL_VALIDATION=true.

meta_validation_spec <- function(metric, effect, study_size, k, i2, model = "random", alternative = "two_sided") {
  validation_spec(
    design = "meta_analysis",
    template = "mean_effect",
    variables = list(Y = validation_variable("continuous", "Outcome")),
    population = list(metric = metric, effect = effect, study_size = study_size, i2 = i2),
    target_test = list(effect = "mean_effect", method = "z_test", model = model, alpha = 0.05, alternative = alternative),
    seed = 1,
    n = k,
    # A formula: no simulations to set.
    options = list(nrep = NULL)
  )
}

# The proportion of simulated meta-analyses whose average effect is
# significant. Each study's estimate is drawn from its true effect with the
# sampling variance v (Cohen's d: 4 / n + d^2 / (2 n) for two equal groups;
# r: Fisher's z with variance 1 / (n - 3)).
simulated_meta_power <- function(metric, effect, study_size, k, i2, model, alternative, nrep, seed) {
  set.seed(seed)
  theta <- if (metric == "r") atanh(effect) else effect
  v <- if (metric == "r") 1 / (study_size - 3) else 4 / study_size + effect^2 / (2 * study_size)
  tau2 <- i2 * v / (1 - i2)
  crit <- stats::qnorm(1 - if (alternative == "two_sided") 0.025 else 0.05)
  hits <- vapply(seq_len(nrep), function(i) {
    y <- stats::rnorm(k, stats::rnorm(k, theta, sqrt(tau2)), sqrt(v))
    w <- rep(1 / v, k)
    fixed <- sum(w * y) / sum(w)
    if (model == "fixed") {
      z <- fixed * sqrt(sum(w))
    } else {
      q <- sum(w * (y - fixed)^2)
      t2 <- max(0, (q - (k - 1)) / (sum(w) - sum(w^2) / sum(w)))
      ws <- rep(1 / (v + t2), k)
      z <- sum(ws * y) / sum(ws) * sqrt(sum(ws))
    }
    if (alternative == "two_sided") abs(z) > crit else z * sign(theta) > crit
  }, logical(1))
  mean(hits)
}

# 1. Published examples ------------------------------------------------------------

test_that("fixed-effect model, one-sided: matches Valentine, Pigott and Rothstein (2010) (published)", {
  skip_unless_full_validation()
  # Source: Valentine, Pigott & Rothstein (2010), J. Educational and
  #   Behavioral Statistics 35(2), "Prospective statistical power for the
  #   fixed effects mean effect", pp. 218-220 (equations 2-7) and Table 1
  #   (p. 221). Transcribe: d, the per-group sample size, the number of
  #   studies k, and the one-tailed power the text reports.
  d <- TODO_PUBLISHED_VALUE
  per_group <- TODO_PUBLISHED_VALUE
  k <- TODO_PUBLISHED_VALUE
  published_power <- TODO_PUBLISHED_VALUE
  skip_if_todo(d, per_group, k, published_power)

  spec <- meta_validation_spec("d", d, 2 * per_group, k, i2 = 0, model = "fixed", alternative = "greater")
  expect_power_near(engine_power(spec), published_power)
})

test_that("random-effects model, one-sided: close to Valentine, Pigott and Rothstein (2010) (published)", {
  skip_unless_full_validation()
  # Source: as above, "Prospective statistical power for the random effects
  #   mean effect", pp. 223-224 (equations 11-14), with "a moderate degree
  #   of heterogeneity" (tau^2 equal to the typical within-study variance,
  #   so I-squared = 0.5). Transcribe d, the per-group size, k and the
  #   reported power. Valentine et al. treat tau^2 as known; metapower
  #   allows for it being estimated (Jackson and Turner, 2017), so a small
  #   difference is expected beyond rounding (docs/conventions.md, Known
  #   differences, 9).
  d <- TODO_PUBLISHED_VALUE
  per_group <- TODO_PUBLISHED_VALUE
  k <- TODO_PUBLISHED_VALUE
  published_power <- TODO_PUBLISHED_VALUE
  skip_if_todo(d, per_group, k, published_power)

  spec <- meta_validation_spec("d", d, 2 * per_group, k, i2 = 0.5, model = "random", alternative = "greater")
  expect_power_near(engine_power(spec), published_power)
})

# 2. Agreement with simulated meta-analyses ----------------------------------------

# r = tanh(0.3) has Fisher's z of exactly 0.30, so metapower's rounding of
# z to two decimals doesn't enter this comparison (its size is pinned in
# test-backend-metapower.R).
meta_cases <- list(
  list("d", 0.3, study_size = 40, k = 10, i2 = 0.5, model = "random", alternative = "two_sided"),
  list("d", 0.2, study_size = 60, k = 20, i2 = 0.25, model = "random", alternative = "two_sided"),
  list("d", 0.3, study_size = 40, k = 5, i2 = 0.5, model = "random", alternative = "greater"),
  list("d", 0.15, study_size = 40, k = 15, i2 = 0, model = "fixed", alternative = "two_sided"),
  list("r", tanh(0.3), study_size = 30, k = 6, i2 = 0.5, model = "random", alternative = "two_sided")
)

for (case in meta_cases) {
  label <- sprintf("%s = %s, %s studies of %s, I-squared %s, %s, %s", case[[1]], signif(case[[2]], 3), case$k,
                   case$study_size, case$i2, case$model, case$alternative)
  test_that(paste0(label, ": matches simulated meta-analyses"), {
    skip_unless_full_validation()
    spec <- meta_validation_spec(case[[1]], case[[2]], case$study_size, case$k, case$i2, case$model, case$alternative)
    nrep <- validation_nrep()
    reference <- simulated_meta_power(case[[1]], case[[2]], case$study_size, case$k, case$i2, case$model,
                                      case$alternative, nrep, seed = 2026)
    expect_power_near(engine_power(spec), reference, reference_nrep = nrep)
  })
}
