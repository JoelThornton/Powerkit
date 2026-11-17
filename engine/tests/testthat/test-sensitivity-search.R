# The smallest detectable effect for the dependent correlations (pwrss),
# the variance tests and Hotelling's T-squared (stats) and the equivalence
# tests (TOSTER), found by searching the backend's own power over the effect
# at a fixed n (sensitivity-pwrss.R, sensitivity-search.R, 16 November
# 2026). Each is checked against a simulation of the test itself, which
# uses none of the power formulas, and the exported R script must
# reproduce it.

sensitivity_of <- function(spec, n = 120L, power = 0.8) {
  spec$goal <- list(type = "sensitivity", n = n, power = power)
  spec$options$method <- NULL
  spec$options$nrep <- NULL
  suppressWarnings(run_quietly(spec))
}

two_group_manova <- function() {
  spec <- example_spec("manova")
  spec$population$means <- spec$population$means[1:2]
  spec$variables$A$levels <- spec$variables$A$levels[1:2]
  spec
}

test_that("each search reaches the target power, and the script reproduces it", {
  skip_on_cran()
  specs <- list(
    overlapping_correlations = example_spec("overlapping_correlations"),
    nonoverlapping_correlations = example_spec("nonoverlapping_correlations"),
    one_variance = example_spec("one_variance"),
    two_variances = example_spec("two_variances"),
    hotelling_one = example_spec("hotelling_one"),
    hotelling_two = two_group_manova(),
    tost_independent = example_spec("tost_independent"),
    tost_paired = example_spec("tost_paired"),
    tost_one_sample = example_spec("tost_one_sample"),
    tost_correlation = example_spec("tost_correlation"),
    tost_two_proportions = example_spec("tost_two_proportions")
  )
  for (name in names(specs)) {
    spec <- specs[[name]]
    result <- sensitivity_of(spec)
    expect_equal(result$sensitivity$power, 0.8, tolerance = 1e-6, label = name)
    spec$goal <- list(type = "sensitivity", n = 120L, power = 0.8)
    spec$options$method <- NULL
    spec$options$nrep <- NULL
    file <- withr::local_tempfile(fileext = ".R")
    writeLines(export_script(spec, result), file)
    out <- system2(file.path(R.home("bin"), "Rscript"), file, stdout = TRUE, stderr = TRUE)
    expect_true(any(grepl("^Reproduced powerkit's result", out)), label = name)
  }
})

test_that("Steiger's test of two correlations sharing a variable has the target power at the second correlation found", {
  skip_on_cran()
  spec <- example_spec("overlapping_correlations")
  s <- sensitivity_of(spec)$sensitivity
  expect_identical(s$effect_name, "r_second")
  # The entered second correlation is below the first, so the search looks
  # for a smaller one.
  expect_lt(s$effect, spec$population$r_X_Y)
  pop <- spec$population
  sigma <- matrix(c(1, pop$r_X_Y, s$effect, pop$r_X_Y, 1, pop$r_Y_Z, s$effect, pop$r_Y_Z, 1), 3)
  set.seed(20261116)
  hits <- replicate(2000, {
    r <- stats::cor(MASS::mvrnorm(120, rep(0, 3), sigma))
    # psych's r.test() with pooled = FALSE is Steiger's (1980) z test as
    # G*Power computes it (powerkit's Departure 12).
    psych::r.test(120, r12 = r[1, 2], r13 = r[1, 3], r23 = r[2, 3], pooled = FALSE)$p < 0.05
  })
  # The asymptotic power pwrss (and G*Power) give for Steiger's z is a
  # little below the test's simulated rejection rate: about 0.03 lower at
  # these values, at the correlations entered (0.615 against 0.645) as at
  # the one found. So this checks that the search lands on the formula's
  # target, within that known gap, not the formula's accuracy.
  expect_equal(mean(hits), 0.8, tolerance = 0.05)
})

test_that("the second correlation stays where the correlation matrix is positive definite", {
  spec <- example_spec("overlapping_correlations")
  range <- dependent_correlation_range(spec, "r_X_Z")
  pop <- spec$population
  # For three variables the ends are known: r12 r23 -/+ sqrt((1 - r12^2)(1 - r23^2)).
  ends <- pop$r_X_Y * pop$r_Y_Z + c(-1, 1) * sqrt((1 - pop$r_X_Y^2) * (1 - pop$r_Y_Z^2))
  expect_equal(range, ends + c(0.001, -0.001), tolerance = 1e-8)
  four <- example_spec("nonoverlapping_correlations")
  range <- dependent_correlation_range(four, "r_X2_Y2")
  s <- sensitivity_of(four)$sensitivity
  expect_true(s$effect > range[1] && s$effect < range[2])
})

