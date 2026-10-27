# Cluster-randomised trials by formula (powertools' crt.parallel.cont()):
# the translation is checked against powertools called directly with the
# arguments written out by hand, and against the textbook design-effect
# calculation done with a second package (pwrss's generic t test).

cluster_spec <- function(goal, ...) {
  spec <- example_spec("cluster_randomised")
  spec$options <- list(seed = 7)
  spec$goal <- goal
  changes <- list(...)
  for (name in names(changes)) spec$population[[name]] <- changes[[name]]
  spec
}

test_that("a cluster-randomised trial runs on powertools, exactly, and passes its check run", {
  result <- run_spec(cluster_spec(list(type = "power", n = 400)))
  expect_equal(result$provenance$backend, "powertools")
  expect_equal(result$provenance$backend_function, "powertools::crt.parallel.cont")
  expect_equal(result$provenance$method, "exact")
  expect_true(all(result$check_run$ok))
  expect_true("powertools" %in% names(result$provenance$packages))
})

test_that("power equals powertools::crt.parallel.cont() called directly", {
  # 400 pupils: 20 classes of 20, 10 classes in each condition.
  direct <- powertools::crt.parallel.cont(
    m = 20, m.sd = 0, J1 = 10, J.ratio = 1, delta = 0.3, sd = 1,
    icc1 = 0.05, icc2 = 0.05, alpha = 0.05, sides = 2
  )
  expect_equal(run_spec(cluster_spec(list(type = "power", n = 400)))$curve$power, direct)
  # Classes of different sizes: 20 on average, SD 5.
  direct_sd <- powertools::crt.parallel.cont(
    m = 20, m.sd = 5, J1 = 10, J.ratio = 1, delta = 0.3, sd = 1,
    icc1 = 0.05, icc2 = 0.05, alpha = 0.05, sides = 2
  )
  spec <- cluster_spec(list(type = "power", n = 400), cluster_size_sd = 5)
  expect_equal(run_spec(spec)$curve$power, direct_sd)
  expect_lt(direct_sd, direct)
  # One-sided, in the direction of the effect.
  spec <- cluster_spec(list(type = "power", n = 400))
  spec$target_test$alternative <- "greater"
  direct_one <- powertools::crt.parallel.cont(
    m = 20, m.sd = 0, J1 = 10, J.ratio = 1, delta = 0.3, sd = 1,
    icc1 = 0.05, icc2 = 0.05, alpha = 0.05, sides = 1
  )
  expect_equal(run_spec(spec)$curve$power, direct_one)
  # A negative d tested one-sided "less" has the same power.
  spec <- cluster_spec(list(type = "power", n = 400), d = -0.3)
  spec$target_test$alternative <- "less"
  expect_equal(run_spec(spec)$curve$power, direct_one)
  spec$target_test$alternative <- "greater"
  expect_spec_problem(spec, "goes the other way")
})

test_that("power agrees with the design effect and the number of groups' degrees of freedom (pwrss)", {
  # The textbook calculation (no covariates, equal group sizes): the
  # variance of the difference is inflated by 1 + (m - 1) * ICC, and the
  # t test has J - 2 degrees of freedom. Checked with pwrss's generic
  # t test, a second package.
  m <- 20; icc <- 0.05; d <- 0.3; groups <- 20
  n_arm <- m * groups / 2
  ncp <- d / sqrt((1 + (m - 1) * icc) * (2 / n_arm))
  expected <- pwrss::power.t.test(ncp = ncp, df = groups - 2, alpha = 0.05,
                                  alternative = "two.sided", plot = FALSE, verbose = 0)$power
  expect_equal(run_spec(cluster_spec(list(type = "power", n = m * groups)))$curve$power, expected, tolerance = 1e-8)
})

test_that("with no effect, power is alpha", {
  result <- run_spec(cluster_spec(list(type = "power", n = 400), d = 0))
  expect_equal(result$curve$power, 0.05, tolerance = 1e-10)
})

