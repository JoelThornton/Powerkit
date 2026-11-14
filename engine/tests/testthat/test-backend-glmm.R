# The same people measured more than once with a count, yes/no or ordered
# outcome (mixed_model / repeated_glmm, E75): a Poisson or logistic mixed
# model through simr's makeGlmer(), or a negative binomial one fitted with
# glmer.nb(), or a cumulative link mixed model fitted with ordinal's
# clmm(), in a Spower simulation. Translation, check runs, refusals and
# the exported script; accuracy is checked by test-validation-glmm.R.

glmm_spec <- function(outcome = "poisson", x = "within_factor", levels = c("Usual", "With the programme"),
                      values = NULL, measurements = 3L, method = "wald", n = 40L, nrep = 100L) {
  spec <- example_spec("repeated_glmm")
  spec$variables$X$type <- x
  spec$variables$X$levels <- as.list(levels)
  pop <- list(sd_person = 0.5, measurements = measurements)
  if (outcome == "ordinal") {
    spec$variables$Y <- list(type = "categorical", label = "Mood", levels = list("Low", "Middle", "High", "Very high"))
    pop <- c(list(metric = "proportion", category_probabilities = list(0.2, 0.3, 0.3, 0.2),
      odds_ratios = as.list(values %||% c(1, seq(1.8, 1.4, length.out = length(levels) - 1)))), pop)
  } else if (outcome == "yes_no") {
    spec$variables$Y <- list(type = "binary", label = "Late")
    pop <- c(list(metric = "probability", probabilities = as.list(values %||% seq(0.3, 0.2, length.out = length(levels)))), pop)
  } else {
    pop <- c(list(metric = "rate", rates = as.list(values %||% seq(2, 1.6, length.out = length(levels)))), pop)
    if (outcome == "negative_binomial") pop$dispersion <- 0.4
  }
  spec$population <- pop
  spec$target_test <- list(effect = "condition", method = method, alpha = 0.05)
  spec$goal <- list(type = "power", n = n)
  spec$options <- list(nrep = nrep, seed = 5L)
  spec
}

# glmer is slow to fit, so the tests that need a run share one per model
# (on one core, as the direct calls run).
shared_glmm_run <- function(make) {
  result <- NULL
  function() {
    if (is.null(result)) {
      old <- options(powerkit.cores = 1)
      on.exit(options(old))
      result <<- suppressWarnings(run_spec(make()))
    }
    result
  }
}
run_poisson <- shared_glmm_run(function() glmm_spec())
run_nb <- shared_glmm_run(function() glmm_spec("negative_binomial", n = 30L))
run_ordinal <- shared_glmm_run(function() glmm_spec("ordinal", measurements = 2L, method = "likelihood_ratio", n = 30L))

test_that("a Poisson count: the model simr receives, its check run and its provenance", {
  inputs <- repeated_glmm_inputs(validate_spec(glmm_spec()))
  expect_equal(inputs$family, "poisson")
  expect_false(inputs$nb)
  expect_equal(inputs$fixef, c(log(2), log(1.6 / 2)))
  model <- simr_model(inputs, 10)
  expect_s4_class(model, "glmerMod")
  expect_equal(stats::family(model)$family, "poisson")
  # Every person in every condition, three times each.
  data <- repeated_glmm_design(inputs, 10)
  expect_equal(nrow(data), 10 * 2 * 3)
  expect_true(all(table(data$person, data$cond) == 3))
  result <- run_poisson()
  expect_equal(result$provenance$backend, "simr")
  expect_match(result$provenance$backend_function, "fixed(\"cond\", \"chisq\")", fixed = TRUE)
  expect_true(all(result$check_run$ok))
  expect_true("SD of person intercepts" %in% result$check_run$parameter)
})

test_that("a Poisson count: the run is simr's powerSim(), replication for replication", {
  inputs <- repeated_glmm_inputs(validate_spec(glmm_spec()))
  direct <- suppressMessages(suppressWarnings(simr::powerSim(simr_model(inputs, 40), test = simr::fixed("cond", "chisq"),
    nsim = 100, seed = 5, progress = FALSE)))
  expect_equal(run_poisson()$curve$power, direct$x / direct$n)
})

test_that("with two conditions, the Wald chi-square test is glmer's Wald z test", {
  inputs <- repeated_glmm_inputs(validate_spec(glmm_spec()))
  data <- repeated_glmm_design(inputs, 30)
  data$y <- with_seed(2, stats::simulate(simr_model(inputs, 30))[[1]])
  fit <- suppressMessages(lme4::glmer(y ~ cond + (1 | person), data = data, family = stats::poisson()))
  expect_equal(car::Anova(fit, type = 2)["cond", "Pr(>Chisq)"],
    summary(fit)$coefficients[2, "Pr(>|z|)"], tolerance = 1e-8)
})

