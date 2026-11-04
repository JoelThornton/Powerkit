# Multinomial logistic regression of an outcome in three or more unordered
# categories on one predictor, simulated with Spower by powerkit's
# experiment p_multinomial(), which fits nnet's multinom(). Translation,
# the check run, refusals and the exported script; accuracy is checked by
# test-validation-multinomial.R.

mn_spec <- function(n = 300, nrep = 100, binary = FALSE, r2 = 0, method = "likelihood_ratio", category = NULL, odds_ratios = NULL) {
  spec <- example_spec("multinomial_regression")
  spec$target_test$method <- method
  spec$target_test$category <- category
  spec$population$r2_other_predictors <- if (r2 > 0) r2
  if (!is.null(odds_ratios)) {
    spec$population$probabilities_second <- NULL
    spec$population$odds_ratios <- as.list(odds_ratios)
  }
  if (binary) {
    spec$variables$X <- list(type = "binary", label = "Condition", levels = list("Leaflet", "Video"))
    spec$population$x_prob <- 0.4
  }
  spec$goal <- list(type = "power", n = n)
  spec$options <- list(seed = 7, nrep = nrep)
  spec
}

test_that("multinomial logistic regression runs on Spower with nnet, and passes its check run", {
  for (binary in c(FALSE, TRUE)) {
    result <- run_quietly(mn_spec(binary = binary, r2 = 0.2))
    expect_equal(result$provenance$backend, "Spower")
    expect_match(result$provenance$backend_function, "p_multinomial", fixed = TRUE)
    expect_true("nnet" %in% names(result$provenance$packages))
    expect_true(all(result$check_run$ok), info = binary)
    expect_equal(nrow(result$check_run), 5)
  }
  wald <- run_quietly(mn_spec(method = "wald_z", category = "Online search"))
  expect_match(wald$provenance$backend_function, "'Online search' against 'General practitioner'", fixed = TRUE)
})

test_that("on one core, it equals a direct Spower call of the experiment", {
  old <- options(powerkit.cores = 1)
  on.exit(options(old))
  intercepts <- log(c(0.3, 0.2) / 0.5)
  slopes <- log(c(0.38, 0.2) / 0.42) - intercepts
  set.seed(7)
  direct <- Spower::Spower(p_multinomial(n = 200, intercepts = intercepts, slopes = slopes, binary = FALSE,
    x_prob = 0.5, r2_other = 0, test = "likelihood_ratio"), replications = 100, verbose = FALSE)
  expect_equal(run_quietly(mn_spec(n = 200))$curve$power, direct$power)
})

test_that("the effect can be given as shares or as odds ratios, with the same model", {
  shares <- multinomial_coefficients(mn_spec())
  odds <- exp(shares$slopes)
  ratios <- multinomial_coefficients(mn_spec(odds_ratios = odds))
  expect_equal(ratios, shares)
  # The data have the spec's shares at both points, and the group sizes.
  spec <- mn_spec(binary = TRUE)
  cf <- multinomial_coefficients(spec)
  d <- with_seed(1, multinomial_data(1000, cf$intercepts, cf$slopes, TRUE, 0.3, 0))
  expect_equal(sum(d$x), 300)
  big <- with_seed(2, multinomial_data(2e5, cf$intercepts, cf$slopes, TRUE, 0.5, 0))
  expect_equal(as.numeric(prop.table(table(big$y[big$x == 0]))), c(0.5, 0.3, 0.2), tolerance = 0.02)
  expect_equal(as.numeric(prop.table(table(big$y[big$x == 1]))), c(0.42, 0.38, 0.2), tolerance = 0.02)
})

test_that("a data set with an empty category counts as not significant", {
  # A category almost nobody is in, at n = 20: most data sets lack it.
  set.seed(3)
  p <- replicate(20, p_multinomial(20, log(c(0.001, 0.5) / 0.499), c(0, 0), FALSE, 0.5, 0))
  expect_true(any(p == 1))
})

test_that("plain-English refusals for impossible or inconsistent multinomial specs", {
  spec <- mn_spec()
  spec$population$probabilities <- list(0.5, 0.3, 0.3)
  expect_spec_problem(spec, "add up to 1.1")
  spec <- mn_spec()
  spec$population$probabilities <- list(0.4, 0.3, 0.2, 0.1)
  expect_spec_problem(spec, "needs one share for each")
  spec <- mn_spec(odds_ratios = c(1.5, 1, 1))
  expect_spec_problem(spec, "needs one odds ratio for each category but the first")
  spec <- mn_spec()
  spec$population$odds_ratios <- list(1.5, 1)
  expect_spec_problem(spec, "Give the effect once")
  spec <- mn_spec()
  spec$population$probabilities_second <- NULL
  expect_spec_problem(spec, "Give the effect")
  expect_spec_problem(mn_spec(method = "wald_z"), "name it in 'target_test > category'")
  expect_spec_problem(mn_spec(method = "wald_z", category = "General practitioner"), "other than the first")
  expect_spec_problem(mn_spec(category = "Online search"), "only used by the Wald z test")
  spec <- mn_spec()
  spec$population$x_prob <- 0.3
  expect_spec_problem(spec, "x_prob")
  spec <- mn_spec()
  spec$target_test$alternative <- "greater"
  expect_error(validate_spec(spec), class = "powerkit_spec_error")
})

test_that("no effect is refused for a sample size, and the minimum n allows ten per coefficient", {
  spec <- mn_spec()
  spec$population$probabilities_second <- spec$population$probabilities
  spec$goal <- list(type = "sample_size", power = 0.8)
  expect_error(validate_spec(spec), class = "powerkit_spec_error")
  expect_equal(minimum_n(mn_spec()), 40)
})

test_that("the R script reproduces the run, and the simulated data have every category", {
  skip_unless_scripts_can_run()
  old <- options(powerkit.cores = 1)
  on.exit(options(old))
  spec <- mn_spec(n = 150, nrep = 100, binary = TRUE, r2 = 0.1, method = "wald_z", category = "Online search")
  out <- run_exported_script(spec, run_quietly(spec))
  expect_equal(out$reproduced, out$powerkit)
  expect_true(any(grepl("nnet::multinom(", out$script, fixed = TRUE)))
  spec <- mn_spec(n = 150, nrep = 100, odds_ratios = c(1.5, 1.2))
  out <- run_exported_script(spec, run_quietly(spec))
  expect_equal(out$reproduced, out$powerkit)
  spec$options$nrep <- 1000L
  data <- simulated_data(spec, 500)
  expect_equal(nrow(data), 500)
  expect_setequal(unique(data[[ncol(data)]]), c("General practitioner", "Online search", "Friends or family"))
})