test_that("the required n is a whole number of groups, the same in each condition", {
  result <- run_spec(cluster_spec(list(type = "sample_size", power = 0.8)))
  n <- result$n_required$n
  expect_equal(n %% 40, 0)
  powers <- result$curve$power[match(c(n - 40, n), result$curve$n)]
  expect_lt(powers[1], 0.8)
  expect_gte(powers[2], 0.8)
  # The same as powertools' own answer for the groups per condition,
  # rounded up.
  j1 <- powertools::crt.parallel.cont(
    m = 20, J1 = NULL, delta = 0.3, icc1 = 0.05, icc2 = 0.05, power = 0.8
  )
  expect_equal(n, ceiling(j1) * 2 * 20)
  expect_equal(result$clusters$clusters_per_condition, ceiling(j1))
})

test_that("the result reports the groups, the design effect and the effective sample size", {
  result <- run_spec(cluster_spec(list(type = "power", n = 400)))
  s <- result$clusters
  expect_equal(s$clusters, 20)
  expect_equal(s$clusters_per_condition, 10)
  expect_equal(s$design_effect, 1 + 19 * 0.05)
  expect_equal(s$effective_n, 400 / 1.95)
  expect_equal(s$relative_efficiency, 1)
  s_sd <- run_spec(cluster_spec(list(type = "power", n = 400), cluster_size_sd = 5))$clusters
  expect_equal(s_sd$relative_efficiency, powertools::re.clustsize.cont(m = 20, m.sd = 5, icc = 0.05))
  expect_gt(s_sd$design_effect, s$design_effect)
  expect_null(run_spec(read_spec(example_path("independent_t")))$clusters)
})

test_that("the smallest detectable effect equals powertools' own answer", {
  result <- run_spec(cluster_spec(list(type = "sensitivity", n = 400, power = 0.8)))
  direct <- powertools::crt.parallel.cont(
    m = 20, J1 = 10, delta = NULL, icc1 = 0.05, icc2 = 0.05, power = 0.8
  )
  expect_equal(result$sensitivity$effect, direct)
  expect_equal(result$sensitivity$power, 0.8, tolerance = 1e-4)
  # No effect size is needed; a negative d keeps its sign.
  expect_gt(run_spec(cluster_spec(list(type = "sensitivity", n = 400, power = 0.8), d = 0))$sensitivity$effect, 0)
  expect_lt(run_spec(cluster_spec(list(type = "sensitivity", n = 400, power = 0.8), d = -0.2))$sensitivity$effect, 0)
})

test_that("the spec checks refuse what powertools can't compute", {
  expect_spec_problem(cluster_spec(list(type = "power", n = 410)), "whole number of groups of 20")
  expect_spec_problem(cluster_spec(list(type = "power", n = 40)), "at least 80 participants")
  expect_spec_problem(cluster_spec(list(type = "sample_size", power = 0.8), d = 0), "zero")
  expect_spec_problem(cluster_spec(list(type = "power", n = 400), cluster_size_sd = 60), "too large")
  spec <- cluster_spec(list(type = "power", n = 400))
  spec$options$method <- "simulation"
  expect_spec_problem(spec, "isn't available for this test")
  spec <- cluster_spec(list(type = "power", n = 400))
  spec$options$allocation_ratio <- 2
  expect_spec_problem(spec, "allocation_ratio")
  spec <- cluster_spec(list(type = "power", n = 400), icc = 1)
  expect_error(validate_spec(spec), class = "powerkit_spec_error")
})

test_that("attrition is allowed for in every group", {
  result <- run_spec(cluster_spec(list(type = "power", n = 400)))
  spec <- cluster_spec(list(type = "power", n = 400))
  spec$options$attrition <- 0.1
  r <- run_spec(spec)$recruitment
  expect_equal(r$groups_recruit, rep(23, 20))
  expect_equal(r$n_recruit, 460)
  expect_equal(r$unit, "cluster")
})

test_that("the exported script reproduces each goal with powertools alone", {
  attrition <- cluster_spec(list(type = "power", n = 400))
  attrition$options$attrition <- 0.1
  specs <- list(
    cluster_spec(list(type = "power", n = 400)),
    cluster_spec(list(type = "sample_size", power = 0.8), cluster_size_sd = 5),
    cluster_spec(list(type = "sensitivity", n = 400, power = 0.9), d = -0.2),
    attrition
  )
  specs[[2]]$target_test$alternative <- "greater"
  for (spec in specs) {
    result <- run_spec(spec)
    out <- run_exported_script(spec, result)
    expect_equal(out$reproduced, out$powerkit, tolerance = 1e-10, info = spec$goal$type)
  }
})
