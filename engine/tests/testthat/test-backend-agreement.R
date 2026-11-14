# Bland-Altman limits of agreement (design "reliability", template
# "bland_altman"): Spower simulating SimplyAgree's agreement_limit() (MOVER
# or Bland and Altman's intervals), and Lu et al.'s approximation from
# SimplyAgree's blandPowerCurve(). Translation, check run, refusals and the
# exported script; accuracy is checked by test-validation-agreement.R.

ba_spec <- function(n = 30, nrep = 100, method = "mover", bias = 0.5, sd = 2.5, margin = 8,
                    agree = NULL, alpha = 0.05) {
  spec <- example_spec("reliability_bland_altman")
  spec$population$bias <- bias
  spec$population$sd_difference <- sd
  spec$population$margin <- margin
  spec$target_test$method <- method
  spec$target_test$agree_level <- agree
  spec$target_test$alpha <- alpha
  spec$goal <- list(type = "power", n = n)
  spec$options <- list(seed = 7, nrep = nrep)
  spec
}

test_that("the limits of agreement are simulated with SimplyAgree, and pass their check run", {
  for (method in c("mover", "bland_altman")) {
    result <- run_quietly(ba_spec(method = method))
    expect_equal(result$provenance$backend, "SimplyAgree")
    expect_equal(result$provenance$method, "simulation")
    expect_match(result$provenance$backend_function,
      sprintf("loa_calc = \"%s\"", bland_altman_loa_calc(method)), fixed = TRUE)
    expect_true(all(c("SimplyAgree", "Spower") %in% names(result$provenance$packages)))
    expect_true(all(result$check_run$ok))
  }
})

test_that("on one core, the simulation equals a direct Spower call of the experiment", {
  old <- options(powerkit.cores = 1)
  on.exit(options(old))
  # Spower evaluates the call in its own frame, so the values are written in.
  set.seed(7)
  direct <- Spower::Spower(p_bland_altman(n = 30, bias = 0.5, sd = 2.5, margin = 8, agree = 0.95, alpha = 0.05,
    loa_calc = "mover"), replications = 100, verbose = FALSE)
  expect_equal(run_quietly(ba_spec())$curve$power, direct$power)
})

test_that("an experiment judges agreement by the outer ends of two-sided 1 - alpha intervals", {
  # agreement_limit()'s alpha is one-sided, so p_bland_altman() gives it
  # alpha / 2; its outer bounds are then those of 95% two-sided intervals.
  set.seed(3)
  y <- stats::rnorm(40)
  data <- data.frame(x = y + stats::rnorm(40, 0.5, 2.5), y = y)
  loa <- SimplyAgree::agreement_limit(x = "x", y = "y", data = data, loa_calc = "blandaltman",
    agree.level = 0.95, alpha = 0.025)$loa
  d <- data$x - data$y
  upper <- mean(d) + stats::qnorm(0.975) * stats::sd(d)
  # Bland and Altman's (1999) interval: SE of a limit sqrt(s^2 / n + z^2 s^2 / (2 (n - 1))).
  se <- stats::sd(d) * sqrt(1 / 40 + stats::qnorm(0.975)^2 / (2 * 39))
  expect_equal(loa$upper_loa_ci, upper + stats::qt(0.975, 39) * se, tolerance = 1e-6)
  set.seed(3)
  inside <- p_bland_altman(n = 40, bias = 0.5, sd = 2.5, margin = loa$upper_loa_ci + 0.01, agree = 0.95,
    alpha = 0.05, loa_calc = "blandaltman")
  expect_true(inside)
})

test_that("Lu et al.'s approximation is SimplyAgree's blandPowerCurve()", {
  result <- run_quietly(ba_spec(method = "lu_formula"))
  expect_equal(result$provenance$method, "exact")
  expect_match(result$provenance$backend_function, "blandPowerCurve()", fixed = TRUE)
  direct <- SimplyAgree::blandPowerCurve(samplesizes = 30, mu = 0.5, SD = 2.5, delta = 8,
    conf.level = 0.95, agree.level = 0.95)
  expect_equal(result$curve$power, as.numeric(direct$power), tolerance = 1e-10)
  # Its 1 - beta1 - beta2 goes below 0 at small samples; powerkit reports 0.
  low <- bland_altman_lu_power(bland_altman_inputs(ba_spec(n = 10, margin = 5.5)), 10)
  expect_gte(low, 0)
  spec <- ba_spec(method = "lu_formula")
  spec$goal <- list(type = "sample_size", power = 0.8)
  n <- run_quietly(spec)$n_required$n
  power_at <- function(n) bland_altman_lu_power(bland_altman_inputs(spec), n)
  expect_gte(power_at(n), 0.8)
  expect_lt(power_at(n - 1), 0.8)
})

test_that("the agreement level and alpha reach the analysis", {
  inputs <- bland_altman_inputs(ba_spec(agree = 0.9, alpha = 0.1))
  expect_equal(inputs$z, stats::qnorm(0.95))
  expect_equal(inputs$alpha, 0.1)
  # Wider limits (99%) leave less room inside the margin, so less power.
  wide <- run_quietly(ba_spec(method = "lu_formula", agree = 0.99))$curve$power
  usual <- run_quietly(ba_spec(method = "lu_formula"))$curve$power
  expect_lt(wide, usual)
})

test_that("limits that already reach the margin, and a calculation method that doesn't fit, are refused", {
  # 0.5 + 1.96 * 4 = 8.34, beyond a margin of 8.
  expect_spec_problem(ba_spec(sd = 4), "the 95% limits of agreement themselves reach 8.34")
  spec <- ba_spec(method = "lu_formula")
  spec$options$method <- "simulation"
  expect_spec_problem(spec, "Lu et al.'s formula is not simulated")
  spec <- ba_spec()
  spec$options$method <- "exact"
  expect_spec_problem(spec, "The limits of agreement are simulated")
  spec <- ba_spec()
  spec$population$sd_difference <- 0
  expect_error(validate_quietly(spec))
  spec <- ba_spec(agree = 0.4)
  expect_error(validate_quietly(spec))
})

test_that("the R script reproduces the run", {
  spec <- ba_spec(n = 25, method = "bland_altman")
  out <- run_exported_script(spec, run_quietly(spec))
  expect_equal(out$reproduced, out$powerkit)
  spec <- ba_spec(method = "lu_formula")
  spec$goal <- list(type = "sample_size", power = 0.8)
  out <- run_exported_script(spec, run_quietly(spec))
  expect_equal(out$reproduced, out$powerkit)
})

test_that("the citations name SimplyAgree, and Lu et al. for their approximation", {
  text <- export_citations(run_quietly(ba_spec(method = "lu_formula")))
  expect_match(text, "Caldwell", fixed = TRUE)
  expect_match(text, "10.1515/ijb-2015-0039", fixed = TRUE)
  text <- export_citations(run_quietly(ba_spec(nrep = 100)))
  expect_match(text, "which runs the simulated studies whose limits of agreement SimplyAgree computes", fixed = TRUE)
  expect_false(grepl("Placeholder", text, fixed = TRUE) && grepl("SimplyAgree_method", text, fixed = TRUE))
})