test_that("the variance tests' ratio has the target power in a simulation of the tests", {
  skip_on_cran()
  set.seed(20261116)
  two <- example_spec("two_variances")
  s <- sensitivity_of(two)$sensitivity
  expect_identical(s$effect_name, "variance_ratio")
  hits <- replicate(2000, stats::var.test(stats::rnorm(60, sd = sqrt(s$effect)), stats::rnorm(60))$p.value < 0.05)
  expect_equal(mean(hits), 0.8, tolerance = 0.03)

  one <- example_spec("one_variance")
  s <- sensitivity_of(one)$sensitivity
  # The test is one-sided ('less'): the ratio found is below 1.
  expect_lt(s$effect, 1)
  expect_equal(s$variance, s$effect * one$population$var0)
  hits <- replicate(2000, {
    y <- stats::rnorm(120, sd = sqrt(s$variance))
    stats::pchisq(119 * stats::var(y) / one$population$var0, 119) < 0.05
  })
  expect_equal(mean(hits), 0.8, tolerance = 0.03)
})

test_that("Hotelling's T-squared: the distance found has the target power in Spower's simulation", {
  skip_on_cran()
  for (spec in list(example_spec("hotelling_one"), two_group_manova())) {
    s <- sensitivity_of(spec)$sensitivity
    expect_identical(s$effect_name, "mahalanobis")
    at <- spec
    at$population$means <- s$means
    at$goal <- list(type = "power", n = 120L)
    at$options <- list(method = "simulation", nrep = 2000L)
    expect_equal(suppressWarnings(run_quietly(at))$curve$power, 0.8, tolerance = 0.03)
    # The pattern entered keeps its shape.
    at$options <- NULL
    expect_equal(sqrt(hotelling_inputs(at)$distance2), s$effect, tolerance = 1e-8)
  }
  spec <- example_spec("hotelling_one")
  spec$population$means <- spec$population$mu0
  spec$goal <- list(type = "sensitivity", n = 120L, power = 0.8)
  expect_error(validate_spec(spec), "no effect pattern to scale")
})

test_that("an equivalence test's narrowest bound shows equivalence with the target power in a simulation of TOST", {
  skip_on_cran()
  spec <- example_spec("tost_independent")
  spec$population$bound <- NULL
  s <- sensitivity_of(spec)$sensitivity
  expect_identical(s$effect_name, "bound")
  set.seed(20261116)
  hits <- replicate(2000, {
    a <- stats::rnorm(60)
    b <- stats::rnorm(60, spec$population$d)
    lower <- stats::t.test(b, a, mu = -s$effect, alternative = "greater", var.equal = TRUE)$p.value
    upper <- stats::t.test(b, a, mu = s$effect, alternative = "less", var.equal = TRUE)$p.value
    max(lower, upper) < 0.05
  })
  expect_equal(mean(hits), 0.8, tolerance = 0.03)

  correlation <- example_spec("tost_correlation")
  correlation$population$bound <- NULL
  s <- sensitivity_of(correlation)$sensitivity
  hits <- replicate(2000, {
    r <- stats::cor(MASS::mvrnorm(120, c(0, 0), matrix(c(1, correlation$population$r, correlation$population$r, 1), 2)))[1, 2]
    z <- (atanh(r) - atanh(c(-s$effect, s$effect))) * sqrt(117)
    stats::pnorm(z[1], lower.tail = FALSE) < 0.05 && stats::pnorm(z[2]) < 0.05
  })
  expect_equal(mean(hits), 0.8, tolerance = 0.03)

  # With a bound entered for power, it is still required.
  power <- example_spec("tost_independent")
  power$population$bound <- NULL
  expect_error(validate_spec(power), "Give the equivalence bound")
})