test_that("a negative binomial count: Spower runs glmer.nb(), and its check run recovers k", {
  inputs <- repeated_glmm_inputs(validate_spec(glmm_spec("negative_binomial")))
  expect_true(inputs$nb)
  expect_equal(inputs$dispersion, 0.4)
  # The counts drawn are negative binomial: variance mu + k mu^2 given the
  # person (here with no person SD, so the mean is the rate).
  set.seed(1)
  big <- repeated_nb_data(4000, c("a", "b"), log(c(2, 2)), 0, 0.4, 1, FALSE)
  expect_equal(stats::var(big$y), 2 + 0.4 * 4, tolerance = 0.08)
  result <- run_nb()
  expect_equal(result$provenance$backend, "Spower")
  expect_match(result$provenance$backend_function, "glmer.nb()", fixed = TRUE)
  expect_true(all(c("Spower", "lme4") %in% names(result$provenance$packages)))
  expect_true(all(result$check_run$ok))
  expect_true(any(grepl("overdispersion", result$check_run$parameter)))
})

test_that("a negative binomial count: on one core, the run equals a direct Spower call", {
  old <- options(powerkit.cores = 1)
  on.exit(options(old))
  set.seed(5)
  direct <- Spower::Spower(p_repeated_nb(n = 30, levels = c("Usual", "With the programme"), centre = log(c(2, 1.6)),
    sd_person = 0.5, dispersion = 0.4, measurements = 3, between = FALSE, method = "wald"),
    sig.level = 0.05, replications = 100, parallel = FALSE, verbose = FALSE)
  expect_equal(run_nb()$curve$power, direct$power)
})

test_that("yes/no and three conditions between people: the logistic model and the design", {
  spec <- glmm_spec("yes_no", x = "between_factor", levels = c("A", "B", "C"), values = c(0.3, 0.25, 0.2),
    method = "likelihood_ratio", n = 30L)
  inputs <- repeated_glmm_inputs(validate_spec(spec))
  expect_equal(inputs$family, "binomial")
  expect_equal(inputs$simr_method, "lr")
  data <- repeated_glmm_design(inputs, 30)
  # Ten people in each condition, each measured three times in it.
  expect_equal(as.vector(table(data$cond)), c(30, 30, 30))
  expect_true(all(rowSums(table(data$person, data$cond) > 0) == 1))
  expect_equal(stats::family(simr_model(inputs, 30))$family, "binomial")
  backend <- repeated_glmm_backend(validate_spec(spec))
  expect_equal(backend$n_step, 3)
  expect_match(backend$functions[["simulation"]], "fixed(\"cond\", \"lr\")", fixed = TRUE)
})

test_that("the negative binomial likelihood-ratio test compares the models with and without cond", {
  set.seed(3)
  p <- p_repeated_nb(n = 20, levels = c("a", "b", "c"), centre = log(c(2, 2, 2)), sd_person = 0.3, dispersion = 0.3,
    measurements = 2, between = FALSE, method = "likelihood_ratio")
  set.seed(3)
  data <- repeated_nb_data(20, c("a", "b", "c"), log(c(2, 2, 2)), 0.3, 0.3, 2, FALSE)
  full <- suppressWarnings(suppressMessages(lme4::glmer.nb(y ~ cond + (1 | person), data = data)))
  reduced <- suppressWarnings(suppressMessages(lme4::glmer.nb(y ~ 1 + (1 | person), data = data)))
  expect_equal(p, stats::pchisq(2 * (as.numeric(stats::logLik(full)) - as.numeric(stats::logLik(reduced))), 2,
    lower.tail = FALSE), tolerance = 1e-8)
})

test_that("ordered categories: the thresholds, the data drawn and clmm()'s check run", {
  inputs <- repeated_glmm_inputs(validate_spec(glmm_spec("ordinal")))
  expect_true(inputs$ordinal)
  expect_false(inputs$binary)
  expect_equal(inputs$thresholds, stats::qlogis(c(0.2, 0.5, 0.8)))
  expect_equal(inputs$centre, log(c(1, 1.8)))
  # With no person SD, a typical person's answers in the first condition
  # fall in the categories in the shares given, and in the second
  # condition with odds of a higher category 1.8 times as high.
  set.seed(1)
  big <- repeated_ordinal_data(20000, c("a", "b"), log(c(1, 1.8)), inputs$thresholds, 0, 1, FALSE)
  first <- prop.table(table(big$y[big$cond == "a"]))
  expect_equal(as.vector(first), c(0.2, 0.3, 0.3, 0.2), tolerance = 0.03)
  below <- cumsum(prop.table(table(big$y[big$cond == "b"])))[1:3]
  expect_equal(as.vector(stats::qlogis(below)), stats::qlogis(c(0.2, 0.5, 0.8)) - log(1.8), tolerance = 0.05)
  result <- run_ordinal()
  expect_equal(result$provenance$backend, "Spower")
  expect_match(result$provenance$backend_function, "ordinal::clmm()", fixed = TRUE)
  expect_true(all(c("Spower", "ordinal") %in% names(result$provenance$packages)))
  expect_true(all(result$check_run$ok))
  expect_true(any(grepl("threshold", result$check_run$parameter)))
})

