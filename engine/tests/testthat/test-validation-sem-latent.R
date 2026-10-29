# Validation: structural equation models with a restriction tested against
# the model without it, by the chi-square difference (likelihood ratio)
# test: measurement invariance across two groups (semPower.powerMI()), the
# correlation between two factors (semPower.powerCFA()) and one slope of a
# latent regression (semPower.powerRegression()), all by formula. Build
# guide section 6:
#   1. analytic agreement: the unit tests (test-backend-sempower.R) check
#      powerkit against each semPower function called directly, power and
#      required N, and the exported script against powerkit
#   2. published examples: below, to be transcribed by the maintainer
#   3. direct-call agreement with a simulation: below, semPower's own
#      simulated power (simulatedPower = TRUE), which fits the models to
#      simulated data with lavaan
#   4. Type I error: power is alpha when the restriction holds (unit tests)
# Expected values below are owned by the maintainer: do not edit them.
# Skipped unless POWERKIT_FULL_VALIDATION=true.

sem_latent_validation_spec <- function(template, population, alpha, seed, n = NULL, target_power = NULL,
                                       allocation_ratio = NULL) {
  effect <- switch(template, invariance = "invariance", factor_correlation = "factor_correlation",
                   latent_regression = "latent_slope")
  spec <- validation_spec(
    design = "sem",
    template = template,
    variables = stats::setNames(list(), character(0)), # an empty set of named fields
    population = population,
    target_test = list(effect = effect, method = "chi_square_difference", alpha = alpha),
    seed = seed,
    n = n,
    target_power = target_power
  )
  if (!is.null(allocation_ratio)) spec$options$allocation_ratio <- allocation_ratio
  spec
}

# 2. Published examples -------------------------------------------------------
#
# Source: to be chosen by the maintainer. Candidates: the worked examples
#   for semPower.powerMI(), semPower.powerCFA() and
#   semPower.powerRegression() in semPower's tutorial (Jobst, Bader &
#   Moshagen, 2023, Psychological Methods, doi 10.1037/met0000423) and
#   method paper (Moshagen & Bader, 2024, Behavior Research Methods, doi
#   10.3758/s13428-023-02254-7). Record the source, section and page here
#   when transcribing.
# Conventions to check against the source before transcribing:
#   * powerkit tests the restriction against the model without it
#     (semPower's comparison = "restricted"; for invariance, metric against
#     configural or scalar against metric), not against the saturated
#     model: a source comparing with the saturated model has more df.
#   * Invariance: powerkit's factor is identified in the first group only
#     (semPower's default, as lavaan does), loadings are standardised, and
#     intercept shifts are in item SD units.
#   * powerkit's n is the total number of participants analysed (for
#     invariance, both groups together).

test_that("SEM invariance: power matches a published worked example (published)", {
  skip_unless_full_validation()
  # Source: TODO (maintainer: source, section, page).
  level <- TODO_PUBLISHED_VALUE # "metric" or "scalar"
  indicators <- TODO_PUBLISHED_VALUE # items on the factor
  loading <- TODO_PUBLISHED_VALUE # loading in the first group
  noninvariant <- TODO_PUBLISHED_VALUE # items that differ
  difference <- TODO_PUBLISHED_VALUE # loading in group 2 (metric) or intercept shift (scalar)
  n <- TODO_PUBLISHED_VALUE # total sample size
  alpha <- TODO_PUBLISHED_VALUE # significance level
  published_power <- TODO_PUBLISHED_VALUE # power as printed
  skip_if_todo(level, indicators, loading, noninvariant, difference, n, alpha, published_power)

  population <- list(metric = "invariance", level = level, indicators = indicators,
                     loading = loading, noninvariant = noninvariant)
  if (identical(level, "metric")) population$loading_group2 <- difference else population$intercept_difference <- difference
  spec <- sem_latent_validation_spec("invariance", population, alpha, seed = 331, n = n)
  expect_power_exact(engine_power(spec), published_power)
})

test_that("SEM factor correlation: required N matches a published worked example (published)", {
  skip_unless_full_validation()
  # Source: TODO (maintainer: source, section, page).
  r <- TODO_PUBLISHED_VALUE # correlation between the factors
  indicators <- TODO_PUBLISHED_VALUE # items per factor, two numbers
  loadings <- TODO_PUBLISHED_VALUE # loading per factor, two numbers
  alpha <- TODO_PUBLISHED_VALUE # significance level
  target_power <- TODO_PUBLISHED_VALUE # target power
  published_n <- TODO_PUBLISHED_VALUE # required sample size as printed
  skip_if_todo(r, indicators, loadings, alpha, target_power, published_n)

  population <- list(metric = "factor_correlation", r = r, indicators = as.list(indicators), loadings = as.list(loadings))
  spec <- sem_latent_validation_spec("factor_correlation", population, alpha, seed = 332, target_power = target_power)
  expect_equal(engine_n_required(spec)$n, published_n)
})

