test_that("allocation periods use the intended integer weights beyond the old scan limit", {
  spec <- example_spec("independent_t")
  spec$options$allocation_ratio <- 1.333
  expect_equal(valid_n_step(spec), 2333)
  expect_true(group_split(spec)$valid(valid_n_step(spec)))
  expect_equal(analysed_groups(spec, 2333), c(1000, 1333))
  expect_length(check_n(spec, 2333), 0)
  expect_match(check_n(spec, 2332), "2333|2,333")
  expect_equal(integer_allocation_step(c(1, 1 / 3)), 4)
  expect_equal(integer_allocation_step(c(0.1, 0.2, 0.3)), 6)
  for (w in list(c(2, 3), c(3, 4), c(2, 3, 5), c(1000, 1333))) {
    expect_equal(integer_allocation_step(w), sum(w))
  }
})

test_that("grouped recruitment rounds each group for previously omitted designs", {
  for (name in c("noninf_independent", "noninf_two_proportions", "tost_two_proportions")) {
    spec <- example_spec(name)
    spec$options$attrition <- 0.2
    spec$options$allocation_ratio <- NULL
    result <- recruitment_target(spec, 10)
    expect_equal(result$groups_analysed, c(5, 5), info = name)
    expect_equal(result$groups_recruit, c(7, 7), info = name)
    expect_equal(result$n_recruit, 14, info = name)
    expect_equal(result$unit, "group", info = name)
  }
  spec <- example_spec("noninf_independent")
  spec$options$allocation_ratio <- 2
  spec$options$attrition <- 0.2
  expect_equal(recruitment_target(spec, 15)$groups_recruit, c(7, 13))
})

test_that("invariance, MANOVA and nested recruitment retain their group structure", {
  spec <- example_spec("sem_invariance")
  spec$options$attrition <- 0.2
  expect_equal(recruitment_target(spec, 10)$n_recruit, 14)
  spec$population$n_groups <- 3
  expect_equal(recruitment_target(spec, 15)$groups_recruit, c(7, 7, 7))
  spec$population$over <- "occasions"
  expect_equal(analysed_groups(spec, 15), 15)

  spec <- example_spec("manova")
  spec$options$attrition <- 0.2
  k <- length(spec$variables$A$levels)
  expect_equal(recruitment_target(spec, k * 5)$n_recruit, k * 7)
  spec <- example_spec("mixed_two_level")
  spec$options$attrition <- 0.2
  m <- spec$population$cluster_size
  expect_equal(recruitment_target(spec, 4 * m)$groups_recruit, rep(ceiling(m / 0.8), 4))
})

test_that("portable recruitment code and the shared allocation agree for all example designs", {
  files <- list.files(system.file("specs", package = "powerkit"), pattern = "\\.json$", full.names = TRUE)
  for (file in files) {
    spec <- withCallingHandlers(read_spec(file), powerkit_spec_warning = function(w) invokeRestart("muffleWarning"))
    if (!is.null(spec$kind)) next
    # Valid whole allocations, without running a power backend.
    layout <- sample_allocation(spec)
    step <- if (layout$kind == "weights") integer_allocation_step(layout$weights) else layout$step %||% 1
    n <- 4 * step
    env <- new.env(parent = baseenv())
    env$n_analysed <- n
    env$group_ratio <- group_ratio_vector(spec)
    eval(parse(text = analysed_groups_code(spec)), envir = env)
    expect_equal(env$groups_analysed, analysed_groups(spec, n), info = basename(file))
    expect_equal(sum(env$groups_analysed), n, info = basename(file))
  }
})

test_that("a standalone script rejects an edited sample size that breaks allocation", {
  spec <- example_spec("noninf_independent")
  env <- new.env(parent = baseenv())
  env$n_analysed <- 11
  expect_error(eval(parse(text = analysed_groups_code(spec)), env), "whole group allocation")
})