test_that("a meta-analysis's smallest average effect: metapower's z test against metafor, and the simulated Hartung-Knapp test", {
  skip_on_cran()
  spec <- example_spec("meta_mean_effect")
  spec$target_test$test <- "z"
  s <- sensitivity_of(spec, n = 20L)$sensitivity
  expect_identical(s$effect_name, "meta_d")
  expect_equal(s$power, 0.8, tolerance = 1e-6)
  # metafor's random-effects z test (DerSimonian and Laird) on simulated
  # meta-analyses of 20 studies at that average effect. metapower allows
  # for tau-squared being estimated (Jackson and Turner, 2017), so the two
  # agree only roughly.
  pop <- spec$population
  v <- 4 / pop$study_size + s$effect^2 / (2 * pop$study_size)
  tau2 <- pop$i2 * v / (1 - pop$i2)
  set.seed(20261117)
  hits <- replicate(2000, {
    yi <- stats::rnorm(20, stats::rnorm(20, s$effect, sqrt(tau2)), sqrt(v))
    metafor::rma(yi = yi, vi = rep(v, 20), method = "DL")$pval < 0.05
  })
  expect_equal(mean(hits), 0.8, tolerance = 0.06)
  for (name in c("z")) {
    script_spec <- spec
    script_spec$goal <- list(type = "sensitivity", n = 20L, power = 0.8)
    result <- sensitivity_of(spec, n = 20L)
    file <- withr::local_tempfile(fileext = ".R")
    writeLines(export_script(script_spec, result), file)
    out <- system2(file.path(R.home("bin"), "Rscript"), file, stdout = TRUE, stderr = TRUE)
    expect_true(any(grepl("^Reproduced powerkit's result", out)))
  }

  hk <- example_spec("meta_mean_effect")
  hk$goal <- list(type = "sensitivity", n = 20L, power = 0.8)
  hk$options$nrep <- 500L
  result <- suppressWarnings(run_quietly(hk))
  s <- result$sensitivity
  expect_true(isTRUE(s$simulated) && s$effect_lower < s$effect && s$effect < s$effect_upper)
  # Power simulated afresh at the effect found, with more replications.
  at <- hk
  at$population$effect <- s$effect
  at$goal <- list(type = "power", n = 20L)
  at$options$nrep <- 4000L
  at$options$seed <- 99L
  expect_equal(suppressWarnings(run_quietly(at))$curve$power, 0.8, tolerance = 0.04)
  file <- withr::local_tempfile(fileext = ".R")
  writeLines(export_script(hk, result), file)
  out <- system2(file.path(R.home("bin"), "Rscript"), file, stdout = TRUE, stderr = TRUE)
  expect_true(any(grepl("^Reproduced powerkit's result", out)))
  # The other meta-analysis questions still refuse the goal plainly.
  sub <- example_spec("meta_subgroups")
  sub$goal <- list(type = "sensitivity", n = 20L, power = 0.8)
  expect_error(validate_spec(sub), "average effect only")
})

test_that("SEM: the RMSEA found matches WebPower's own solver, and semPower needs the n given at the correlation and slope found", {
  skip_on_cran()
  skip_if_not_installed("semPower")
  fit <- example_spec("sem_model_fit")
  df <- sem_df(fit)
  for (method in c("chi_square_exact_fit", "chi_square_close_fit", "chi_square_not_close_fit")) {
    spec <- fit
    spec$target_test$method <- method
    spec$population$rmsea <- NULL
    n <- if (method == "chi_square_not_close_fit") 600L else 200L
    s <- sensitivity_of(spec, n = n)$sensitivity
    expect_identical(s$effect_name, "rmsea")
    # WebPower solves wp.sem.rmsea() for rmsea1 itself; the test of exact
    # fit is its test of close fit with a null RMSEA of 0.
    solved <- WebPower::wp.sem.rmsea(
      n = n, df = df, rmsea0 = if (method == "chi_square_exact_fit") 0 else 0.05, rmsea1 = NULL, power = 0.8,
      alpha = 0.05, type = if (method == "chi_square_not_close_fit") "notclose" else "close"
    )$rmsea1
    # WebPower's uniroot() keeps R's default tolerance (about 1e-4 on the
    # RMSEA), so the two agree to about three significant figures.
    expect_equal(s$effect, solved, tolerance = 2e-3, label = method)
    spec$goal <- list(type = "sensitivity", n = n, power = 0.8)
    file <- withr::local_tempfile(fileext = ".R")
    writeLines(export_script(spec, sensitivity_of(spec, n = n)), file)
    out <- system2(file.path(R.home("bin"), "Rscript"), file, stdout = TRUE, stderr = TRUE)
    expect_true(any(grepl("^Reproduced powerkit's result", out)), label = method)
  }
  # With an RMSEA given for power, it is still required.
  power <- fit
  power$population$rmsea <- NULL
  expect_error(validate_spec(power), "Give the model's RMSEA")

  for (name in c("sem_factor_correlation", "sem_latent_regression")) {
    spec <- example_spec(name)
    result <- sensitivity_of(spec, n = 200L)
    s <- result$sensitivity
    # semPower's own a-priori analysis at the value found needs about the n
    # given (it rounds up to a whole person).
    at <- spec
    if (name == "sem_factor_correlation") at$population$r <- s$effect else {
      at$population$slopes[[at$population$tested %||% 1L]] <- s$effect
    }
    args <- sem_restriction_args(at)
    fun <- getExportedValue("semPower", sub("^semPower::", "", sem_function(at)))
    needed <- suppressMessages(do.call(fun, c(list(type = "a-priori", alpha = 0.05, power = 0.8), args)))$requiredN
    expect_true(abs(needed - 200) <= 1, label = name)
    spec$goal <- list(type = "sensitivity", n = 200L, power = 0.8)
    file <- withr::local_tempfile(fileext = ".R")
    writeLines(export_script(spec, result), file)
    out <- system2(file.path(R.home("bin"), "Rscript"), file, stdout = TRUE, stderr = TRUE)
    expect_true(any(grepl("^Reproduced powerkit's result", out)), label = name)
  }
  # Invariance compares a pattern of loadings or intercepts: no single
  # effect to search, so the goal is refused plainly.
  mi <- example_spec("sem_invariance")
  mi$goal <- list(type = "sensitivity", n = 200L, power = 0.8)
  expect_error(suppressWarnings(run_quietly(mi)), "isn't available yet")
})

