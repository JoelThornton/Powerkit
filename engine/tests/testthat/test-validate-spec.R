# Structural checks: the JSON schema, translated into plain English.

test_that("every bundled example spec is valid", {
  names <- example_spec_names()
  expect_gte(length(names), 14)
  for (name in names) {
    result <- tryCatch(
      {
        validate_spec(example_spec(name))
        "valid"
      },
      error = conditionMessage
    )
    expect_identical(result, "valid", label = name)
  }
})

test_that("there is an example for every template", {
  templates <- vapply(example_spec_names(), function(n) example_spec(n)$template, character(1))
  expect_setequal(unique(templates), c(
    "one_sample_t", "independent_t", "paired_t", "correlation",
    "two_proportions", "chi_square_independence", "2x2_between", "2x2_mixed",
    "two_way", "process_4", "process_6", "process_7", "process_14",
    # Wave 2 (engine only).
    "oneway_between", "one_proportion", "mcnemar", "r2_zero", "r2_increase",
    # One-way repeated measures.
    "oneway_within", "mixed", "factorial_between", "factorial_within", "factorial_ancova", "factorial_three",
    # More tests by formula (engine only).
    "chi_square_gof", "two_correlations", "oneway_ancova",
    "overlapping_correlations", "nonoverlapping_correlations",
    # Logistic regression (engine only).
    "single_predictor",
    # Poisson regression (engine only).
    "single_predictor_count",
    # Clustered designs (powertools).
    "cluster_randomised", "multisite", "group_treatment",
    # Structural equation model fit (semPower).
    "model_fit",
    # Planned comparisons (engine only).
    "oneway_contrast",
    # Variance tests, simulated (engine only).
    "one_variance", "two_variances",
    # Generic tests (engine only).
    "t", "f", "chi_square", "z",
    # Equivalence tests (TOST).
    "tost_independent", "tost_paired", "tost_one_sample"
  ))
})

test_that("a spec built in R validates and matches the same spec read from JSON", {
  from_file <- read_spec(example_path("anova_2x2_between"))
  built <- example_spec("anova_2x2_between")
  built$population$means <- matrix(c(10, 10, 10, 13), nrow = 2, byrow = TRUE)
  built$population$sd <- 6
  built$goal$power <- 0.9
  out <- expect_valid_spec(built)
  expect_identical(unclass(out), unclass(from_file))
})

test_that("validate_spec() accepts a file path or JSON string", {
  expect_s3_class(validate_spec(example_path("correlation")), "powerkit_spec")
})

test_that("a missing effect justification is explained", {
  spec <- example_spec("process_7")
  spec$effect_justification <- NULL
  expect_spec_problem(spec, "The spec is missing 'effect_justification'. Every power analysis needs a reason")
})

test_that("prior-study justifications need an adjustment", {
  spec <- example_spec("independent_t")
  spec$effect_justification <- list(type = "prior_study", source = "Earlier lab study")
  expect_spec_problem(spec, "'effect_justification' is missing 'adjustment'")
})

test_that("'none' records that no effect size can be justified, and the source is optional", {
  spec <- example_spec("independent_t")
  spec$effect_justification <- list(type = "none")
  expect_valid_spec(spec)
  spec$effect_justification <- list(type = "meta_analysis")
  expect_valid_spec(spec)
})

test_that("an empty justification source is rejected", {
  spec <- example_spec("independent_t")
  spec$effect_justification$source <- ""
  expect_spec_problem(spec, "'effect_justification > source' can't be empty.")
})

test_that("unknown designs and templates list the choices and suggest a fix", {
  spec <- example_spec("mediation_simple")
  spec$design <- "mediaton"
  expect_spec_problem(spec, "Did you mean 'mediation'?")

  spec <- example_spec("mediation_simple")
  spec$template <- "process_5"
  expect_spec_problem(spec, "'template' must be one of 'process_4' or 'process_6'; you wrote 'process_5'.")
})