test_that("SEM latent regression: required N matches a published worked example (published)", {
  skip_unless_full_validation()
  # Source: TODO (maintainer: source, section, page).
  slopes <- TODO_PUBLISHED_VALUE # standardised slopes
  predictor_correlation <- TODO_PUBLISHED_VALUE # correlation between the predictors
  indicators <- TODO_PUBLISHED_VALUE # items per factor
  loading <- TODO_PUBLISHED_VALUE # loading of every item
  alpha <- TODO_PUBLISHED_VALUE # significance level
  target_power <- TODO_PUBLISHED_VALUE # target power
  published_n <- TODO_PUBLISHED_VALUE # required sample size as printed
  skip_if_todo(slopes, predictor_correlation, indicators, loading, alpha, target_power, published_n)

  population <- list(metric = "standardised_slopes", slopes = as.list(slopes),
                     predictor_correlation = predictor_correlation, indicators = indicators, loading = loading)
  spec <- sem_latent_validation_spec("latent_regression", population, alpha, seed = 333, target_power = target_power)
  expect_equal(engine_n_required(spec)$n, published_n)
})

# 3. Agreement with semPower's simulated power ------------------------------

test_that("SEM factor correlation and invariance: formula power agrees with simulation (semPower, and lavaan directly) (direct call)", {
  skip_unless_full_validation()
  set.seed(334)
  population <- list(metric = "factor_correlation", r = 0.2, indicators = list(4, 5), loadings = list(0.6, 0.7))
  spec <- sem_latent_validation_spec("factor_correlation", population, 0.05, seed = 334, n = 300)
  simulated <- semPower::semPower.powerCFA(
    type = "post-hoc", Phi = 0.2, nIndicator = c(4, 5), loadM = c(0.6, 0.7), alpha = 0.05, N = 300,
    simulatedPower = TRUE, simOptions = list(nReplications = 1000)
  )$power
  # 1,000 replications: Monte Carlo SE at most 0.016.
  expect_lt(abs(engine_power(spec)$power - simulated), 0.05)

  population <- list(metric = "invariance", level = "metric", indicators = 6, loading = 0.7,
                     noninvariant = 2, loading_group2 = 0.5)
  spec <- sem_latent_validation_spec("invariance", population, 0.05, seed = 335, n = 400)
  # semPower 2.2.0's own simulation stops for a multigroup comparison with
  # the configural model ("length of 'dimnames' [2] not equal to array
  # extent", in its internal simulate(); docs/upstream-questions.md), so
  # the same test is simulated directly with lavaan: two groups of 200 from
  # the standardised population (residual variances 1 - loading^2), the
  # configural and the metric model fitted to each data set, and the
  # chi-square difference test at alpha.
  loadings <- list(rep(0.7, 6), c(0.7, 0.7, 0.7, 0.7, 0.5, 0.5))
  population_model <- function(l) {
    paste0(
      "f =~ ", paste0(l, "*x", 1:6, collapse = " + "), "\n",
      paste0("x", 1:6, " ~~ ", 1 - l^2, "*x", 1:6, collapse = "\n"), "\nf ~~ 1*f"
    )
  }
  analysis_model <- paste0("f =~ ", paste0("x", 1:6, collapse = " + "))
  rejected <- vapply(seq_len(1000), function(i) {
    data <- rbind(
      cbind(lavaan::simulateData(population_model(loadings[[1]]), sample.nobs = 200), g = 1),
      cbind(lavaan::simulateData(population_model(loadings[[2]]), sample.nobs = 200), g = 2)
    )
    configural <- lavaan::cfa(analysis_model, data = data, group = "g")
    metric <- lavaan::cfa(analysis_model, data = data, group = "g", group.equal = "loadings")
    lavaan::lavTestLRT(configural, metric)[["Pr(>Chisq)"]][2] < 0.05
  }, logical(1))
  simulated <- mean(rejected)
  expect_lt(abs(engine_power(spec)$power - simulated), 0.05)
})
