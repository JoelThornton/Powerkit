# Validation: the same people measured more than once with a count or
# yes/no outcome (design "mixed_model", template "repeated_glmm", E75).
# Backend: simr's powerSim() on makeGlmer() (Poisson, logistic), testing
# cond with simr's Wald chi-square ("chisq", through car) or likelihood-
# ratio test; Spower running p_repeated_nb(), lme4's glmer.nb(), for a
# negative binomial count, or p_repeated_ordinal(), ordinal's clmm(), for
# ordered categories.
#   1. analytic agreement: an independent simulation. Each person's
#      intercept is drawn directly, each count or 0/1 response from its
#      distribution (a negative binomial count as a gamma mixture of
#      Poissons, not rnbinom(); an ordered answer by cutting a latent
#      logistic variable at the thresholds, not from the cumulative
#      probabilities), each data set fitted with lme4 (ordinal's clmm()
#      for ordered categories) and tested with summary()'s Wald z (two
#      conditions) or the likelihood ratio, without simr, car or Spower
#   2. Type I error with no difference between the conditions
#   3. published example: a placeholder, for the maintainer
# Generalised mixed models are slow to fit, so these use 1,000
# replications (glmer.nb(), slower still, 1,000 for the engine and 600 by
# hand).
# Expected values below are owned by the maintainer: do not edit them.
# Skipped unless POWERKIT_FULL_VALIDATION=true.

glmm_reps <- 1000L

glmm_validation_spec <- function(outcome, x, levels, values, sd_person, measurements, method, n, seed,
                                 dispersion = NULL, categories = NULL, nrep = glmm_reps) {
  count <- outcome %in% c("poisson", "negative_binomial")
  ordered <- outcome == "ordinal"
  population <- c(
    list(metric = if (ordered) "proportion" else if (count) "rate" else "probability"),
    if (ordered) list(category_probabilities = as.list(categories), odds_ratios = as.list(values)) else
      if (count) list(rates = as.list(values)) else list(probabilities = as.list(values)),
    list(sd_person = sd_person, measurements = measurements),
    if (!is.null(dispersion)) list(dispersion = dispersion)
  )
  y <- if (ordered) validation_variable("categorical", "Outcome", levels = as.list(paste0("c", seq_along(categories)))) else
    validation_variable(if (count) "count" else "binary", "Outcome")
  validation_spec(
    design = "mixed_model",
    template = "repeated_glmm",
    variables = list(
      X = validation_variable(x, "Condition", levels = as.list(levels)),
      Y = y
    ),
    population = population,
    target_test = list(effect = "condition", method = method, alpha = 0.05),
    seed = seed,
    n = n,
    options = list(nrep = nrep)
  )
}

# An independent simulation: rejections at alpha 0.05 in nrep studies.
glmm_by_hand <- function(outcome, between, values, sd_person, measurements, method, n, nrep, seed, dispersion = 0,
                         categories = NULL) {
  k <- length(values)
  per <- n / k
  eta <- if (outcome == "yes_no") stats::qlogis(values) else log(values)
  cuts <- if (outcome == "ordinal") stats::qlogis(cumsum(categories)[-length(categories)])
  rows <- if (between) {
    data.frame(person = rep(seq_len(n), each = measurements), c = rep(ceiling(seq_len(n) / per), each = measurements))
  } else {
    data.frame(person = rep(seq_len(n), each = k * measurements), c = rep(rep(seq_len(k), each = measurements), n))
  }
  fit_one <- function(formula, d) {
    tryCatch(suppressMessages(suppressWarnings(switch(outcome,
      negative_binomial = lme4::glmer.nb(formula, data = d),
      ordinal = ordinal::clmm(formula, data = d),
      poisson = lme4::glmer(formula, data = d, family = stats::poisson()),
      yes_no = lme4::glmer(formula, data = d, family = stats::binomial())))), error = function(e) NULL)
  }
  hits <- with_seed(seed, vapply(seq_len(nrep), function(i) {
    u <- stats::rnorm(n, sd = sd_person)
    linear <- eta[rows$c] + u[rows$person]
    d <- rows
    d$y <- switch(outcome,
      poisson = stats::rpois(nrow(d), exp(linear)),
      # Negative binomial with variance mu + k mu^2: a Poisson whose mean
      # is mu times a gamma with mean 1 and variance k.
      negative_binomial = stats::rpois(nrow(d), exp(linear) * stats::rgamma(nrow(d), shape = 1 / dispersion, scale = dispersion)),
      yes_no = stats::rbinom(nrow(d), 1, stats::plogis(linear)),
      # An ordered answer: the latent logistic variable linear + e, cut at
      # the thresholds (P(Y <= j) = plogis(cut_j - linear)).
      ordinal = factor(findInterval(linear + stats::rlogis(nrow(d)), cuts) + 1L, levels = seq_along(categories),
        ordered = TRUE))
    if (outcome == "ordinal") d$y <- droplevels(d$y)
    d$cond <- factor(d$c)
    d$person <- factor(d$person)
    fit <- fit_one(y ~ cond + (1 | person), d)
    if (is.null(fit)) return(FALSE)
    p_value <- if (method == "likelihood_ratio") {
      reduced <- fit_one(y ~ 1 + (1 | person), d)
      if (is.null(reduced)) return(FALSE)
      stats::pchisq(2 * (as.numeric(stats::logLik(fit)) - as.numeric(stats::logLik(reduced))), k - 1, lower.tail = FALSE)
    } else {
      summary(fit)$coefficients["cond2", "Pr(>|z|)"]
    }
    isTRUE(p_value < 0.05)
  }, logical(1)))
  list(power = mean(hits), mcse = sqrt(mean(hits) * (1 - mean(hits)) / nrep))
}

