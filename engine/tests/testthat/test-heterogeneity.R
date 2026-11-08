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
  expect_error(run_spec(bad), "SDs to be equal")
  sim <- het_spec(method = "student_t"); sim$options$method <- "simulation"
  expect_error(run_spec(sim), "Kenny and Judd's formula")
  corr <- example_spec("correlation"); corr$population$tau <- 0.1
  expect_error(run_spec(corr), "t-tests only|tau")
})