test_that("ordered categories: on one core, the run equals a direct Spower call", {
  old <- options(powerkit.cores = 1)
  on.exit(options(old))
  set.seed(5)
  direct <- Spower::Spower(p_repeated_ordinal(n = 30, levels = c("Usual", "With the programme"), centre = log(c(1, 1.8)),
    thresholds = stats::qlogis(c(0.2, 0.5, 0.8)), sd_person = 0.5, measurements = 2, between = FALSE,
    method = "likelihood_ratio"), sig.level = 0.05, replications = 100, parallel = FALSE, verbose = FALSE)
  expect_equal(run_ordinal()$curve$power, direct$power)
})

test_that("ordered categories: the Wald test is clmm()'s z with two conditions, and the LR test compares with and without cond", {
  set.seed(4)
  p <- p_repeated_ordinal(n = 40, levels = c("a", "b", "c"), centre = log(c(1, 1.5, 2)), thresholds = stats::qlogis(c(0.3, 0.6)),
    sd_person = 0.5, measurements = 2, between = FALSE, method = "likelihood_ratio")
  set.seed(4)
  data <- repeated_ordinal_data(40, c("a", "b", "c"), log(c(1, 1.5, 2)), stats::qlogis(c(0.3, 0.6)), 0.5, 2, FALSE)
  full <- ordinal::clmm(y ~ cond + (1 | person), data = data)
  reduced <- ordinal::clmm(y ~ 1 + (1 | person), data = data)
  expect_equal(p, stats::pchisq(2 * (as.numeric(stats::logLik(full)) - as.numeric(stats::logLik(reduced))), 2,
    lower.tail = FALSE), tolerance = 1e-6)
  two <- droplevels(data[data$cond != "c", ])
  fit <- repeated_ordinal_fit(y ~ cond + (1 | person), two)
  expect_equal(repeated_ordinal_wald(fit, 2), summary(fit)$coefficients["condb", "Pr(>|z|)"], tolerance = 1e-8)
})

test_that("designs the model can't estimate, and inputs that don't fit, are refused", {
  expect_spec_problem(glmm_spec(x = "between_factor", measurements = 1L), "the random intercept can't be estimated")
  expect_spec_problem(glmm_spec("yes_no", measurements = 1L), "McNemar's test")
  spec <- glmm_spec()
  spec$population$rates <- list(2, 1.8, 1.6)
  expect_spec_problem(spec, "'population > rates' has 3 values, but X has 2 conditions")
  spec <- glmm_spec("yes_no")
  spec$population$dispersion <- 0.2
  expect_spec_problem(spec, "a yes/no outcome has none")
  # No difference between the conditions: no sample size reaches a power.
  spec <- glmm_spec()
  spec$population$rates <- list(2, 2)
  spec$goal <- list(type = "sample_size", power = 0.8)
  expect_error(validate_quietly(spec))
  spec <- glmm_spec(x = "between_factor", n = 31L)
  expect_error(validate_quietly(spec))
  # Ordered categories.
  spec <- glmm_spec("ordinal")
  spec$population$category_probabilities <- list(0.2, 0.3, 0.3, 0.3)
  expect_spec_problem(spec, "adds up to 1.1")
  spec <- glmm_spec("ordinal", values = c(1.2, 1.8))
  expect_spec_problem(spec, "its odds ratio is 1")
  spec <- glmm_spec("ordinal", values = c(1, 1.5, 1.8))
  expect_spec_problem(spec, "'population > odds_ratios' has 3 values, but X has 2 conditions")
  spec <- glmm_spec("ordinal", x = "between_factor", measurements = 1L)
  expect_spec_problem(spec, "two groups compared on ordered categories")
  spec <- glmm_spec("ordinal")
  spec$population$rates <- list(2, 1.6)
  expect_spec_problem(spec, "for ordered categories give 'category_probabilities'")
})

test_that("the R script reproduces the run", {
  spec <- glmm_spec(n = 20L)
  out <- run_exported_script(spec, run_quietly(spec))
  expect_equal(out$reproduced, out$powerkit)
  spec <- glmm_spec("negative_binomial", method = "likelihood_ratio", n = 16L)
  out <- run_exported_script(spec, run_quietly(spec))
  expect_equal(out$reproduced, out$powerkit)
  spec <- glmm_spec("ordinal", x = "between_factor", levels = c("A", "B", "C"), values = c(1, 1.5, 2), method = "wald", n = 18L)
  out <- run_exported_script(spec, run_quietly(spec))
  expect_equal(out$reproduced, out$powerkit)
})
