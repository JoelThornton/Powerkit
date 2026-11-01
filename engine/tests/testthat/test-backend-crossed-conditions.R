# Participants and items in three or more conditions (mixed_model /
# crossed_conditions, E63): simr's powerSim() with lmerTest's
# Satterthwaite F test, or one pair's Satterthwaite t test adjusted for all
# the pairs.

conditions_spec <- function(effect = "pairwise", item_design = "between", goal = list(type = "power", n = 30L), nrep = 100L) {
  spec <- example_spec("crossed_conditions")
  spec$population$item_design <- item_design
  if (identical(item_design, "within")) {
    spec$population$items <- 20L
    spec$population$sd_item_condition <- 10
  }
  if (identical(effect, "condition")) {
    spec$target_test <- list(effect = "condition", method = "satterthwaite_f", alpha = 0.05)
  }
  spec$goal <- goal
  spec$options <- list(nrep = nrep, seed = 9L)
  spec
}

test_that("the model and design simr receives: a mean per condition, items split equally or in every condition", {
  inputs <- crossed_conditions_inputs(validate_spec(conditions_spec()))
  expect_identical(deparse1(inputs$formula), "y ~ cond + (1 | participant) + (1 | participant:cond) + (1 | item)")
  expect_equal(inputs$fixef, c(600, -20, -10))
  data <- crossed_conditions_design(inputs, 4)
  expect_equal(nrow(data), 4 * 60)
  expect_equal(as.vector(table(data$cond)), rep(80, 3))
  expect_equal(as.vector(tapply(as.integer(data$cond), data$item, function(x) length(unique(x)))), rep(1, 60))
  inputs <- crossed_conditions_inputs(validate_spec(conditions_spec(item_design = "within")))
  expect_match(deparse1(inputs$formula), "(1 | item:cond)", fixed = TRUE)
  expect_equal(nrow(crossed_conditions_design(inputs, 4)), 4 * 20 * 3)
})

test_that("the test is the Satterthwaite F test, or the chosen pair's t test with its adjustment for all the pairs", {
  spec <- validate_spec(conditions_spec())
  inputs <- crossed_conditions_inputs(spec)
  model <- simr_model(inputs, 30)
  data <- crossed_conditions_design(inputs, 30)
  data$y <- with_seed(1, stats::simulate(model)[[1]])
  fit <- lmerTest::lmer(inputs$formula, data = data)
  # The three pairs' Satterthwaite t tests, by lmerTest's own difference
  # of least-squares means, adjusted by Holm's method.
  lsm <- lmerTest::difflsmeans(fit, which = "cond", ddf = "Satterthwaite")
  holm <- stats::p.adjust(lsm[["Pr(>|t|)"]], "holm")
  expect_equal(crossed_conditions_test(inputs)(fit), holm[[1]], tolerance = 1e-8)
  for (adjust in c("none", "bonferroni")) {
    inputs$p_adjust <- adjust
    expect_equal(crossed_conditions_test(inputs)(fit), stats::p.adjust(lsm[["Pr(>|t|)"]], adjust)[[1]], tolerance = 1e-8)
  }
  overall <- crossed_conditions_inputs(validate_spec(conditions_spec("condition")))
  expect_equal(crossed_conditions_test(overall)(fit), stats::anova(fit, ddf = "Satterthwaite")["cond", "Pr(>F)"])
})

test_that("both tests run on simr, and the check run recovers the population", {
  for (effect in c("pairwise", "condition")) {
    result <- suppressWarnings(run_spec(conditions_spec(effect)))
    expect_identical(result$provenance$backend, "simr")
    expect_true(all(result$check_run$ok), label = effect)
  }
  result <- suppressWarnings(run_spec(conditions_spec("condition", item_design = "within", nrep = 100L)))
  expect_true("SD of item-by-condition effects" %in% result$check_run$parameter)
  expect_true(all(result$check_run$ok))
})

