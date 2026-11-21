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
  occasions <- example_spec("mixed_two_level")
  occasions$goal$unit <- "observations"
  diary <- sample_structure(occasions)
  expect_identical(diary$unit, "observations")
  expect_match(diary$note, "N counts observations, with each person measured on", fixed = TRUE)
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

test_that("analyses of the same groups on different outcomes and cards share one count", {
  t_test <- example_spec("independent_t")
  proportions <- example_spec("two_proportions")
  proportions$variables$X <- t_test$variables$X
  proportions$options$attrition <- t_test$options$attrition
  expect_identical(sample_structure(t_test)$compatibility_key, sample_structure(proportions)$compatibility_key)
  proportions$options$allocation_ratio <- 2
  expect_false(identical(sample_structure(t_test)$compatibility_key, sample_structure(proportions)$compatibility_key))
  expect_false(identical(sample_structure(t_test)$compatibility_key, sample_structure(example_spec("correlation"))$compatibility_key))
  paired <- example_spec("paired_t")
  mcnemar <- example_spec("mcnemar")
  mcnemar$variables$X <- paired$variables$X
  mcnemar$options$attrition <- paired$options$attrition
  expect_identical(sample_structure(paired)$compatibility_key, sample_structure(mcnemar)$compatibility_key)
})

test_that("with n, the groups are the ones the engine runs, labelled in its order", {
  unequal <- example_spec("anova_2x2_between_unequal")
  d <- sample_structure(unequal, 120)
  expect_equal(d$groups, 120 * cell_ratio_vector(unequal) / sum(cell_ratio_vector(unequal)))
  expect_equal(d$groups, superpower_cell_n(list(cell_ratio = cell_ratio_vector(unequal)), 120))
  expect_identical(d$group_unit, "cell")
  a <- unlist(unequal$variables$A$levels)
  b <- unlist(unequal$variables$B$levels)
  expect_identical(d$group_labels, c(paste(a[1], b[1], sep = ", "), paste(a[1], b[2], sep = ", "),
    paste(a[2], b[1], sep = ", "), paste(a[2], b[2], sep = ", ")))
  # One group of people, or pairs: no split.
  expect_null(sample_structure(example_spec("paired_t"), 40)$groups)
  expect_null(sample_structure(example_spec("dyadic_apim"), 150)$groups)
  # Without n, as before.
  expect_null(sample_structure(unequal)$groups)
})
