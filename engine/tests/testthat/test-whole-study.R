# Whole-study simulation (experimental): checks, translation to
# power4mome, and the joint power's bookkeeping. Accuracy against each
# analysis's own engine is checked, with many replications, in
# test-validation-whole-study-crosscheck.R.

whole_study_example <- function() {
  path <- system.file("whole-study", "example.json", package = "powerkit", mustWork = TRUE)
  jsonlite::fromJSON(path, simplifyVector = FALSE)
}

# A study with two regression analyses only: fast to simulate.
regression_study <- function(claim = "all", nrep = 100, seed = 11) {
  list(
    spec_version = "0.1", kind = "whole_study",
    variables = list(
      X = list(type = "continuous", label = "Workload"),
      W = list(type = "continuous", label = "Social support"),
      Y = list(type = "continuous", label = "Exhaustion")
    ),
    population = list(
      paths = list("X->Y" = 0.2, "W->Y" = -0.1, "XW->Y" = -0.15),
      correlations = list("X<->W" = -0.2)
    ),
    analyses = list(
      list(id = "compare", label = "Workload and exhaustion", test = "x_y", role = "main"),
      list(id = "moderation", label = "Depends on support", test = "interaction", role = "main")
    ),
    claim = claim, alpha = 0.05,
    effect_justification = list(type = "none"),
    goal = list(type = "power", n = 150),
    options = list(nrep = nrep, seed = seed)
  )
}

lines_of <- function(x) strsplit(x, "\n", fixed = TRUE)[[1]]

test_that("the example study is valid", {
  expect_s3_class(validate_whole_study(whole_study_example()), "powerkit_whole_study")
})

test_that("problems with a whole-study spec are reported in plain words", {
  spec <- whole_study_example()
  spec$population$paths[["X->M"]] <- NULL
  expect_error(validate_whole_study(spec), "Missing: X->M", class = "powerkit_spec_error")

  spec <- whole_study_example()
  spec$population$paths[["M->W"]] <- 0.1
  expect_error(validate_whole_study(spec), "aren't part of the model", class = "powerkit_spec_error")

  spec <- whole_study_example()
  spec$population$correlations <- NULL
  expect_error(validate_whole_study(spec), "Give the correlation X<->W", class = "powerkit_spec_error")

  spec <- whole_study_example()
  for (i in seq_along(spec$analyses)) spec$analyses[[i]]$role <- "extra"
  expect_error(validate_whole_study(spec), "at least one analysis as a main", class = "powerkit_spec_error")

  spec <- whole_study_example()
  spec$analyses[[3]] <- NULL
  expect_error(validate_whole_study(spec), "no analysis uses a moderator", class = "powerkit_spec_error")

  spec <- whole_study_example()
  spec$analyses[[2]]$path <- "X->M1->Y"
  expect_error(validate_whole_study(spec), "names a mediator that isn't", class = "powerkit_spec_error")

  spec <- whole_study_example()
  spec$analyses[[2]]$moderated_link <- "x_m"
  expect_error(validate_whole_study(spec), class = "powerkit_spec_error")

  spec <- whole_study_example()
  spec$population$paths[["X->M"]] <- 0.99
  spec$population$paths[["X->Y"]] <- 0.9
  spec$population$paths[["M->Y"]] <- 0.9
  expect_error(validate_whole_study(spec), "impossible together", class = "powerkit_spec_error")
})

test_that("a chain through both mediators needs serial mediators", {
  spec <- whole_study_example()
  spec$variables$M <- NULL
  spec$variables$M1 <- list(type = "continuous", label = "A")
  spec$variables$M2 <- list(type = "continuous", label = "B")
  spec$mediators <- "parallel"
  spec$population$paths <- list("X->M1" = 0.3, "X->M2" = 0.2, "M1->Y" = 0.2, "M2->Y" = 0.2,
    "X->Y" = 0.1, "W->Y" = 0, "XW->Y" = 0.1)
  spec$population$correlations[["M1<->M2"]] <- 0.2
  spec$analyses[[2]]$path <- "X->M1->M2->Y"
  expect_error(validate_whole_study(spec), "only a chain", class = "powerkit_spec_error")
  spec$analyses[[2]]$path <- "X->M1->Y"
  expect_s3_class(validate_whole_study(spec), "powerkit_whole_study")
})

test_that("the population model is the union of the analyses' models", {
  inputs <- whole_study_inputs(validate_whole_study(whole_study_example()))
  expect_equal(lines_of(inputs$model), c("M ~ X", "Y ~ X + M + W + X:W"))
  expect_setequal(lines_of(inputs$pop_es), c(
    "M ~ X: 0.3", "Y ~ X: 0.1", "Y ~ M: 0.3", "Y ~ W: -0.1", "Y ~ X:W: -0.15", "X ~~ W: -0.2"
  ))
  # Each analysis is fitted with its own model.
  expect_equal(
    vapply(inputs$analyses, function(a) a$fit_model, character(1)),
    c("Y ~ X", "M ~ X\nY ~ M + X", "Y ~ X + W + X:W")
  )
  expect_equal(names(inputs$fits), c("fit", "fit2", "fit3"))
  expect_equal(inputs$mains, c("compare", "mediation"))
})

