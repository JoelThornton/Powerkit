test_that("two groups in a ratio other than 1 are rounded to whole people at every total", {
  # Group 1 is n / (1 + ratio) rounded to the nearest person, a half up;
  # group 2 is the rest. Every total is valid.
  spec <- example_spec("independent_t")
  spec$options$allocation_ratio <- 1.333
  expect_equal(rounded_ratio(spec), 1.333)
  expect_equal(valid_n_step(spec), 1)
  expect_null(group_split(spec))
  expect_equal(analysed_groups(spec, 70), c(30, 40))
  expect_equal(analysed_groups(spec, 71), c(30, 41))
  expect_length(check_n(spec, 71), 0)
  expect_equal(planned_allocation(spec, 71)[c("entered", "group1", "group2", "exact")],
    list(entered = 1.333, group1 = 30, group2 = 41, exact = FALSE))
  # At a total, the plan uses that total's whole groups exactly.
  at <- spec_at_total(spec, 71)
  expect_equal(as.numeric(at$options$allocation_ratio), 41 / 30)
  expect_true(attr(at$options$allocation_ratio, "exact"))
  expect_null(rounded_ratio(at))
  expect_equal(valid_n_step(at), 71)
  # A half rounds up for group 1; a ratio met exactly says so.
  expect_equal(rounded_groups(10, 3), c(3, 7))
  spec$options$allocation_ratio <- 2
  expect_true(planned_allocation(spec, 300)$exact)
  # Equal groups keep their step of 2 and need no note.
  spec$options$allocation_ratio <- 1
  expect_null(rounded_ratio(spec))
  expect_null(planned_allocation(spec, 100))
  expect_equal(valid_n_step(spec), 2)
  # Neither group shrinks as the total grows, so power still rises with n.
  for (ratio in c(0.2, 0.67, 1.333, 1.5, 2, 3, 4.7)) {
    groups <- vapply(2:400, rounded_groups, numeric(2), ratio = ratio)
    expect_true(all(diff(groups[1, ]) >= 0) && all(diff(groups[2, ]) >= 0), info = ratio)
    expect_true(all(abs(groups[1, ] - (2:400) / (1 + ratio)) <= 0.5), info = ratio)
  }
})

test_that("the required total is the smallest whose rounded groups reach the target", {
  # d = 0.5, 80% power, Student's test, group 2 0.67 times group 1: power
  # from pwr::pwr.t2n.test() at every total's rounded groups, checked here
  # independently of the engine's search.
  spec <- example_spec("independent_t")
  spec$population$d <- 0.5
  spec$target_test$method <- "student_t"
  spec$goal <- list(type = "sample_size", power = 0.8)
  spec$options <- list(seed = 1, allocation_ratio = 0.67)
  result <- run_spec(spec)
  power_at <- function(n) {
    n1 <- floor(n / 1.67 + 0.5)
    pwr::pwr.t2n.test(n1 = n1, n2 = n - n1, d = 0.5)$power
  }
  brute <- (10:300)[vapply(10:300, power_at, numeric(1)) >= 0.8][1]
  expect_equal(result$n_required$n, brute)
  expect_equal(result$n_step, 1)
  expect_equal(c(result$allocation$group1, result$allocation$group2), c(floor(brute / 1.67 + 0.5), brute - floor(brute / 1.67 + 0.5)))
  expect_equal(result$curve$power[result$curve$n == brute], power_at(brute), tolerance = 1e-10)
  # The groups are recruited at that total.
  recruited <- spec_at_total(spec, brute)
  recruited$options$attrition <- 0.2
  expect_equal(recruitment_target(recruited, brute)$groups_analysed,
    c(result$allocation$group1, result$allocation$group2))
  expect_equal(analysed_groups(spec, brute), c(result$allocation$group1, result$allocation$group2))
  # Power at a total that the exact ratio could never split: 100 people.
  spec$goal <- list(type = "power", n = 100)
  expect_equal(run_spec(spec)$curve$power, power_at(100), tolerance = 1e-10)
})

test_that("integer allocation steps recover simple ratios", {
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

test_that("mediation and repeated outcomes recruit for the actual between-person groups", {
  for (name in c("mediation_binary_mediator", "mediation_ordinal_mediator", "mediation_binary_or_count_outcome")) {
    spec <- example_spec(name)
    spec$variables$X <- list(type = "binary", levels = c("First", "Second"))
    spec$options$attrition <- 0.1
    expect_equal(recruitment_target(spec, 80)$groups_recruit, c(45, 45), info = name)
    expect_equal(valid_n_step(spec), 2, info = name)
    spec$variables$X <- list(type = "continuous")
    expect_equal(recruitment_target(spec, 80)$groups_analysed, 80, info = name)
  }

  spec <- example_spec("repeated_glmm_interaction")
  spec$options$attrition <- 0.1
  groups <- length(spec$variables$W$levels)
  expect_equal(valid_n_step(spec), groups)
  expect_equal(recruitment_target(spec, 40 * groups)$groups_recruit, rep(45, groups))

  spec <- example_spec("repeated_glmm")
  spec$variables$X$type <- "between_factor"
  spec$options$attrition <- 0.1
  groups <- length(spec$variables$X$levels)
  expect_equal(valid_n_step(spec), groups)
  expect_equal(recruitment_target(spec, 40 * groups)$groups_recruit, rep(45, groups))
  spec$variables$X$type <- "within_factor"
  expect_equal(recruitment_target(spec, 40 * groups)$groups_analysed, 40 * groups)
})

test_that("portable recruitment code and the shared allocation agree for all example designs", {
  files <- list.files(system.file("specs", package = "powerkit"), pattern = "\\.json$", full.names = TRUE)
  for (file in files) {
    # Checking some specs calls their backend (a SEM's degrees of freedom),
    # which may be an optional package that isn't installed.
    spec <- tryCatch(
      withCallingHandlers(read_spec(file), powerkit_spec_warning = function(w) invokeRestart("muffleWarning")),
      powerkit_missing_package = function(e) NULL
    )
    if (is.null(spec) || !is.null(spec$kind)) next
    # Valid whole allocations, without running a power backend.
    layout <- sample_allocation(spec)
    n <- 4 * allocation_step(layout)
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
  spec$options$allocation_ratio <- NULL
  env <- new.env(parent = baseenv())
  env$n_analysed <- 11
  expect_error(eval(parse(text = analysed_groups_code(spec)), env), "whole group allocation")
})

test_that("a standalone script splits any total when the groups are rounded", {
  spec <- example_spec("noninf_independent")
  spec$options$allocation_ratio <- 0.67
  env <- new.env(parent = baseenv())
  env$n_analysed <- 101
  eval(parse(text = analysed_groups_code(spec)), env)
  expect_equal(env$groups_analysed, analysed_groups(spec, 101))
  expect_equal(env$groups_analysed, c(60, 41))
})

test_that("every design whose sample size moves in steps recruits group by group", {
  # A backend whose n moves in steps of k splits people into equal groups;
  # recruitment must then round up each group, not the total.
  specs <- list.files(system.file("specs", package = "powerkit"), "\\.json$", full.names = TRUE)
  ungrouped <- character()
  for (file in specs) {
    spec <- unclass(read_spec(file, validate = FALSE))
    backend <- tryCatch(route_backend(spec), error = function(e) NULL)
    step <- backend$n_step %||% 1
    if (is.numeric(step) && step > 1 && identical(sample_allocation(spec)$kind, "single")) {
      ungrouped <- c(ungrouped, basename(file))
    }
  }
  expect_identical(ungrouped, character())
})