test_that("ordinal, survival, growth-curve and reliability searches agree with the packages' own solvers and simulations", {
  skip_on_cran()
  found <- function(name, n = 150L) {
    spec <- example_spec(name)
    result <- sensitivity_of(spec, n = n)
    # kappaSize's power is itself found by uniroot() over its whole-subject
    # sample size, so it reaches the target to about 1e-5.
    expect_equal(result$sensitivity$power, 0.8, tolerance = 1e-4, label = name)
    spec$goal <- list(type = "sensitivity", n = n, power = 0.8)
    file <- withr::local_tempfile(fileext = ".R", .local_envir = parent.frame())
    writeLines(export_script(spec, result), file)
    out <- system2(file.path(R.home("bin"), "Rscript"), file, stdout = TRUE, stderr = TRUE)
    expect_true(any(grepl("^Reproduced powerkit's result", out)), label = name)
    list(spec = spec, s = result$sensitivity)
  }
  # Proportional odds: Hmisc's popower() (Whitehead, 1993) gives the same
  # power from the categories' shares pooled over the two groups (group
  # 2's from group 1's by the odds ratio, Hmisc's pomodm()).
  x <- found("ordinal_two_groups")
  pop <- x$spec$population
  expect_lt(x$s$effect, 1)
  pooled <- (unlist(pop$probabilities) + Hmisc::pomodm(p = unlist(pop$probabilities), odds.ratio = x$s$effect)) / 2
  expect_equal(Hmisc::popower(pooled, x$s$effect, 150)$power, 0.8, tolerance = 1e-3)

  # A Cox regression predictor: powerSurvEpi's own sample size at the
  # hazard ratio found.
  x <- found("survival_cox_predictor")
  pop <- x$spec$population
  needed <- powerSurvEpi::ssizeEpiCont.default(power = 0.8, theta = x$s$effect, sigma2 = 1,
    psi = pop$event_proportion, rho2 = pop$r2_other, alpha = 0.05)
  expect_true(abs(needed - 150) <= 1)

  # The log-rank test, simulated with survival's survdiff(): exponential
  # times reaching the proportions by the reference time, uniform entry
  # over the accrual period, follow-up to its end.
  x <- found("survival_log_rank")
  pop <- x$spec$population
  expect_identical(x$s$effect_name, "p_event2")
  rates <- -log(1 - c(pop$p_event[[1]], x$s$effect)) / pop$time
  set.seed(20261117)
  hits <- replicate(2000, {
    group <- rep(1:2, each = 75)
    entry <- stats::runif(150, 0, pop$accrual)
    event_time <- stats::rexp(150, rates[group])
    censor <- pop$accrual + pop$follow_up - entry
    test <- survival::survdiff(survival::Surv(pmin(event_time, censor), event_time <= censor) ~ group)
    stats::pchisq(test$chisq, 1, lower.tail = FALSE) < 0.05
  })
  expect_equal(mean(hits), 0.8, tolerance = 0.03)

  # Growth curves: longpower solves diggle.linear.power() for delta itself.
  x <- found("growth_curve")
  pop <- x$spec$population
  t <- unlist(pop$times)
  cov_is <- pop$r_intercept_slope * pop$sd_intercept * pop$sd_slope
  r <- outer(t, t, function(a, b) pop$sd_intercept^2 + a * b * pop$sd_slope^2 + (a + b) * cov_is) + diag(pop$sd_residual^2, length(t))
  delta <- longpower::diggle.linear.power(n = 75, delta = NULL, t = t, sigma2 = 1, R = r, sig.level = 0.05, power = 0.8)$delta
  expect_equal(abs(x$s$effect), delta, tolerance = 1e-4)

  # The ICC's F test, simulated: one-way random effects with that ICC.
  x <- found("reliability_icc")
  pop <- x$spec$population
  k <- pop$raters
  ratio <- function(rho) (1 + (k - 1) * rho) / (1 - rho)
  set.seed(20261117)
  hits <- replicate(2000, {
    y <- matrix(stats::rnorm(150, sd = sqrt(x$s$effect)), 150, k) + stats::rnorm(150 * k, sd = sqrt(1 - x$s$effect))
    msb <- k * stats::var(rowMeans(y))
    msw <- sum((y - rowMeans(y))^2) / (150 * (k - 1))
    msb / msw > ratio(pop$icc_null) * stats::qf(0.95, 149, 150 * (k - 1))
  })
  expect_equal(mean(hits), 0.8, tolerance = 0.03)

  # Cronbach's alpha and kappa: statpsych's and kappaSize's own sample
  # sizes at the value found.
  x <- found("reliability_cronbach_alpha")
  pop <- x$spec$population
  expect_true(abs(statpsych::size.test.cronbach(0.05, 0.8, x$s$effect, pop$items, pop$reliability_null)[[1]] - 150) <= 1)
  x <- found("reliability_kappa")
  pop <- x$spec$population
  needed <- kappaSize::PowerBinary(pop$kappa_null, x$s$effect, pop$proportions[[2]], raters = pop$raters, alpha = 0.05, power = 0.8)$N
  expect_true(abs(needed - 150) <= 1)
})

