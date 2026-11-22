# Two groups measured more than once with a count, yes/no or ordered
# outcome (mixed_model / repeated_glmm, E75, W between people and X
# within): the group-by-condition interaction, and the likelihood-ratio
# test a yes/no answer takes. The model without groups is tested in
# test-backend-glmm.R.

interaction_spec <- function(outcome = "poisson", method = "likelihood_ratio", n = 40L, nrep = 100L) {
  spec <- example_spec("repeated_glmm_interaction")
  if (outcome == "negative_binomial") spec$population$dispersion <- 0.5
  if (outcome == "yes_no") {
    spec$variables$Y <- list(type = "binary", label = "Any disruption")
    spec$population <- list(metric = "probability", probabilities = list(list(0.5, 0.5), list(0.5, 0.35)),
      sd_person = 0.5, measurements = 2L)
  }
  if (outcome == "ordinal") {
    spec$variables$Y <- list(type = "categorical", label = "Mood", levels = list("Low", "Middle", "High"))
    spec$population <- list(metric = "proportion", category_probabilities = list(0.3, 0.4, 0.3),
      odds_ratios = list(list(1, 1), list(1, 2)), sd_person = 0.5, measurements = 2L)
  }
  spec$target_test$method <- method
  spec$goal <- list(type = "power", n = n)
  spec$options <- list(nrep = nrep, seed = 7L)
  spec
}

test_that("with groups, the cells give the interaction model's fixed effects in glmer's coding", {
  inputs <- repeated_glmm_inputs(validate_quietly(interaction_spec()))
  expect_identical(inputs$term, "group:cond")
  expect_identical(inputs$df, 1L)
  expect_identical(inputs$fixef_names, c("(Intercept)", "groupProgramme", "condAfter", "groupProgramme:condAfter"))
  expect_equal(inputs$fixef, c(log(2), 0, 0, log(1.4 / 2)))
  # Three groups and three occasions: (3 - 1) * (3 - 1) interaction terms,
  # and the coefficients reproduce every cell.
  centre <- log(c(2, 2, 2, 2, 1.6, 1.4, 2, 1.8, 1.5))
  fixef <- repeated_glmm_fixef(c("T1", "T2", "T3"), c("A", "B", "C"), centre)
  cells <- repeated_glmm_cells(c("T1", "T2", "T3"), c("A", "B", "C"))
  expect_equal(as.numeric(stats::model.matrix(~ group * cond, cells) %*% fixef), centre)
  expect_equal(sum(grepl(":", names(fixef), fixed = TRUE)), 4)
  # The design: every person at every occasion, the people split equally.
  # 10 people, 5 in each group, each measured twice at each occasion.
  data <- repeated_glmm_design(inputs, 10)
  expect_equal(as.vector(table(data$group)), c(20, 20))
  expect_equal(as.vector(table(data$cond)), c(20, 20))
  expect_equal(length(unique(data$person[data$group == "Programme"])), 5)
  expect_equal(repeated_glmm_cell(data, 2)[data$group == "Programme" & data$cond == "After"][1], 4)
})

test_that("with groups, a Poisson run tests group:cond and its check run recovers the interaction", {
  old <- options(powerkit.cores = 1)
  on.exit(options(old))
  result <- suppressWarnings(run_spec(interaction_spec(n = 40L)))
  expect_match(result$provenance$backend_function, "fixed(\"group:cond\", \"lr\")", fixed = TRUE)
  expect_true(all(result$check_run$ok))
  expect_true(any(grepl("interaction", result$check_run$parameter, fixed = TRUE)))
})

test_that("with groups, the ordered-categories Wald test is of the interaction terms", {
  set.seed(4)
  data <- repeated_ordinal_data(400, c("Before", "After"), log(c(1, 1, 1, 2)), stats::qlogis(c(0.3, 0.7)), 0.5, 2L, FALSE,
    c("Usual teaching", "Programme"))
  fit <- repeated_ordinal_fit(y ~ group * cond + (1 | person), data)
  z <- summary(fit)$coefficients["groupProgramme:condAfter", "z value"]
  expect_equal(repeated_ordinal_wald(fit, 2, interaction = TRUE), stats::pchisq(z^2, 1, lower.tail = FALSE), tolerance = 1e-8)
})

test_that("with three groups, the ordered-categories Wald test has (groups - 1) x (conditions - 1) degrees of freedom", {
  # With df = conditions - 1 it rejected about 17% of null studies at
  # three groups (correctness review, 15 November 2026).
  set.seed(5)
  groups <- c("A", "B", "C")
  data <- repeated_ordinal_data(450, c("Before", "After"), rep(0, 6), stats::qlogis(c(0.3, 0.7)), 0.5, 2L, FALSE, groups)
  fit <- repeated_ordinal_fit(y ~ group * cond + (1 | person), data)
  terms <- grep(":", names(stats::coef(fit)), fixed = TRUE, value = TRUE)
  expect_length(terms, 2)
  b <- stats::coef(fit)[terms]
  w <- as.numeric(t(b) %*% solve(stats::vcov(fit)[terms, terms], b))
  expect_equal(repeated_ordinal_wald(fit, 2, interaction = TRUE), stats::pchisq(w, 2, lower.tail = FALSE), tolerance = 1e-8)
})

