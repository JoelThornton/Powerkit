test_that("sample counts distinguish people, dyads, items and studies", {
  expect_identical(sample_structure(example_spec("independent_t"))$unit, "participants")
  expect_identical(sample_structure(example_spec("paired_t"))$unit, "participants")
  expect_identical(sample_structure(example_spec("dyadic_apim"))$unit, "pairs")
  expect_identical(sample_structure(example_spec("meta_mean_effect"))$unit, "studies")
  spec <- example_spec("crossed_two_condition")
  spec$goal$unit <- "items"
  expect_identical(sample_structure(spec)$unit, "items")
  cluster <- sample_structure(example_spec("cluster_randomised"))
  expect_identical(cluster$unit, "participants")
  expect_match(cluster$note, "N counts participants", fixed = TRUE)
})

test_that("study counts retain participant and measurement structure within studies", {
  first <- example_spec("meta_mean_effect")
  second <- first
  second$population$effect <- 0.4
  expect_identical(sample_structure(first)$compatibility_key, sample_structure(second)$compatibility_key)
  second$population$study_size <- 100
  expect_false(identical(sample_structure(first)$compatibility_key, sample_structure(second)$compatibility_key))
  first <- example_spec("meta_dependent_effects")
  second <- first
  second$population$effects_per_study <- 2
  expect_false(identical(sample_structure(first)$compatibility_key, sample_structure(second)$compatibility_key))
})

test_that("a common count requires matching allocation, grouping and measurement structure", {
  first <- example_spec("independent_t")
  second <- first
  second$population$d <- 0.8
  second$variables$Y$label <- "Another outcome"
  expect_identical(sample_structure(first)$compatibility_key, sample_structure(second)$compatibility_key)
  second$options$allocation_ratio <- 2
  expect_false(identical(sample_structure(first)$compatibility_key, sample_structure(second)$compatibility_key))
  second <- first
  second$options$attrition <- 0.5
  expect_false(identical(sample_structure(first)$compatibility_key, sample_structure(second)$compatibility_key))
  second <- first
  second$variables$X$levels <- list("One grouping", "Another grouping")
  expect_false(identical(sample_structure(first)$compatibility_key, sample_structure(second)$compatibility_key))
  paired <- example_spec("paired_t")
  expect_false(identical(sample_structure(first)$compatibility_key, sample_structure(paired)$compatibility_key))
})