test_that("simulated searches for paired variances, trends, d', factorial logistic effects, moderation, time series and unordered categories land where a fresh simulation has the target power", {
  skip_on_cran()
  set_found <- list(
    paired_variances = function(spec, s) { spec$population$var1 <- spec$population$var2 * s$effect; spec },
    proportion_trend = function(spec, s) {
      p <- unlist(spec$population$proportions)
      spec$population$proportions <- as.list(mean(p) + s$scale * (p - mean(p)))
      spec
    },
    dprime = function(spec, s) { spec$population$dprime[[2]] <- spec$population$dprime[[1]] + s$effect; spec },
    jonckheere = function(spec, s) {
      m <- unlist(spec$population$means)
      spec$population$means <- as.list(mean(m) + s$scale * (m - mean(m)))
      spec
    },
    its = function(spec, s) { spec$population$level_change <- s$effect; spec },
    regression_interaction_binary = function(spec, s) { spec$population$r_XW_Y <- s$effect; spec },
    logistic_interaction = function(spec, s) { spec$population$odds_ratio_xw <- s$effect; spec },
    poisson_interaction = function(spec, s) { spec$population$rate_ratio_xw <- s$effect; spec },
    # The log odds ratios of the categories against the first, scaled: from
    # the shares entered (the second point's less the first's).
    multinomial_regression = function(spec, s) {
      p1 <- unlist(spec$population$probabilities)
      p2 <- unlist(spec$population$probabilities_second)
      spec$population$odds_ratios <- as.list(exp(s$scale * (log(p2[-1] / p2[1]) - log(p1[-1] / p1[1]))))
      spec$population$probabilities_second <- NULL
      spec
    },
    multinomial_interaction = function(spec, s) {
      spec$population$odds_ratios_xw <- as.list(unlist(spec$population$odds_ratios_xw)^s$scale)
      spec
    },
    group_moderator = function(spec, s) {
      r <- unlist(spec$population$r_xy)
      spec$population$r_xy <- as.list(mean(r) + s$scale * (r - mean(r)))
      spec
    },
    # The interaction's part of each cell's log-odds (the cell less its
    # row and column means, plus the grand mean) multiplied by the scale.
    logistic_factorial = function(spec, s) {
      l <- stats::qlogis(do.call(rbind, lapply(spec$population$probabilities, unlist)))
      ab <- l - outer(rowMeans(l), colMeans(l), "+") + mean(l)
      p <- stats::plogis(l + (s$scale - 1) * ab)
      spec$population$probabilities <- lapply(seq_len(nrow(p)), function(i) as.list(p[i, ]))
      spec
    }
  )
  jonckheere <- function() {
    spec <- example_spec("anova_oneway_between")
    spec$target_test$method <- "jonckheere_terpstra"
    spec$target_test$alternative <- "greater"
    spec$population$score_shape <- "normal"
    spec
  }
  for (name in names(set_found)) {
    spec <- if (name == "jonckheere") jonckheere() else example_spec(name)
    if (name == "logistic_factorial") spec$target_test$effect <- "interaction"
    n <- switch(name, jonckheere = 99L, logistic_factorial = 600L, group_moderator = 300L, its = 24L, logistic_interaction = 400L, poisson_interaction = 400L,
      multinomial_regression = 400L, multinomial_interaction = 400L, regression_interaction_binary = 300L, 100L)
    spec$goal <- list(type = "sensitivity", n = n, power = 0.8)
    spec$options$nrep <- 500L
    result <- suppressWarnings(run_quietly(spec))
    s <- result$sensitivity
    expect_true(isTRUE(s$simulated) && s$effect_lower < s$effect && s$effect < s$effect_upper, label = name)
    # Power simulated afresh at the effect found, with more replications
    # and another seed.
    at <- set_found[[name]](spec, s)
    at$goal <- list(type = "power", n = n)
    at$options$nrep <- 4000L
    at$options$seed <- 99L
    expect_equal(suppressWarnings(run_quietly(at))$curve$power, 0.8, tolerance = 0.04, label = name)
    file <- withr::local_tempfile(fileext = ".R")
    writeLines(export_script(spec, result), file)
    out <- system2(file.path(R.home("bin"), "Rscript"), file, stdout = TRUE, stderr = TRUE)
    expect_true(any(grepl("^Reproduced powerkit's result", out)), label = name)
  }
  # The factorial logistic effect's size: for a main effect, the odds
  # ratio between the levels with the most and the fewest 'yes' on the
  # log-odds scale averaged over the other factor; for the interaction in
  # a 2 x 2 table, the ratio of the odds ratios.
  spec <- example_spec("logistic_factorial")
  l <- stats::qlogis(do.call(rbind, lapply(spec$population$probabilities, unlist)))
  plan <- simulated_search_plan(spec, 600L, 0.8)
  expect_equal(plan$effect(2), exp(2 * abs(diff(rowMeans(l)))))
  spec$variables$B$levels <- list("Doctor", "Friend")
  spec$population$probabilities <- list(list(0.3, 0.4), list(0.4, 0.45))
  spec$target_test$effect <- "interaction"
  odds <- function(p) p / (1 - p)
  ratio <- (odds(0.3) / odds(0.4)) / (odds(0.4) / odds(0.45))
  expect_equal(simulated_search_plan(spec, 600L, 0.8)$effect(1), max(ratio, 1 / ratio))
  # A time series tested on both changes scales the two together, so it
  # needs one of them.
  both <- example_spec("its")
  both$target_test$effect <- "both"
  both$population$level_change <- 0
  both$goal <- list(type = "sensitivity", n = 24L, power = 0.8)
  expect_error(validate_spec(both), "no effect pattern to scale")
  # A flat pattern of proportions has nothing to scale.
  flat <- example_spec("proportion_trend")
  flat$population$proportions <- list(0.3, 0.3, 0.3, 0.3)
  flat$goal <- list(type = "sensitivity", n = 100L, power = 0.8)
  expect_error(validate_spec(flat), "no effect pattern to scale")
})

test_that("the three-way interaction's smallest effect matches InteractionPoweR's own sample size there", {
  skip_on_cran()
  spec <- example_spec("regression_three_way")
  spec$goal <- list(type = "sensitivity", n = 300L, power = 0.8)
  s <- run_quietly(spec)$sensitivity
  expect_identical(s$effect_name, "b_XWZ")
  expect_equal(s$power, 0.8, tolerance = 1e-6)
  at <- spec
  at$population$b_XWZ <- s$effect
  at$goal <- list(type = "sample_size", power = 0.8)
  expect_true(abs(run_quietly(at)$n_required$n - 300) <= 1)
  file <- withr::local_tempfile(fileext = ".R")
  writeLines(export_script(spec, run_quietly(spec)), file)
  out <- system2(file.path(R.home("bin"), "Rscript"), file, stdout = TRUE, stderr = TRUE)
  expect_true(any(grepl("^Reproduced powerkit's result", out)))
})