test_that("misspelt fields are named, with a suggestion", {
  spec <- example_spec("correlation")
  names(spec)[names(spec) == "population"] <- "populaton"
  err <- expect_spec_problem(spec, "'populaton' is not a recognised field in the spec. Did you mean 'population'?")
  expect_match(err$problems, "The spec is missing 'population'.", fixed = TRUE, all = FALSE)
})

test_that("unexpected fields list what is allowed", {
  spec <- example_spec("independent_t")
  spec$population$sd <- 1
  expect_spec_problem(spec, "'sd' is not a recognised field in 'population'. Allowed here: metric, d, raw, score_shape, effect_sd.")
})

test_that("wrong value types are described in plain words", {
  spec <- example_spec("independent_t")
  spec$target_test$alpha <- "0.05"
  expect_spec_problem(spec, "'target_test > alpha' should be a number, but it is text ('0.05').")

  spec <- example_spec("independent_t")
  spec$options$nrep <- 1000.5
  expect_spec_problem(spec, "'options > nrep' should be a whole number, but it is a number with decimals (1000.5).")
})

test_that("a null or missing SD gives a plain-English problem, not a crash", {
  # Reported in PR #4: a null SD failed with "non-character argument".
  for (name in c("anova_2x2_between", "anova_2x2_mixed")) {
    spec <- example_spec(name)
    spec$population["sd"] <- list(NULL)
    expect_spec_problem(
      spec,
      "'population > sd' should be a number or a list ([ ... ]), but it is empty (null)."
    )

    spec <- example_spec(name)
    spec$population$sd <- NULL
    expect_spec_problem(spec, "'population' is missing 'sd'.")
  }

  # The same spec as JSON, as the app would send it.
  json <- sub(
    "\"sd\": 6", "\"sd\": null",
    paste(readLines(example_path("anova_2x2_between")), collapse = "\n"),
    fixed = TRUE
  )
  expect_spec_problem(json, "'population > sd' should be a number or a list ([ ... ]), but it is empty (null).")
})

test_that("a null SD where the design has no SD is named as not applicable", {
  spec <- example_spec("independent_t")
  spec$population["sd"] <- list(NULL)
  expect_spec_problem(spec, "'sd' is not a recognised field in 'population'.")
})

test_that("out-of-range values give the limit and the value", {
  spec <- example_spec("independent_t")
  spec$target_test$alpha <- 0.6
  expect_spec_problem(spec, "'target_test > alpha' must be at most 0.5; you wrote 0.6.")

  spec <- example_spec("correlation")
  spec$population$r <- 1
  expect_spec_problem(spec, "'population > r' must be less than 1; you wrote 1.")
})

test_that("percentages written where proportions are needed get a hint", {
  spec <- example_spec("process_7")
  spec$goal$power <- 90
  expect_spec_problem(spec, "Write power as a proportion: 90% is 0.9.")

  spec <- example_spec("process_7")
  spec$options$attrition <- 15
  expect_spec_problem(spec, "Write attrition as a proportion: 15% is 0.15.")
})

test_that("goal fields must match the goal type", {
  spec <- example_spec("independent_t")
  spec$goal <- list(type = "sample_size")
  expect_spec_problem(spec, "'goal' is missing 'power'.")

  spec$goal <- list(type = "power", power = 0.8)
  err <- expect_spec_problem(spec, "'goal' is missing 'n'.")
  expect_match(err$problems, "'goal > power' doesn't apply here when the goal type is 'power'; remove it.", fixed = TRUE, all = FALSE)

  spec$goal <- list(type = "sensitivity", n = 100)
  expect_spec_problem(spec, "'goal' is missing 'power'.")
})

test_that("variables must have the type the template needs", {
  spec <- example_spec("independent_t")
  spec$variables$X$type <- "continuous"
  expect_spec_problem(spec, "'variables > X > type' must be 'binary'; you wrote 'continuous'.")
})

