# A yes/no outcome on each trial (E33, E63 with Y binary): glmer through
# simr's makeGlmer(), the probabilities those of a typical participant and
# item, every SD on the log-odds scale.

binary_two <- function(method = "wald", goal = list(type = "power", n = 30L), nrep = 100L) {
  spec <- read_spec(system.file("specs", "crossed_two_condition.json", package = "powerkit"))
  spec$variables$Y <- list(type = "binary", label = "Correct")
  spec$population <- list(metric = "probability", probabilities = list(0.7, 0.8), sd_participant = 0.6,
    sd_participant_slope = 0.3, sd_item = 0.5, items = 40L, item_design = "between")
  spec$target_test$method <- method
  spec$goal <- goal
  spec$options <- list(nrep = nrep, seed = 4L)
  spec
}

binary_three <- function(effect = "condition", method = "wald", nrep = 100L) {
  spec <- example_spec("crossed_conditions")
  spec$variables$Y <- list(type = "binary", label = "Correct")
  spec$population <- list(metric = "probability", probabilities = list(0.7, 0.8, 0.75), sd_participant = 0.6,
    sd_participant_condition = 0.3, sd_item = 0.5, items = 60L, item_design = "between")
  spec$target_test <- c(list(effect = effect, method = method, alpha = 0.05),
    if (effect == "pairwise") list(comparison = list("Neutral", "Happy"), p_adjust = "holm"))
  spec$goal <- list(type = "power", n = 30L)
  spec$options <- list(nrep = nrep, seed = 4L)
  spec
}

# glmer is slow to fit, so the tests that need a run share one per design
# (on one core, as the direct simr call runs).
shared_binary_run <- function(make) {
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
run_two <- shared_binary_run(function() binary_two())
run_three <- shared_binary_run(function() binary_three())

test_that("two conditions, yes/no: the logistic model simr receives, and its tests", {
  inputs <- simr_inputs(validate_spec(binary_two()))
  expect_true(inputs$binary)
  expect_equal(inputs$fixef, c(mean(stats::qlogis(c(0.7, 0.8))), diff(stats::qlogis(c(0.7, 0.8)))))
  expect_s4_class(simr_model(inputs, 10), "glmerMod")
  expect_match(simr_backend(validate_spec(binary_two("likelihood_ratio")))$functions[["simulation"]], "fixed(\"cond\", \"lr\")", fixed = TRUE)
  result <- run_two()
  expect_true(all(result$check_run$ok))
  expect_match(result$provenance$backend_function, "fixed(\"cond\", \"z\")", fixed = TRUE)
  expect_false("residual SD" %in% result$check_run$parameter)
})

test_that("two conditions, yes/no: the test is simr's, replication for replication", {
  inputs <- simr_inputs(validate_spec(binary_two()))
  result <- run_two()
  direct <- suppressMessages(suppressWarnings(simr::powerSim(simr_model(inputs, 30), test = simr::fixed("cond", "z"),
    nsim = 100, seed = 4, progress = FALSE)))
  expect_equal(result$curve$power, direct$x / direct$n)
})

test_that("three conditions, yes/no: simr's Wald chi-square test, and a pair by car's Wald test or a likelihood ratio", {
  result <- run_three()
  expect_true(all(result$check_run$ok))
  expect_match(result$provenance$backend_function, "fixed(\"cond\", \"chisq\")", fixed = TRUE)
  expect_match(simr_backend(validate_spec(binary_three(method = "likelihood_ratio")))$functions[["simulation"]], "\"lr\"", fixed = TRUE)
  spec <- validate_spec(binary_three("pairwise", "wald"))
  inputs <- crossed_conditions_inputs(spec)
  data <- crossed_conditions_design(inputs, 30)
  data$y <- with_seed(2, stats::simulate(simr_model(inputs, 30))[[1]])
  fit <- lme4::glmer(inputs$formula, data = data, family = stats::binomial())
  # The pair Neutral-Happy is the treatment coefficient condHappy: car's
  # Wald test of it equals glmer's own z test, before the adjustment.
  inputs$p_adjust <- "none"
  expect_equal(crossed_conditions_test(inputs)(fit), summary(fit)$coefficients["condHappy", "Pr(>|z|)"], tolerance = 1e-8)
  # By likelihood ratio: the model against one in which Neutral and Happy
  # share a mean (the random terms keep every condition), by lme4's anova().
  inputs$method <- "lr"
  data$cond2 <- factor(ifelse(data$cond == "Happy", "Neutral", as.character(data$cond)), levels = c("Neutral", "Angry"))
  full <- lme4::glmer(inputs$formula, data = data, family = stats::binomial())
  reduced <- lme4::glmer(y ~ cond2 + (1 | participant) + (1 | participant:cond) + (1 | item), data = data, family = stats::binomial())
  expect_equal(crossed_conditions_test(inputs)(full), stats::anova(reduced, full)[["Pr(>Chisq)"]][2], tolerance = 1e-6)
})

test_that("a yes/no outcome refuses score inputs and the wrong test, in plain words", {
  spec <- binary_two()
  spec$population$sd_residual <- 1
  expect_spec_problem(spec, "no residual SD")
  expect_spec_problem(binary_two("satterthwaite_t"), "\"wald\" or \"likelihood_ratio\"")
  three <- binary_three()
  three$population$probabilities <- list(0.7, 0.8)
  expect_spec_problem(three, "each of the 3 conditions")
  same <- binary_two(goal = list(type = "sample_size", power = 0.8))
  same$population$probabilities <- list(0.7, 0.7)
  expect_error(validate_spec(same), class = "powerkit_spec_error")
})

test_that("the exported scripts and simulated data sets use glmer", {
  spec <- binary_two()
  expect_script_reproduces_power(spec, run_two())
  expect_true(any(grepl("makeGlmer", simulated_data_code(validate_spec(spec), 10, 1), fixed = TRUE)))
  three <- binary_three()
  expect_script_reproduces_power(three, run_three())
  expect_true(any(grepl("makeGlmer", simulated_data_code(validate_spec(three), 10, 1), fixed = TRUE)))
})
