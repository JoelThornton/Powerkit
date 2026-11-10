# Effects that vary between studies (Kenny & Judd, 2019): pwr's t-test
# power with Kenny and Judd's effective alpha and adjusted effect.

het_spec <- function(template = "independent_t", effect = 0.3, tau = 0.2, goal = list(type = "power", n = 100L),
                     method = NULL) {
  spec <- example_spec(template)
  field <- if (identical(template, "paired_t")) "dz" else "d"
  spec$population[[field]] <- effect
  spec$population$tau <- tau
  if (!is.null(method)) spec$target_test$method <- method
  spec$options$attrition <- NULL
  spec$goal <- goal
  spec
}

het_r_spec <- function(r = 0.3, tau = 0.1, goal = list(type = "power", n = 100L), method = "pearson") {
  spec <- example_spec("correlation")
  spec$population$r <- r
  spec$population$tau <- tau
  spec$target_test$method <- method
  spec$options$attrition <- NULL
  spec$goal <- goal
  spec
}

test_that("Kenny and Judd's worked example: mu 0.3, tau 0.2, 50 per group", {
  # Their text: q = 0.7071, critical t 1.4032, noncentrality 1.06066, power
  # .375 (against .318 with no heterogeneity), effective alpha about .16.
  result <- run_spec(het_spec(method = "student_t"))
  expect_equal(result$curve$power, 0.375, tolerance = 0.002)
  expect_equal(result$heterogeneity$q, sqrt(0.5), tolerance = 1e-6)
  expect_equal(result$heterogeneity$power_without, 0.318, tolerance = 0.002)
  expect_equal(result$heterogeneity$effective_alpha, 2 * pt(sqrt(0.5) * qt(0.975, 98), 98, lower.tail = FALSE))
  expect_equal(result$provenance$backend, "pwr")
  # Their appendix function, as printed, gives the same: positive and
  # negative tails.
  pow_ad <- function(mu, sigma, N, alph) {
    q <- sqrt((4 / N) / (4 / N + sigma^2)); cr <- qt(1 - alph / 2, N - 2) * q
    ncp <- mu / sqrt(4 / N + sigma^2)
    c(1 - pt(cr, N - 2, ncp), pt(-cr, N - 2, ncp))
  }
  expect_equal(result$curve$power, sum(pow_ad(0.3, 0.2, 100, 0.05)), tolerance = 1e-6)
})

test_that("with no variation it is the card's usual pwr answer", {
  usual <- run_spec(het_spec(tau = NULL, method = "student_t"))
  zero <- run_spec(het_spec(tau = 0, method = "student_t"))
  expect_equal(zero$curve$power, usual$curve$power)
  expect_null(zero$heterogeneity)
  tiny <- run_spec(het_spec(tau = 1e-8, method = "student_t"))
  expect_equal(tiny$curve$power, usual$curve$power, tolerance = 1e-6)
})

test_that("an independent simulation, drawing each study's true effect, agrees", {
  set.seed(20261108)
  simulate <- function(template, mu, tau, n, reps = 4000) {
    mean(vapply(seq_len(reps), function(i) {
      delta <- rnorm(1, mu, tau)
      p <- switch(template,
        independent_t = t.test(rnorm(n / 2, delta), rnorm(n / 2), var.equal = TRUE)$p.value,
        stats::t.test(rnorm(n, delta))$p.value)
      p < 0.05
    }, logical(1)))
  }
  for (case in list(list("independent_t", 0.4, 0.2, 100L), list("one_sample_t", 0.3, 0.125, 60L), list("paired_t", 0.5, 0.2, 40L))) {
    result <- run_spec(het_spec(case[[1]], case[[2]], case[[3]], list(type = "power", n = case[[4]]),
      method = if (case[[1]] == "independent_t") "student_t" else NULL))
    expect_equal(result$curve$power, simulate(case[[1]], case[[2]], case[[3]], case[[4]]), tolerance = 0.025,
      label = case[[1]])
  }
  # And with no average effect, a single study is significant about as
  # often as the effective alpha says.
  result <- run_spec(het_spec(effect = 0, tau = 0.2, goal = list(type = "power", n = 100L), method = "student_t"))
  expect_equal(result$heterogeneity$effective_alpha, simulate("independent_t", 0, 0.2, 100L), tolerance = 0.025)
})

test_that("variation between studies asks for more people when power is high, as Kenny and Judd show", {
  usual <- run_spec(het_spec(tau = NULL, goal = list(type = "sample_size", power = 0.8), method = "student_t"))
  varied <- run_spec(het_spec(tau = 0.1, goal = list(type = "sample_size", power = 0.8), method = "student_t"))
  expect_gt(varied$n_required$n, usual$n_required$n)
  # Below a half, it gives more power, not less.
  low <- run_spec(het_spec(effect = 0.2, tau = 0.2, goal = list(type = "power", n = 60L), method = "student_t"))
  expect_gt(low$curve$power, low$heterogeneity$power_without)
})

