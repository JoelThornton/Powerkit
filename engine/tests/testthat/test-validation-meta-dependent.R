# Validation: a meta-analysis whose studies each give several correlated
# effect sizes (E61, template dependent_effects). Backend: POMADE's
# power_MADE(), the CHE model with the RVE test.
#   1. analytic agreement: an independent simulation. Each study's average
#      true effect is drawn with SD tau, its effects with SD omega around
#      it, and their sampling errors with variance sigma2 and correlation
#      rho; each meta-analysis is fitted with metafor's rma.mv() under the
#      CHE model (the same working covariance, random effects for studies
#      and effects within them) and tested with metafor's robust() (cluster-
#      robust variance by study, the small-sample adjustment, J - 1 degrees
#      of freedom), without POMADE
#   2. published examples: a placeholder, for the maintainer
#   3. Type I error
# Expected values below are owned by the maintainer: do not edit them.
# Skipped unless POWERKIT_FULL_VALIDATION=true.

dependent_reps <- 1000L

dependent_spec <- function(population, seed, n) {
  validation_spec(
    design = "meta_analysis",
    template = "dependent_effects",
    variables = list(Y = validation_variable("continuous", "Outcome")),
    population = c(list(metric = "d"), population),
    target_test = list(effect = "mean_effect", method = "rve_t", alpha = 0.05),
    seed = seed,
    n = n
  )
}

dependent_by_hand <- function(p, J, nrep, seed) {
  sigma2 <- 4 / p$study_size + p$effect^2 / (2 * p$study_size)
  k <- p$effects_per_study
  block <- sigma2 * (p$rho + diag(1 - p$rho, k))
  V <- as.matrix(Matrix::bdiag(replicate(J, block, simplify = FALSE)))
  data <- data.frame(study = rep(seq_len(J), each = k), es = seq_len(J * k))
  with_seed(seed, mean(vapply(seq_len(nrep), function(i) {
    study_mean <- stats::rnorm(J, p$effect, p$tau)
    true <- stats::rnorm(J * k, study_mean[data$study], p$omega)
    data$yi <- true + as.vector(MASS::mvrnorm(1, rep(0, J * k), V))
    fit <- tryCatch(suppressWarnings(metafor::rma.mv(yi, V, random = ~ 1 | study / es, data = data)), error = function(e) NULL)
    if (is.null(fit)) return(FALSE)
    robust_fit <- tryCatch(metafor::robust(fit, cluster = data$study, adjust = TRUE), error = function(e) NULL)
    !is.null(robust_fit) && isTRUE(robust_fit$pval < 0.05)
  }, logical(1))))
}

dependent_population <- list(effect = 0.15, study_size = 40, effects_per_study = 4, tau = 0.1, omega = 0.05, rho = 0.6)

test_that("several effects per study: agrees with an independent simulation (analytic)", {
  skip_unless_full_validation()
  skip_if_not_installed("metafor")
  skip_if_not_installed("MASS")
  reference <- dependent_by_hand(dependent_population, J = 20, nrep = dependent_reps, seed = 6801)
  expect_power_near(engine_power(dependent_spec(dependent_population, seed = 6802, n = 20)), reference, reference_nrep = dependent_reps)
})

test_that("several effects per study: the independent simulation's Type I error is near alpha, as POMADE's power is with no effect", {
  skip_unless_full_validation()
  null <- modifyList(dependent_population, list(effect = 0))
  expect_equal(engine_power(dependent_spec(null, seed = 6803, n = 20))$power, 0.05, tolerance = 1e-8)
  rejected <- dependent_by_hand(null, J = 20, nrep = 2000L, seed = 6804)
  expect_lt(abs(rejected - 0.05), 3 * sqrt(0.05 * 0.95 / 2000))
})

test_that("several effects per study: matches a published example (published)", {
  skip_unless_full_validation()
  # Source: to be chosen by the maintainer (for example a worked example in
  # Vembye, Pustejovsky and Pigott's paper introducing POMADE's methods).
  # Transcribe the number of studies, effects per study, tau, omega, rho,
  # the sampling variance or study size, the average effect and the power.
  population <- TODO_PUBLISHED_VALUE
  n <- TODO_PUBLISHED_VALUE
  published_power <- TODO_PUBLISHED_VALUE
  skip_if_todo(population, n, published_power)
  expect_power_near(engine_power(dependent_spec(population, seed = 6805, n = n)), published_power, reference_nrep = Inf)
})