cases <- list(
  list(label = "Poisson count, two conditions within people, Wald", outcome = "poisson", between = FALSE,
    values = c(2, 1.6), sd_person = 0.5, measurements = 3, method = "wald", n = 40, reps = glmm_reps),
  list(label = "Poisson count, three conditions within people, likelihood ratio", outcome = "poisson", between = FALSE,
    values = c(2, 1.7, 1.6), sd_person = 0.5, measurements = 2, method = "likelihood_ratio", n = 40, reps = glmm_reps),
  list(label = "negative binomial count, two conditions within people, Wald", outcome = "negative_binomial", between = FALSE,
    values = c(3, 2.2), sd_person = 0.4, measurements = 2, method = "wald", n = 40, dispersion = 0.4, reps = 600L),
  list(label = "yes/no, three groups measured five times each, likelihood ratio", outcome = "yes_no", between = TRUE,
    values = c(0.3, 0.2, 0.2), sd_person = 0.6, measurements = 5, method = "likelihood_ratio", n = 90, reps = glmm_reps),
  list(label = "ordered categories, two conditions within people, Wald", outcome = "ordinal", between = FALSE,
    values = c(1, 1.8), sd_person = 0.8, measurements = 2, method = "wald", n = 40, categories = c(0.2, 0.3, 0.3, 0.2),
    reps = glmm_reps),
  list(label = "ordered categories, three groups measured three times each, likelihood ratio", outcome = "ordinal",
    between = TRUE, values = c(1, 1.6, 2.2), sd_person = 0.5, measurements = 3, method = "likelihood_ratio", n = 60,
    categories = c(0.3, 0.4, 0.3), reps = glmm_reps)
)

for (case in cases) {
  test_that(sprintf("repeated measures, %s: agrees with an independent simulation (analytic)", case$label), {
    skip_unless_full_validation()
    k <- length(case$values)
    spec <- glmm_validation_spec(case$outcome, if (case$between) "between_factor" else "within_factor",
      LETTERS[seq_len(k)], case$values, case$sd_person, case$measurements, case$method, case$n, seed = 7501,
      dispersion = case$dispersion, categories = case$categories)
    reference <- glmm_by_hand(case$outcome, case$between, case$values, case$sd_person, case$measurements,
      case$method, case$n, case$reps, seed = 7502, dispersion = case$dispersion %||% 0, categories = case$categories)
    expect_power_agrees_within(engine_power(spec), reference, allowance = 0)
  })
}

test_that("repeated measures: Type I error near alpha with no difference", {
  skip_unless_full_validation()
  # 1,000 replications: within 3 Monte Carlo SEs of 0.05.
  band <- 3 * sqrt(0.05 * 0.95 / glmm_reps)
  poisson <- engine_power(glmm_validation_spec("poisson", "within_factor", c("A", "B"), c(2, 2), 0.5, 3, "wald", 40, seed = 7503))
  expect_lt(abs(poisson$power - 0.05), band)
  # The negative binomial model with the likelihood-ratio test, the app's
  # default.
  nb <- engine_power(glmm_validation_spec("negative_binomial", "within_factor", c("A", "B"), c(3, 3), 0.4, 2,
    "likelihood_ratio", 40, seed = 7504, dispersion = 0.4))
  expect_lt(abs(nb$power - 0.05), band)
  # Ordered categories, the likelihood-ratio test.
  ordered <- engine_power(glmm_validation_spec("ordinal", "within_factor", c("A", "B"), c(1, 1), 0.8, 2,
    "likelihood_ratio", 40, seed = 7506, categories = c(0.2, 0.3, 0.3, 0.2)))
  expect_lt(abs(ordered$power - 0.05), band)
})

test_that("repeated measures: matches a published example (published)", {
  skip_unless_full_validation()
  # Source: to be chosen by the maintainer (a published power analysis for
  # a Poisson, negative binomial or logistic mixed model of repeated
  # measurements; source, section, page).
  values <- TODO_PUBLISHED_VALUE
  sd_person <- TODO_PUBLISHED_VALUE
  measurements <- TODO_PUBLISHED_VALUE
  n <- TODO_PUBLISHED_VALUE
  published_power <- TODO_PUBLISHED_VALUE
  reference_nrep <- TODO_PUBLISHED_VALUE
  skip_if_todo(values, sd_person, measurements, n, published_power, reference_nrep)
  spec <- glmm_validation_spec("poisson", "within_factor", c("A", "B"), values, sd_person, measurements, "wald", n, seed = 7505)
  expect_power_near(engine_power(spec), published_power, reference_nrep = reference_nrep)
})