test_that("impossible designs are refused in plain English", {
  wrong <- conditions_spec()
  wrong$population$means <- list(600, 580)
  expect_spec_problem(wrong, "one mean per condition")
  odd <- conditions_spec()
  odd$population$items <- 62L
  expect_spec_problem(odd, "multiple of 3")
  pair <- conditions_spec()
  pair$target_test$comparison <- list("Neutral", "Sad")
  expect_spec_problem(pair, "two different conditions")
  same <- conditions_spec(goal = list(type = "sample_size", power = 0.8))
  same$population$means <- list(600, 600, 590)
  expect_error(validate_spec(same), class = "powerkit_spec_error")
})

test_that("the exported script reproduces the result with simr alone, and the data set has a row per participant and item", {
  spec <- conditions_spec(nrep = 100L)
  expect_script_reproduces_power(spec, suppressWarnings(run_spec(spec)))
  code <- simulated_data_code(validate_spec(spec), 10, 1)
  expect_true(any(grepl("one block per condition", code, fixed = TRUE)))
})

test_that("adjusting a pair for all the pairs costs power: none, then Holm, then Bonferroni (Departure 17)", {
  # On the same data sets each adjusted p is at least the one before, so
  # the rejections can only fall. Over 1,000 data sets at 40 participants:
  # 38.3%, 25.0% and 24.4% (docs/conventions.md, 17).
  spec <- validate_spec(conditions_spec(goal = list(type = "power", n = 40L)))
  inputs <- crossed_conditions_inputs(spec)
  model <- simr_model(inputs, 40)
  power <- vapply(c("none", "holm", "bonferroni"), function(adjust) {
    inputs$p_adjust <- adjust
    r <- suppressMessages(suppressWarnings(simr::powerSim(model, test = crossed_conditions_test(inputs), nsim = 60,
                                                          seed = 21, progress = FALSE)))
    r$x / r$n
  }, numeric(1))
  expect_gte(power[["none"]], power[["holm"]])
  expect_gte(power[["holm"]], power[["bonferroni"]])
})

# Three or more conditions between participants (X a between factor) -------

between_conditions_spec <- function(item_design = "within", goal = list(type = "power", n = 30L), nrep = 100L) {
  spec <- conditions_spec(item_design = item_design, goal = goal, nrep = nrep)
  spec$variables$X$type <- "between_factor"
  spec$population$sd_participant_condition <- NULL
  spec
}

test_that("conditions between participants: a participant intercept only, the participants split equally", {
  inputs <- crossed_conditions_inputs(validate_spec(between_conditions_spec("within")))
  expect_identical(deparse1(inputs$formula), "y ~ cond + (1 | participant) + (1 | item) + (1 | item:cond)")
  data <- crossed_conditions_design(inputs, 9)
  expect_equal(nrow(data), 9 * 20)
  expect_equal(as.vector(tapply(as.integer(data$cond), data$participant, function(x) length(unique(x)))), rep(1, 9))
  expect_equal(as.vector(table(tapply(as.integer(data$cond), data$participant, unique))), rep(3, 3))
  inputs <- crossed_conditions_inputs(validate_spec(between_conditions_spec("between")))
  data <- crossed_conditions_design(inputs, 9)
  # Each condition's own block of 20 items, each seen by its 3 participants.
  expect_equal(nrow(data), 9 * 20)
  expect_equal(as.vector(tapply(as.integer(data$cond), data$item, function(x) length(unique(x)))), rep(1, 60))
})

test_that("conditions between participants run, recover the population, and refuse what doesn't apply", {
  for (items in c("within", "between")) {
    result <- suppressWarnings(run_spec(between_conditions_spec(items)))
    expect_true(all(result$check_run$ok), label = items)
    expect_false("SD of participant-by-condition effects" %in% result$check_run$parameter)
  }
  expect_spec_problem(between_conditions_spec(goal = list(type = "power", n = 31L)), "3 equal groups")
  extra <- between_conditions_spec()
  extra$population$sd_participant_condition <- 10
  expect_spec_problem(extra, "every condition")
  missing <- conditions_spec()
  missing$population$sd_participant_condition <- NULL
  expect_spec_problem(missing, "sd_participant_condition")
  spec <- between_conditions_spec("between")
  expect_script_reproduces_power(spec, suppressWarnings(run_spec(spec)))
})