test_that("with three groups and no effect, the Wald test's false-positive rate is near alpha", {
  skip_unless_full_validation()
  rejections <- with_seed(11, vapply(seq_len(1000), function(i) p_repeated_ordinal(150, c("Before", "After"), rep(0, 6),
    stats::qlogis(c(0.3, 0.7)), 0.5, 2L, FALSE, method = "wald", groups = c("A", "B", "C")) < 0.05, logical(1)))
  expect_lt(abs(mean(rejections) - 0.05), 3 * sqrt(0.05 * 0.95 / 1000))
})

test_that("with groups, inputs that don't fit the design are refused", {
  spec <- interaction_spec()
  spec$population$rates <- list(list(2, 2), list(2))
  expect_spec_problem(spec, "needs one row per group of W")
  spec <- interaction_spec()
  spec$target_test$effect <- "condition"
  expect_spec_problem(spec, "the test is the group-by-condition interaction")
  spec <- interaction_spec()
  spec$variables$X$type <- "between_factor"
  expect_spec_problem(spec, "so its type is 'within_factor'")
  spec <- glmm_spec()
  spec$target_test$effect <- "interaction"
  expect_spec_problem(spec, "needs the groups")
  spec <- interaction_spec("ordinal")
  spec$population$odds_ratios <- list(list(1.2, 1), list(1, 2))
  expect_spec_problem(spec, "the first group's first condition is the one the others are compared with")
  # Every group changing alike is no interaction to detect.
  spec <- interaction_spec()
  spec$population$rates <- list(list(2, 1.4), list(2, 1.4))
  spec$goal <- list(type = "sample_size", power = 0.8)
  expect_error(validate_quietly(spec), class = "powerkit_spec_error")
})

test_that("with groups, the R script reproduces the run", {
  skip_unless_scripts_can_run()
  spec <- interaction_spec(n = 20L)
  out <- run_exported_script(spec, run_quietly(spec))
  expect_equal(out$reproduced, out$powerkit)
  spec <- interaction_spec("ordinal", method = "wald", n = 20L)
  out <- run_exported_script(spec, run_quietly(spec))
  expect_equal(out$reproduced, out$powerkit)
  spec <- interaction_spec("negative_binomial", method = "wald", n = 16L)
  out <- run_exported_script(spec, run_quietly(spec))
  expect_equal(out$reproduced, out$powerkit)
})

test_that("a yes/no outcome is tested by the likelihood ratio only; a count keeps the Wald test", {
  expect_spec_problem(glmm_spec("yes_no", method = "wald"), "the Wald test found a difference too often")
  expect_spec_problem(interaction_spec("yes_no", method = "wald"), "the Wald test found a difference too often")
  expect_silent(validate_quietly(glmm_spec("yes_no", method = "likelihood_ratio")))
  expect_silent(validate_quietly(glmm_spec("poisson", method = "wald")))
  # One answer per condition stays refused, with groups or without.
  once <- interaction_spec("yes_no")
  once$population$measurements <- 1L
  expect_spec_problem(once, "can't plan a test of whether the groups change differently")
})

test_that("a yes/no answer: the run also simulates the test with no difference, recording the rarest cell", {
  spec <- interaction_spec("yes_no", n = 40L, nrep = 40L)
  # 20 people a group, two answers each in each condition, the rarest cell
  # a 35% chance of yes: 20 x 2 x 0.35 = 14 of the rarer answer.
  expect_equal(repeated_glmm_rarest(repeated_glmm_inputs(spec), 40L), 14)
  spec$population$probabilities <- list(list(0.05, 0.05), list(0.05, 0.1))
  expect_equal(repeated_glmm_rarest(repeated_glmm_inputs(spec), 40L), 2)
  t1 <- suppressWarnings(repeated_glmm_type1(spec, 40L, 40L, 1L))
  expect_equal(t1$kind, "repeated_yes_no")
  expect_equal(t1$nrep, 40)
  expect_equal(t1$rarest, 2)
  expect_gte(t1$rate, 0)
  expect_lte(t1$rate, 1)
  # A near-certain answer is counted from its rarer side; a count has no record.
  spec$population$probabilities <- list(list(0.95, 0.95), list(0.95, 0.9))
  expect_equal(repeated_glmm_rarest(repeated_glmm_inputs(spec), 40L), 2)
  expect_null(repeated_glmm_type1(interaction_spec(), 40L, 40L, 1L))
})

test_that("a yes/no answer: the null model keeps the groups and conditions and drops only the tested terms", {
  spec <- interaction_spec("yes_no")
  spec$population$probabilities <- list(list(0.05, 0.08), list(0.06, 0.2))
  inputs <- repeated_glmm_inputs(spec)
  captured <- NULL
  local_mocked_bindings(simr_rejections = function(inputs, n, nrep, seed) {
    captured <<- inputs
    c(1, nrep, nrep, nrep)
  })
  t1 <- repeated_glmm_type1(spec, 40L, 20L, 1L)
  tested <- grepl(":", captured$fixef_names, fixed = TRUE)
  expect_equal(captured$fixef[tested], 0)
  expect_equal(captured$fixef[!tested], inputs$fixef[!tested])
  expect_equal(t1$rate, 1 / 20)
  # Without groups, every condition as the first.
  within <- glmm_spec("yes_no", values = c(0.04, 0.1), measurements = 2L, n = 30L)
  repeated_glmm_type1(within, 30L, 20L, 1L)
  expect_equal(captured$fixef[-1], 0)
  expect_equal(captured$fixef[1], stats::qlogis(0.04))
})