test_that("Welch's test with equal SDs is planned the same way", {
  welch <- run_spec(het_spec(method = "welch_t"))
  student <- run_spec(het_spec(method = "student_t"))
  expect_equal(welch$curve$power, student$curve$power)
  unequal <- het_spec(method = "welch_t")
  unequal$options$allocation_ratio <- 2
  unequal$goal$n <- 102L
  expect_error(run_spec(unequal), "currently requires equal group sizes", class = "powerkit_spec_error")
  unequal$population$tau <- 0
  expect_s3_class(validate_spec(unequal), "powerkit_spec")
})

test_that("a sensitivity target already reached at average zero has a plain explanation", {
  expect_error(run_spec(het_spec(effect = 0.3, tau = 1,
    goal = list(type = "sensitivity", n = 200L, power = 0.1), method = "student_t")),
    "already reached with an average effect of zero", class = "powerkit_run_error")
  expect_error(run_spec(het_r_spec(tau = 1,
    goal = list(type = "sensitivity", n = 200L, power = 0.1))),
    "already reached with an average effect of zero", class = "powerkit_run_error")
})

test_that("the smallest detectable average effect has the target power", {
  result <- run_spec(het_spec(goal = list(type = "sensitivity", n = 200L, power = 0.8), method = "student_t"))
  check <- run_spec(het_spec(effect = result$sensitivity$effect, goal = list(type = "power", n = 200L), method = "student_t"))
  expect_equal(check$curve$power, 0.8, tolerance = 1e-4)
  expect_gt(result$sensitivity$effect, run_spec(het_spec(tau = NULL, goal = list(type = "sensitivity", n = 200L, power = 0.8),
    method = "student_t"))$sensitivity$effect)
})

test_that("the R script gives the same power with pwr alone", {
  for (template in c("independent_t", "paired_t")) {
    spec <- het_spec(template, method = if (template == "independent_t") "student_t" else NULL)
    result <- run_spec(spec)
    script <- export_script(spec, result)
    env <- new.env()
    exprs <- parse(text = script)
    values <- lapply(exprs, eval, envir = env)
    power_line <- grep("$power", vapply(exprs, function(e) paste(deparse(e), collapse = ""), ""), fixed = TRUE)
    expect_length(power_line, 1)
    expect_equal(values[[power_line]], result$curve$power, tolerance = 1e-8, label = template)
  }
})

test_that("what can't be combined with it is refused in plain words", {
  expect_error(validate_spec(het_spec(tau = 3)), "at most 2")
  bad <- het_spec(method = "welch_t"); bad$population$sd_ratio <- 1.5
  expect_error(run_spec(bad), "equal SDs")
  sim <- het_spec(method = "student_t"); sim$options$method <- "simulation"
  expect_error(run_spec(sim), "Kenny and Judd's formula")
  two <- example_spec("two_proportions"); two$population$tau <- 0.1
  expect_error(run_spec(two), "tau")
  for (method in c("spearman", "kendall")) {
    rank <- het_r_spec(method = method)
    expect_error(run_spec(rank), "Pearson's correlation test", label = method)
  }
})

test_that("Departure 23: the cards' starting variation of 0.05 against none", {
  usual <- run_spec(het_spec(tau = NULL, goal = list(type = "sample_size", power = 0.8), method = "student_t"))
  small <- run_spec(het_spec(tau = 0.05, goal = list(type = "sample_size", power = 0.8), method = "student_t"))
  expect_equal(usual$n_required$n, 352)
  expect_equal(small$n_required$n, 376)
  at_100 <- run_spec(het_spec(tau = 0.05, method = "student_t"))
  expect_equal(at_100$curve$power, 0.323, tolerance = 0.002)
  expect_equal(at_100$heterogeneity$power_without, 0.318, tolerance = 0.002)
})

# A correlation: McShane and Bockenholt (2014, Appendix B), on Fisher's z.

test_that("a correlation with no variation is pwr.r.test's usual answer", {
  usual <- run_spec(het_r_spec(tau = NULL))
  zero <- run_spec(het_r_spec(tau = 0))
  tiny <- run_spec(het_r_spec(tau = 1e-8))
  expect_equal(usual$curve$power, pwr::pwr.r.test(n = 100, r = 0.3)$power)
  expect_equal(zero$curve$power, usual$curve$power)
  expect_equal(tiny$curve$power, usual$curve$power, tolerance = 1e-6)
})

