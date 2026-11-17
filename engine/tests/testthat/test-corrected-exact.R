# Continuity-corrected two-proportion and 2 x 2 tests worked out exactly
# (backend-corrected-exact.R): the vectorised statistic against R's own
# tests on every table, and power against independent enumerations.

test_that("the vectorised corrected test gives prop.test()'s p-value on every table", {
  for (alternative in c("two.sided", "greater", "less")) {
    for (n in list(c(7, 12), c(25, 25), c(31, 18))) {
      grid <- expand.grid(x1 = 0:n[1], x2 = 0:n[2])
      reference <- mapply(function(a, b) suppressWarnings(stats::prop.test(c(a, b), n, correct = TRUE,
        alternative = alternative)$p.value), grid$x1, grid$x2)
      got <- corrected_prop_p(grid$x1, grid$x2, n[1], n[2], alternative)
      expect_identical(is.na(got), is.na(reference))
      expect_equal(got[!is.na(got)], reference[!is.na(reference)], tolerance = 1e-12)
      expect_identical(corrected_prop_reject(grid$x1, grid$x2, n[1], n[2], .05, alternative),
        !is.na(reference) & reference < .05)
    }
  }
})

test_that("it is chisq.test()'s corrected 2 x 2 test too", {
  for (x in list(c(3, 9, 8, 2), c(10, 10, 4, 16), c(0, 5, 6, 7))) {
    m <- matrix(x, 2, byrow = TRUE)
    reference <- suppressWarnings(stats::chisq.test(m, correct = TRUE)$p.value)
    expect_equal(corrected_prop_p(m[1, 1], m[2, 1], sum(m[1, ]), sum(m[2, ])), reference, tolerance = 1e-12)
  }
})

test_that("two-proportion power equals a table-by-table enumeration with prop.test()", {
  for (alternative in c("two.sided", "less")) {
    reference <- corrected_prop_reference(14, 21, .3, .7, alternative = alternative)
    expect_equal(corrected_prop_power(14, 21, .3, .7, .05, alternative), reference, tolerance = 1e-9)
  }
})

test_that("2 x 2 power equals an enumeration of every multinomial table with chisq.test()", {
  P <- matrix(c(.3, .2, .15, .35), 2, byrow = TRUE)
  n <- 24
  tables <- expand.grid(a = 0:n, b = 0:n, c = 0:n)
  tables <- tables[rowSums(tables) <= n, ]
  tables$d <- n - tables$a - tables$b - tables$c
  reference <- sum(apply(tables, 1, function(x) {
    p <- suppressWarnings(stats::chisq.test(matrix(x, 2, byrow = TRUE), correct = TRUE)$p.value)
    if (is.finite(p) && p < .05) stats::dmultinom(x, prob = as.vector(t(P))) else 0
  }))
  expect_equal(corrected_table_power(n, P, .05), reference, tolerance = 1e-9)
})

test_that("corrected tests are worked out exactly by default, and simulated on request", {
  for (name in c("two_proportions_corrected", "chi_square_independence_corrected")) {
    spec <- validate_spec(example_spec(name))
    expect_equal(basic_test_method(spec), "exact")
    expect_equal(route_spec(spec)$name, "stats")
    spec$options$method <- "simulation"
    expect_equal(route_spec(spec)$name, "Spower")
  }
  result <- run_spec(example_spec("two_proportions_corrected"))
  expect_equal(result$provenance$method, "exact")
  expect_equal(result$curve$power, corrected_prop_power(170, 170, .5, .65, .05), tolerance = 1e-12)
})

test_that("the sample size found is the smallest that reaches the target", {
  spec <- example_spec("two_proportions_corrected")
  spec$goal <- list(type = "sample_size", power = .8)
  spec$options$allocation_ratio <- 2
  result <- run_spec(spec)
  n <- result$n_required$n
  backend <- route_spec(validate_spec(spec))
  smaller <- seq(backend$exact_min_n, n - backend$n_step, by = backend$n_step)
  expect_gte(backend$exact_power(n), .8)
  expect_true(all(vapply(smaller, backend$exact_power, numeric(1)) < .8))
})

test_that("the 2 x 2 search's walk down finds what checking every smaller n finds", {
  for (P in list(list(list(.4, .1), list(.1, .4)), list(list(.25, .25), list(.15, .35)))) {
    spec <- example_spec("chi_square_independence_corrected")
    spec$population$probabilities <- P
    spec$goal <- list(type = "sample_size", power = .8)
    result <- run_spec(spec)
    backend <- route_spec(validate_spec(spec))
    every <- seq(backend$exact_min_n, result$n_required$n, by = backend$n_step)
    expect_equal(every[which(vapply(every, backend$exact_power, numeric(1)) >= .8)[1]], result$n_required$n)
  }
})

test_that("the standalone script reproduces the exact power and sample size with base R alone", {
  for (name in c("two_proportions_corrected", "chi_square_independence_corrected")) {
    spec <- example_spec(name)
    if (name == "two_proportions_corrected") spec$options$allocation_ratio <- 2
    for (goal in list(list(type = "power", n = 120), list(type = "sample_size", power = .8))) {
      spec$goal <- goal
      if (goal$type == "sample_size") {
        if (name == "two_proportions_corrected") { spec$population$p1 <- .3; spec$population$p2 <- .6 }
        else spec$population$probabilities <- list(list(.35, .15), list(.15, .35))
      }
      result <- run_spec(spec)
      lines <- export_script(spec, result)
      expect_false(any(grepl("library(Spower)", lines, fixed = TRUE)))
      env <- new.env(parent = globalenv())
      capture.output(eval(parse(text = lines), env))
      expect_equal(env$reproduced, env$powerkit_result, tolerance = 1e-10)
    }
  }
})