test_that("missing and extra variables are reported", {
  spec <- example_spec("independent_t")
  spec$variables$Y <- NULL
  expect_spec_problem(spec, "'variables' is missing 'Y'.")

  spec <- example_spec("independent_t")
  spec$variables$W <- list(type = "continuous", label = "Age")
  expect_spec_problem(spec, "'W' is not a recognised field in 'variables'. Allowed here: X, Y.")
})

test_that("pattern-named variables are explained when a name is wrong", {
  spec <- example_spec("mediation_parallel")
  spec$variables$Mediator3 <- list(type = "continuous", label = "Stress")
  expect_spec_problem(spec, "Allowed here: X, Y, and mediators named M (one mediator) or M1, M2, ... (several).")
})

test_that("2x2 factors need exactly two levels", {
  spec <- example_spec("anova_2x2_between")
  spec$variables$A$levels <- list("None", "Praise", "Criticism")
  expect_spec_problem(spec, "'variables > A > levels' can have at most 2 entries; it has 3.")

  spec <- example_spec("anova_2x2_between")
  spec$variables$B$levels <- NULL
  expect_spec_problem(spec, "'variables > B' is missing 'levels'.")
})

test_that("one-sided tests are only allowed for directional basic tests", {
  spec <- example_spec("anova_2x2_between")
  spec$target_test$alternative <- "greater"
  expect_spec_problem(spec, "'target_test > alternative' must be 'two_sided'; you wrote 'greater'.")

  spec <- example_spec("independent_t")
  spec$target_test$alternative <- "greater"
  expect_valid_spec(spec)
})

test_that("an indirect path is required for mediation and refused elsewhere", {
  spec <- example_spec("mediation_simple")
  spec$target_test$path <- NULL
  expect_spec_problem(spec, "'target_test' is missing 'path'. Give the indirect path to test")

  spec <- example_spec("correlation")
  spec$target_test$path <- "X->Y"
  expect_spec_problem(spec, "'target_test > path' doesn't apply here (an indirect path is only given for mediation designs); remove it.")
})

test_that("spec_version is checked first, with a helpful message", {
  spec <- example_spec("correlation")
  spec$spec_version <- NULL
  expect_spec_problem(spec, "The spec is missing 'spec_version'.")

  spec$spec_version <- "1.3"
  expect_spec_problem(spec, "uses format version '1.3', but this version of powerkit reads version 0.1")
})

test_that("duplicated fields are rejected", {
  json <- paste(readLines(example_path("correlation")), collapse = "\n")
  json <- sub('"r": -0.2', '"r": -0.2, "r": 0.3', json, fixed = TRUE)
  expect_spec_problem(json, "'population' has 'r' more than once. Keep only one.")
})

test_that("all problems are reported together", {
  spec <- example_spec("process_7")
  spec$effect_justification <- NULL
  spec$goal$power <- 2
  spec$target_test$method <- "sobel"
  err <- expect_error(validate_spec(spec), class = "powerkit_spec_error")
  expect_length(err$problems, 3)
  expect_match(conditionMessage(err), "^This design spec has 3 problems:\n\\* ")
})

test_that("messages never show schema internals", {
  broken <- list(
    within(example_spec("process_7"), {
      design <- "moderated"
      goal$power <- "high"
    }),
    within(example_spec("anova_2x2_mixed"), {
      population$means <- list(1, 2, 3)
      population$r <- -2
      variables$B$type <- "between"
    }),
    within(example_spec("chi_square_independence"), {
      population$metric <- NULL
      options <- list(seed = 0)
    })
  )
  for (spec in broken) {
    err <- expect_error(validate_spec(spec), class = "powerkit_spec_error")
    text <- conditionMessage(err)
    expect_no_match(text, "#/|instancePath|schemaPath|must NOT|must match|NULL|character\\(0\\)")
  }
})