test_that("moderated mediation adds its product term where W moderates", {
  spec <- whole_study_example()
  spec$analyses[[3]] <- list(id = "modmed", label = "Moderated mediation", test = "index_of_mome",
    moderated_link = "m_y", role = "extra")
  spec$analyses[[1]]$role <- "extra"
  spec$population$paths <- list("X->M" = 0.3, "M->Y" = 0.3, "X->Y" = 0.1, "W->Y" = -0.1, "MW->Y" = 0.1)
  inputs <- whole_study_inputs(validate_whole_study(spec))
  expect_equal(lines_of(inputs$model), c("M ~ X", "Y ~ X + M + W + M:W"))
  expect_equal(inputs$analyses[[3]]$fit_model, "M ~ X\nY ~ M + X + W + M:W")
  expect_equal(inputs$analyses[[3]]$test_fun, "test_index_of_mome")
})

test_that("under 'any' the main tests are at alpha divided by the number of mains", {
  spec <- whole_study_example()
  spec$claim <- "any"
  inputs <- whole_study_inputs(validate_whole_study(spec))
  levels <- vapply(inputs$analyses, function(a) a$test_args$level, numeric(1))
  expect_equal(levels, c(1 - 0.025, 1 - 0.025, 1 - 0.05))
  spec$claim <- "all"
  inputs <- whole_study_inputs(validate_whole_study(spec))
  expect_equal(vapply(inputs$analyses, function(a) a$test_args$level, numeric(1)), rep(0.95, 3))
})

test_that("the check run catches a path put in the wrong place", {
  spec <- validate_whole_study(regression_study())
  inputs <- whole_study_inputs(spec)
  big <- whole_study_big_sample(inputs, seed = 3)
  expect_true(all(whole_study_check_run(spec, inputs, big)$ok))
  wrong <- inputs
  wrong$pop_es <- sub("Y ~ X: 0.2", "Y ~ X: 0.1", inputs$pop_es, fixed = TRUE)
  check <- whole_study_check_run(spec, inputs, whole_study_big_sample(wrong, seed = 3))
  expect_false(all(check$ok))
  expect_true("X->Y" %in% check$parameter[!check$ok])
})

test_that("joint power is counted in the same replications as each analysis", {
  skip_on_cran()
  spec <- validate_whole_study(regression_study(nrep = 100))
  inputs <- whole_study_inputs(spec)
  counts <- whole_study_batch(inputs, 150, 100, 5)
  names(counts) <- rownames(whole_study_batch_template(inputs))
  # Both main tests are at the same alpha here, so in every replication
  # (both significant) + (at least one significant) counts each test's
  # significant results once: exactly, not only on average.
  expect_equal(counts[["joint_all:valid"]], 100)
  expect_equal(
    counts[["joint_all:sig"]] + counts[["joint_any:sig"]],
    counts[["compare:sig"]] + counts[["moderation:sig"]]
  )
  expect_lte(counts[["joint_all:sig"]], min(counts[["compare:sig"]], counts[["moderation:sig"]]))
  expect_gte(counts[["joint_any:sig"]], max(counts[["compare:sig"]], counts[["moderation:sig"]]))
})

test_that("a whole-study run reports each analysis, the joint power and its provenance", {
  skip_on_cran()
  result <- run_whole_study(regression_study(nrep = 100, seed = 11))
  expect_s3_class(result, "powerkit_whole_study_result")
  expect_equal(result$analyses$id, c("compare", "moderation"))
  expect_true(all(result$analyses$nrep == 100))
  expect_equal(result$joint$rule, "all")
  expect_lte(result$joint$power, min(result$analyses$power))
  expect_true(all(result$check_run$ok))
  expect_equal(result$provenance$backend, "power4mome")
  expect_equal(result$provenance$seed, 11)
  expect_true(all(c("powerkit", "power4mome") %in% names(result$provenance$packages)))
  expect_match(result$provenance$spec_hash, "^[0-9a-f]{64}$")
  # What the population implies for each analysis's own screen: the
  # correlation of X and Y is the direct path plus W's path times r(X, W).
  expect_equal(result$implied$compare$values[["r"]], 0.2 + (-0.1) * (-0.2), tolerance = 0.02)
  expect_equal(result$implied$moderation$values[["r_X_W"]], -0.2, tolerance = 0.02)

  again <- run_whole_study(regression_study(nrep = 100, seed = 11))
  expect_identical(again$analyses, result$analyses)

  any <- run_whole_study(regression_study(claim = "any", nrep = 100, seed = 11))
  expect_equal(any$joint$rule, "any")
  expect_equal(any$analyses$alpha, c(0.025, 0.025))
  expect_gte(any$joint$power, max(any$analyses$power))
})