test_that("a correlation's power is McShane and Bockenholt's normal model on Fisher's z", {
  # The estimate's Fisher z has SD sqrt(1 / (n - 3) + tau^2); the critical
  # z is the usual one. Written out directly, with pwr.r.test()'s z for r.
  direct <- function(r, tau, n, alpha = 0.05) {
    t <- qt(1 - alpha / 2, n - 2)
    zc <- atanh(t / sqrt(n - 2 + t^2))
    zr <- atanh(r) + r / (2 * (n - 1))
    s <- sqrt(1 / (n - 3) + tau^2)
    pnorm((zr - zc) / s) + pnorm((-zr - zc) / s)
  }
  for (case in list(c(0.3, 0.1, 100), c(0.1, 0.025, 800), c(-0.2, 0.15, 150))) {
    result <- run_spec(het_r_spec(case[1], case[2], list(type = "power", n = as.integer(case[3]))))
    expect_equal(result$curve$power, direct(case[1], case[2], case[3]), tolerance = 1e-8)
    expect_lt(result$curve$power, result$heterogeneity$power_without)
  }
  result <- run_spec(het_r_spec())
  expect_equal(result$heterogeneity$scale, "Fisher's z")
  expect_equal(result$heterogeneity$source, "McShane & Bockenholt (2014)")
})

test_that("an independent simulation, drawing each study's true correlation, agrees", {
  set.seed(20261109)
  simulate <- function(r, tau, n, reps = 4000) {
    mean(vapply(seq_len(reps), function(i) {
      rho <- tanh(rnorm(1, atanh(r), tau))
      x <- rnorm(n)
      y <- rho * x + sqrt(1 - rho^2) * rnorm(n)
      cor.test(x, y)$p.value < 0.05
    }, logical(1)))
  }
  result <- run_spec(het_r_spec(0.3, 0.1, list(type = "power", n = 100L)))
  expect_equal(result$curve$power, simulate(0.3, 0.1, 100L), tolerance = 0.025)
  null <- run_spec(het_r_spec(0, 0.15, list(type = "power", n = 100L)))
  expect_equal(null$heterogeneity$effective_alpha, simulate(0, 0.15, 100L), tolerance = 0.02)
})

test_that("a correlation's sample size and smallest detectable correlation", {
  usual <- run_spec(het_r_spec(r = 0.1, tau = NULL, goal = list(type = "sample_size", power = 0.8)))
  varied <- run_spec(het_r_spec(r = 0.1, tau = 0.025, goal = list(type = "sample_size", power = 0.8)))
  expect_gt(varied$n_required$n, usual$n_required$n)
  found <- run_spec(het_r_spec(goal = list(type = "sensitivity", n = 200L, power = 0.8)))
  check <- run_spec(het_r_spec(r = found$sensitivity$effect, goal = list(type = "power", n = 200L)))
  expect_equal(check$curve$power, 0.8, tolerance = 1e-4)
  expect_equal(found$sensitivity$effect_name, "r")
})

test_that("the correlation's R script gives the same power with pwr alone", {
  spec <- het_r_spec(r = -0.25, tau = 0.1)
  result <- run_spec(spec)
  script <- export_script(spec, result)
  env <- new.env()
  exprs <- parse(text = script)
  values <- lapply(exprs, eval, envir = env)
  power_line <- grep("$power", vapply(exprs, function(e) paste(deparse(e), collapse = ""), ""), fixed = TRUE)
  expect_length(power_line, 1)
  expect_equal(values[[power_line]], result$curve$power, tolerance = 1e-8)
})

test_that("Departure 24: the correlation card's starting variation of 0.025 against none", {
  n_for <- function(r, tau) run_spec(het_r_spec(r = r, tau = tau, goal = list(type = "sample_size", power = 0.8)))$n_required$n
  expect_equal(n_for(0.1, NULL), 782)
  expect_equal(n_for(0.1, 0.025), 904)
  expect_equal(n_for(0.3, NULL), 85)
  expect_equal(n_for(0.3, 0.025), 86)
})

test_that("the result shows the answer with no, small, medium and large variation", {
  result <- run_spec(het_spec(tau = 0.05, goal = list(type = "sample_size", power = 0.8), method = "student_t"))
  range <- result$heterogeneity$range
  expect_equal(range$level, c("none", "small", "medium", "large"))
  expect_equal(range$tau, c(0, 0.05, 0.125, 0.20))
  # Kenny and Judd's case, as in conventions.md: 352, 376, 522 and 830.
  expect_equal(range$value, c(352, 376, 522, 830))
  expect_equal(range$entered, c(FALSE, TRUE, FALSE, FALSE))
  expect_equal(result$heterogeneity$range_goal, "sample_size")
  # A value of the researcher's own is added in order.
  own <- run_spec(het_r_spec(tau = 0.1))$heterogeneity$range
  expect_equal(own$level, c("none", "small", "medium", "entered", "large"))
  expect_equal(own$tau, c(0, 0.025, 0.075, 0.1, 0.125))
  expect_equal(own$value[1], pwr::pwr.r.test(n = 100, r = 0.3)$power, tolerance = 1e-8)
  expect_true(all(diff(own$value) < 0))
  sens <- run_spec(het_spec(goal = list(type = "sensitivity", n = 200L, power = 0.8), method = "student_t"))$heterogeneity$range
  expect_true(all(diff(sens$value) > 0))
})
