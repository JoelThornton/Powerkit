# Snapshots of the full error text for typical mistakes, so the wording can
# be reviewed in one place: tests/testthat/_snaps/spec-messages.md

test_that("typical beginner mistakes read clearly", {
  spec <- example_spec("process_7")
  spec$effect_justification <- NULL
  spec$goal$power <- 80
  spec$design <- "moderated mediation"
  expect_snapshot(validate_spec(spec), error = TRUE)

  spec <- example_spec("independent_t")
  names(spec)[names(spec) == "target_test"] <- "target"
  spec$population$d <- "medium"
  expect_snapshot(validate_spec(spec), error = TRUE)
})

test_that("impossible populations read clearly", {
  spec <- example_spec("process_7")
  spec$population$paths[["X->M"]] <- 0.8
  spec$population$paths[["XW->M"]] <- 0.6
  expect_snapshot(validate_spec(spec), error = TRUE)

  spec <- example_spec("regression_interaction")
  spec$population$r_X_Y <- 0.8
  spec$population$r_W_Y <- 0.6
  expect_snapshot(validate_spec(spec), error = TRUE)

  spec <- example_spec("chi_square_independence")
  spec$population$probabilities[[3]] <- list(0.2, 0.2)
  expect_snapshot(validate_spec(spec), error = TRUE)
})

test_that("model-structure mistakes read clearly", {
  spec <- example_spec("mediation_parallel")
  spec$population$paths[["M1->M2"]] <- 0.2
  spec$population$paths[["X->Y"]] <- NULL
  spec$target_test$path <- "X->M1->M2->Y"
  expect_snapshot(validate_spec(spec), error = TRUE)

  spec <- example_spec("anova_2x2_between")
  spec$goal <- list(type = "power", n = 150)
  expect_snapshot(validate_spec(spec), error = TRUE)
})

test_that("file problems read clearly", {
  expect_snapshot(read_spec("my-study.json"), error = TRUE)
  expect_snapshot(read_spec("{'design': 'mediation'}"), error = TRUE)
})
