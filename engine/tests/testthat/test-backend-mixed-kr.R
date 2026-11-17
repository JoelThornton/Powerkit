# Kenward and Roger's degrees of freedom as a choice beside Satterthwaite's
# on the simr mixed models with a score (17 November 2026):
# target_test.df_method = "kenward_roger" tests each simulated study with
# simr's method "kr" (pbkrtest), or, for three or more conditions, with
# lmerTest's ddf = "Kenward-Roger".

kr_spec <- function(template, nrep = 100L, seed = 11L, n = NULL, items = NULL) {
  spec <- example_spec(switch(template, two_level = "mixed_two_level", three_level = "mixed_three_level", template))
  spec$target_test$df_method <- "kenward_roger"
  # Kenward-Roger refits are slow: the runs below use small designs.
  if (!is.null(items)) spec$population$items <- items
  spec$options <- utils::modifyList(spec$options %||% list(), list(nrep = nrep, seed = seed))
  if (!is.null(n)) spec$goal <- list(type = "power", n = n)
  spec
}

test_that("Kenward-Roger reaches simr as its method \"kr\" on every mixed model with a score", {
  for (template in c("crossed_two_condition", "two_level", "three_level", "item_predictor")) {
    spec <- validate_spec(kr_spec(template))
    inputs <- switch(template, two_level = two_level_inputs(spec), three_level = three_level_inputs(spec),
      item_predictor = item_predictor_inputs(spec), simr_inputs(spec))
    expect_identical(inputs$method, "kr", label = template)
    sa <- spec
    sa$target_test$df_method <- NULL
    sa_inputs <- switch(template, two_level = two_level_inputs(sa), three_level = three_level_inputs(sa),
      item_predictor = item_predictor_inputs(sa), simr_inputs(sa))
    expect_identical(sa_inputs$method, "sa", label = template)
  }
  conditions <- validate_spec(kr_spec("crossed_conditions"))
  expect_identical(crossed_conditions_inputs(conditions)$ddf, "Kenward-Roger")
  expect_match(crossed_conditions_inputs(conditions)$test_label, "Kenward-Roger", fixed = TRUE)
})

# One shared Kenward-Roger run (seed 11, one core, as the direct simr call
# below runs): each refits 100 mixed models with pbkrtest's test, so the
# design is small (12 participants, 20 items).
kr_run <- local({
  result <- NULL
  function() {
    if (is.null(result)) {
      old <- options(powerkit.cores = 1)
      on.exit(options(old))
      result <<- suppressWarnings(run_spec(kr_spec("crossed_two_condition", n = 12L, items = 20L)))
    }
    result
  }
})

test_that("powerkit's Kenward-Roger simulation is simr's powerSim() with fixed(\"cond\", \"kr\"), replication for replication", {
  old <- options(powerkit.cores = 1)
  on.exit(options(old))
  spec <- kr_spec("crossed_two_condition", n = 12L, items = 20L)
  result <- kr_run()
  inputs <- simr_inputs(validate_spec(spec))
  direct <- suppressMessages(suppressWarnings(simr::powerSim(
    simr_model(inputs, 12), test = simr::fixed("cond", "kr"), nsim = 100, seed = 11, progress = FALSE
  )))
  expect_equal(result$curve$power, direct$x / direct$n)
  expect_true("pbkrtest" %in% names(result$provenance$packages))
  expect_match(result$provenance$backend_function, "\"kr\"", fixed = TRUE)
  expect_script_reproduces_power(spec, result)
})

test_that("with three or more conditions, the F test and a pair's t test use lmerTest's Kenward-Roger degrees of freedom", {
  # The example is one pair (Neutral against Happy, Holm); the F test of
  # any difference is the same design with effect "condition".
  pair <- validate_spec(kr_spec("crossed_conditions"))
  any_difference <- kr_spec("crossed_conditions")
  any_difference$target_test <- list(effect = "condition", method = "satterthwaite_f", alpha = 0.05,
    df_method = "kenward_roger")
  any_difference <- validate_spec(any_difference)
  inputs <- crossed_conditions_inputs(any_difference)
  model <- simr_model(inputs, 24L)
  data <- stats::model.frame(model)
  data$y <- with_seed(5, stats::simulate(model)[[1]])
  fit <- lmerTest::lmer(inputs$formula, data = data)
  expect_equal(crossed_conditions_test(inputs)(fit), stats::anova(fit, ddf = "Kenward-Roger")["cond", "Pr(>F)"])
  pair_inputs <- crossed_conditions_inputs(pair)
  k <- length(inputs$levels)
  pairs <- utils::combn(k, 2)
  p <- apply(pairs, 2, function(ij) {
    contrast <- numeric(k)
    contrast[ij[2]] <- 1
    if (ij[1] > 1) contrast[ij[1]] <- -1
    lmerTest::contest(fit, contrast, ddf = "Kenward-Roger")[["Pr(>F)"]]
  })
  at <- sort(pair_inputs$pair)
  chosen <- which(pairs[1, ] == at[1] & pairs[2, ] == at[2])
  expect_equal(crossed_conditions_test(pair_inputs)(fit), stats::p.adjust(p, "holm")[[chosen]])
})

test_that("the exported script reproduces a Kenward-Roger F test of three or more conditions", {
  spec <- kr_spec("crossed_conditions", n = 12L, items = 12L)
  spec$target_test <- list(effect = "condition", method = "satterthwaite_f", alpha = 0.05, df_method = "kenward_roger")
  result <- suppressWarnings(run_spec(spec))
  script <- export_script(spec, result)
  expect_true(any(grepl("ddf = \"Kenward-Roger\"", script, fixed = TRUE)))
  expect_script_reproduces_power(spec, result)
})

test_that("Kenward-Roger and Satterthwaite give similar power on the same simulated studies", {
  # Both correct the t test for few participants and items; on the same
  # 100 studies their decisions mostly agree.
  old <- options(powerkit.cores = 1)
  on.exit(options(old))
  kr <- kr_run()
  sa_spec <- kr_spec("crossed_two_condition", n = 12L, items = 20L)
  sa_spec$target_test$df_method <- "satterthwaite"
  sa <- suppressWarnings(run_spec(sa_spec))
  expect_lte(abs(kr$curve$power - sa$curve$power), 0.1)
})

test_that("the degrees-of-freedom choice is refused where it doesn't apply", {
  ttest <- example_spec("independent_t")
  ttest$target_test$df_method <- "kenward_roger"
  expect_spec_problem(ttest, "remove it here")
  binary <- example_spec("crossed_two_condition")
  binary$variables$Y$type <- "binary"
  binary$population <- list(metric = "probability", probabilities = list(0.7, 0.8), sd_participant = 0.6,
    sd_participant_slope = 0.3, sd_item = 0.5, items = 40L, item_design = "between")
  binary$target_test$method <- "wald"
  binary$target_test$df_method <- "kenward_roger"
  expect_spec_problem(binary, "Kenward and Roger's degrees of freedom are for a score")
})
