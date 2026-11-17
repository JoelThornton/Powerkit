# Moderation with an outcome in three or more unordered categories
# (logistic_regression / multinomial_interaction, E32), simulated with
# Spower by powerkit's experiment p_multinomial_interaction(), which fits
# nnet's multinom(). Translation, the check run, refusals and the exported
# script; accuracy is checked by test-validation-multinomial-interaction.R.

mi_spec <- function(n = 300, nrep = 100, method = "likelihood_ratio", category = NULL, w_binary = FALSE) {
  spec <- example_spec("multinomial_interaction")
  spec$target_test$method <- method
  spec$target_test$category <- category
  if (w_binary) spec$variables$W <- list(type = "binary", label = "Sex", levels = list("Female", "Male"))
  spec$goal <- list(type = "power", n = n)
  spec$options <- list(seed = 7, nrep = nrep)
  spec
}

test_that("multinomial moderation runs on Spower with nnet, and passes its check run", {
  for (w_binary in c(FALSE, TRUE)) {
    result <- run_quietly(mi_spec(w_binary = w_binary))
    expect_equal(result$provenance$backend, "Spower")
    expect_match(result$provenance$backend_function, "p_multinomial_interaction", fixed = TRUE)
    expect_true("nnet" %in% names(result$provenance$packages))
    expect_true(all(result$check_run$ok))
    expect_equal(nrow(result$check_run), 8)
  }
})

test_that("multinomial moderation: the run is Spower's, replication for replication", {
  spec <- validate_spec(mi_spec())
  co <- multinomial_interaction_coefficients(spec)
  expect_equal(co$intercepts, log(c(0.3, 0.2) / 0.5))
  expect_equal(co$bxw, log(c(0.6, 0.9)))
  old <- options(powerkit.cores = 1)
  on.exit(options(old))
  result <- run_quietly(spec)
  intercepts <- co$intercepts
  bx <- co$bx
  bw <- co$bw
  bxw <- co$bxw
  set.seed(7)
  direct <- Spower::Spower(p_multinomial_interaction(n = 300, intercepts = intercepts, bx = bx, bw = bw,
    bxw = bxw, x_binary = TRUE, w_binary = FALSE, x_prob = 0.5, w_prob = 0.5, r = 0),
    replications = 100, verbose = FALSE)
  expect_equal(result$curve$power, direct$power)
})

test_that("multinomial moderation: the likelihood-ratio test has K - 1 df, and the Wald test is one category's x:w", {
  data <- with_seed(3, multinomial_interaction_data(400, log(c(0.3, 0.2) / 0.5), c(0.2, 0), c(0.1, 0), c(-0.5, 0),
    TRUE, FALSE, 0.5, 0.5, 0))
  full <- nnet::multinom(y ~ x * w, data = data, trace = FALSE, Hess = TRUE)
  reduced <- nnet::multinom(y ~ x + w, data = data, trace = FALSE)
  lr <- stats::pchisq(stats::deviance(reduced) - stats::deviance(full), df = 2, lower.tail = FALSE)
  p <- with_seed(3, p_multinomial_interaction(400, log(c(0.3, 0.2) / 0.5), c(0.2, 0), c(0.1, 0), c(-0.5, 0), TRUE, FALSE, 0.5, 0.5, 0))
  expect_equal(p, lr)
  fit <- summary(full)
  wald <- 2 * stats::pnorm(-abs(fit$coefficients[1, "x:w"] / fit$standard.errors[1, "x:w"]))
  p_wald <- with_seed(3, p_multinomial_interaction(400, log(c(0.3, 0.2) / 0.5), c(0.2, 0), c(0.1, 0), c(-0.5, 0), TRUE, FALSE,
    0.5, 0.5, 0, test = "wald_z", category = 2L))
  expect_equal(p_wald, wald)
})

test_that("multinomial moderation: refusals", {
  short <- mi_spec()
  short$population$odds_ratios_xw <- list(0.6, 0.9, 1)
  expect_spec_problem(short, "'population > odds_ratios_xw' needs one value for each category but the first")
  shares <- mi_spec()
  shares$population$probabilities <- list(0.5, 0.3, 0.3)
  expect_spec_problem(shares, "add up to 1.1")
  wald <- mi_spec(method = "wald_z")
  expect_spec_problem(wald, "name it in 'target_test > category'")
  stray <- mi_spec(category = "Online search")
  expect_spec_problem(stray, "Remove it.")
})

test_that("multinomial moderation: the exported script reproduces the run, for both tests", {
  for (method in c("likelihood_ratio", "wald_z")) {
    spec <- validate_spec(mi_spec(method = method, category = if (method == "wald_z") "Online search"))
    result <- run_quietly(spec)
    file <- tempfile(fileext = ".R")
    export_script(spec, result, file)
    output <- utils::capture.output(sys.source(file, envir = new.env()))
    expect_true(any(grepl("Reproduced powerkit's result", output, fixed = TRUE)), label = method)
  }
})
