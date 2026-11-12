test_that("a ratio typed as a rounded decimal is planned as the simplest whole split that rounds to it", {
  # 1.333 is exactly 1000 : 1333, which only multiples of 2333 can split
  # into whole groups; the plan uses 3 : 4.
  spec <- example_spec("independent_t")
  spec$options$allocation_ratio <- 1.333
  expect_equal(integer_allocation_step(c(1, 1.333)), 2333)
  expect_equal(allocation_ratio(spec), 4 / 3)
  expect_equal(valid_n_step(spec), 7)
  expect_true(group_split(spec)$valid(valid_n_step(spec)))
  expect_equal(analysed_groups(spec, 70), c(30, 40))
  expect_length(check_n(spec, 70), 0)
  expect_match(check_n(spec, 71), "70")
  expect_equal(planned_allocation(spec)[c("entered", "group1", "group2")], list(entered = 1.333, group1 = 3, group2 = 4))
  # 0.67, 0.33 and 1.37 as typed; the simplified ratio always rounds to the entry.
  for (case in list(c(0.67, 3, 2), c(0.33, 3, 1), c(1.37, 19, 26), c(0.6667, 3, 2))) {
    found <- simplified_allocation(case[1])
    expect_equal(found$parts, case[2:3], info = case[1])
    expect_equal(round(found$ratio, nchar(sub("^[^.]*\\.", "", format(case[1])))), case[1], info = case[1])
  }
  # Ratios whose exact split is already manageable are used as given.
  for (ratio in c(1, 2, 0.5, 1.5, 0.3, 0.35, 0.25, 3)) {
    expect_false(simplified_allocation(ratio)$simplified, info = ratio)
    expect_equal(simplified_allocation(ratio)$ratio, ratio)
  }
  spec$options$allocation_ratio <- 2
  expect_null(planned_allocation(spec))
})

test_that("a decimal ratio no longer inflates the two-group sample size", {
  # d = 0.5, 80% power, Student's test: about 133 with groups near 0.67 : 1;
  # the exact 67 : 100 split allowed only multiples of 167.
  spec <- example_spec("independent_t")
  spec$population$d <- 0.5
  spec$target_test$method <- "student_t"
  spec$goal <- list(type = "sample_size", power = 0.8)
  spec$options <- list(seed = 1, allocation_ratio = 0.67)
  result <- run_spec(spec)
  expect_equal(result$n_required$n, 135)
  expect_equal(result$allocation$group1, 3)
  expect_gte(pwr::pwr.t2n.test(n1 = 81, n2 = 54, d = 0.5)$power, 0.8)
  expect_lt(pwr::pwr.t2n.test(n1 = 78, n2 = 52, d = 0.5)$power, 0.8)
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
