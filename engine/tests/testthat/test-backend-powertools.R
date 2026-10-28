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

# Multisite trials (powertools' multisite.cont()): people are randomised
# within each group, half to each condition.

multisite_spec <- function(goal, ...) {
  spec <- example_spec("multisite")
  spec$options <- list(seed = 7)
  spec$goal <- goal
  changes <- list(...)
  for (name in names(changes)) spec$population[[name]] <- changes[[name]]
  spec
}

test_that("a multisite trial runs on powertools' multisite.cont(), and passes its check run", {
  result <- run_spec(multisite_spec(list(type = "power", n = 400)))
  expect_equal(result$provenance$backend_function, "powertools::multisite.cont")
  expect_true(all(result$check_run$ok))
})

test_that("multisite power equals powertools::multisite.cont() called directly", {
  # 400 pupils: 20 schools of 20, 10 in each condition within each school.
  direct <- powertools::multisite.cont(
    m = 20, m.sd = 0, alloc.ratio = 1, J = 20, delta = 0.3, sd = 1,
    icc0 = 0.1, icc1 = 0.02, alpha = 0.05, sides = 2
  )
  expect_equal(run_spec(multisite_spec(list(type = "power", n = 400)))$curve$power, direct)
  direct_sd <- powertools::multisite.cont(
    m = 20, m.sd = 5, J = 20, delta = 0.3, icc0 = 0.1, icc1 = 0.02, sides = 2
  )
  expect_equal(run_spec(multisite_spec(list(type = "power", n = 400), cluster_size_sd = 5))$curve$power, direct_sd)
  spec <- multisite_spec(list(type = "power", n = 400), d = -0.3)
  spec$target_test$alternative <- "less"
  direct_one <- powertools::multisite.cont(m = 20, J = 20, delta = 0.3, icc0 = 0.1, icc1 = 0.02, sides = 1)
  expect_equal(run_spec(spec)$curve$power, direct_one)
})

test_that("multisite power agrees with the textbook variance and J - 1 degrees of freedom (pwrss)", {
  # Half of each group in each condition, no covariates, equal group
  # sizes: the variance of the average difference is
  # 4 * (1 - icc0 + (m - 1) * icc1) / N, and the t test has J - 1 df.
  m <- 20; icc0 <- 0.1; icc1 <- 0.02; d <- 0.3; groups <- 20
  ncp <- d / sqrt(4 * (1 - icc0 + (m - 1) * icc1) / (m * groups))
  expected <- pwrss::power.t.test(ncp = ncp, df = groups - 1, alpha = 0.05,
                                  alternative = "two.sided", plot = FALSE, verbose = 0)$power
  expect_equal(run_spec(multisite_spec(list(type = "power", n = m * groups)))$curve$power, expected, tolerance = 1e-8)
  # With no effect, power is alpha.
  expect_equal(run_spec(multisite_spec(list(type = "power", n = 400), d = 0))$curve$power, 0.05, tolerance = 1e-10)
})

test_that("a multisite trial needs fewer people than a cluster-randomised one with the same ICC", {
  multi <- run_spec(multisite_spec(list(type = "sample_size", power = 0.8)))
  cluster <- run_spec(cluster_spec(list(type = "sample_size", power = 0.8), icc = 0.1))
  expect_lt(multi$n_required$n, cluster$n_required$n)
})

test_that("the multisite n is a whole number of groups, and matches powertools' number of groups", {
  result <- run_spec(multisite_spec(list(type = "sample_size", power = 0.8)))
  n <- result$n_required$n
  expect_equal(n %% 20, 0)
  j <- powertools::multisite.cont(m = 20, J = NULL, delta = 0.3, icc0 = 0.1, icc1 = 0.02, power = 0.8)
  expect_equal(n, ceiling(j) * 20)
  s <- result$clusters
  expect_identical(s$assignment, "people")
  expect_true(is.na(s$clusters_per_condition))
  expect_equal(s$icc_effect, 0.02)
  expect_equal(s$design_effect, 1 - 0.1 + 19 * 0.02)
  expect_equal(s$effective_n, n / s$design_effect)
  expect_identical(run_spec(cluster_spec(list(type = "power", n = 400)))$clusters$assignment, "groups")
})

test_that("the multisite smallest detectable effect equals powertools' own answer", {
  result <- run_spec(multisite_spec(list(type = "sensitivity", n = 400, power = 0.8)))
  direct <- powertools::multisite.cont(m = 20, J = 20, delta = NULL, icc0 = 0.1, icc1 = 0.02, power = 0.8)
  expect_equal(result$sensitivity$effect, direct)
})

test_that("multisite spec checks", {
  expect_spec_problem(multisite_spec(list(type = "power", n = 410)), "whole number of groups of 20")
  expect_spec_problem(multisite_spec(list(type = "power", n = 20)), "at least 40 participants")
  spec <- multisite_spec(list(type = "power", n = 400))
  spec$population$icc_effect <- NULL
  expect_spec_problem(spec, "icc_effect")
  spec <- cluster_spec(list(type = "power", n = 400))
  spec$population$icc_effect <- 0.02
  expect_spec_problem(spec, "icc_effect")
})

test_that("the exported multisite script reproduces each goal with powertools alone", {
  specs <- list(
    multisite_spec(list(type = "power", n = 400)),
    multisite_spec(list(type = "sample_size", power = 0.8), cluster_size_sd = 4),
    multisite_spec(list(type = "sensitivity", n = 400, power = 0.9))
  )
  specs[[2]]$options$attrition <- 0.1
  for (spec in specs) {
    result <- run_spec(spec)
    out <- run_exported_script(spec, result)
    expect_equal(out$reproduced, out$powerkit, tolerance = 1e-10, info = spec$goal$type)
  }
})

# Yes/no outcomes (powertools' crt.parallel.bin() and multisite.bin()).

binary_spec <- function(name, goal, ...) {
  spec <- example_spec(name)
  spec$options <- list(seed = 7)
  spec$goal <- goal
  changes <- list(...)
  for (field in names(changes)) spec$population[[field]] <- changes[[field]]
  spec
}

test_that("yes/no outcomes run on powertools' .bin() functions and pass their check run", {
  r1 <- run_spec(binary_spec("cluster_randomised_binary", list(type = "power", n = 800)))
  expect_equal(r1$provenance$backend_function, "powertools::crt.parallel.bin")
  expect_true(all(r1$check_run$ok))
  r2 <- run_spec(binary_spec("multisite_binary", list(type = "power", n = 400)))
  expect_equal(r2$provenance$backend_function, "powertools::multisite.bin")
  expect_true(all(r2$check_run$ok))
})

test_that("yes/no power equals powertools called directly", {
  # 800 pupils: 40 classes of 20 (J is the total number of groups).
  direct <- powertools::crt.parallel.bin(m = 20, m.sd = 0, J = 40, pc = 0.3, pt = 0.45, sigma.u = 0.3, alpha = 0.05, sides = 2)
  expect_equal(run_spec(binary_spec("cluster_randomised_binary", list(type = "power", n = 800)))$curve$power, direct)
  direct_ms <- powertools::multisite.bin(m = 20, alloc.ratio = 1, J = 20, pc = 0.3, pt = 0.45, sigma.u = 0.3, alpha = 0.05, sides = 2)
  expect_equal(run_spec(binary_spec("multisite_binary", list(type = "power", n = 400)))$curve$power, direct_ms)
  # One-sided, and a decrease tested one-sided "less" in the same direction.
  spec <- binary_spec("cluster_randomised_binary", list(type = "power", n = 800), p1 = 0.45, p2 = 0.3)
  spec$target_test$alternative <- "less"
  direct_one <- powertools::crt.parallel.bin(m = 20, J = 40, pc = 0.45, pt = 0.3, sigma.u = 0.3, sides = 1)
  expect_equal(run_spec(spec)$curve$power, direct_one)
  spec$target_test$alternative <- "greater"
  expect_spec_problem(spec, "goes the other way")
})

test_that("the yes/no sample size is a whole number of groups and matches powertools' number of groups", {
  r <- run_spec(binary_spec("cluster_randomised_binary", list(type = "sample_size", power = 0.8)))
  j <- powertools::crt.parallel.bin(m = 20, J = NULL, pc = 0.3, pt = 0.45, sigma.u = 0.3, power = 0.8)
  # The same number of groups in each condition: J rounded up to even.
  expect_equal(r$n_required$n, 2 * ceiling(j / 2) * 20)
  expect_identical(r$clusters$outcome, "yes/no")
  expect_true(is.na(r$clusters$design_effect))
  r2 <- run_spec(binary_spec("multisite_binary", list(type = "sample_size", power = 0.8)))
  j2 <- powertools::multisite.bin(m = 20, J = NULL, pc = 0.3, pt = 0.45, sigma.u = 0.3, power = 0.8)
  expect_equal(r2$n_required$n, ceiling(j2) * 20)
})

test_that("yes/no spec checks: equal group sizes, no smallest detectable effect, the right fields", {
  expect_spec_problem(binary_spec("cluster_randomised_binary", list(type = "power", n = 800), cluster_size_sd = 3), "same size only")
  expect_spec_problem(binary_spec("cluster_randomised_binary", list(type = "sample_size", power = 0.8), p2 = 0.3), "zero")
  expect_error(run_spec(binary_spec("cluster_randomised_binary", list(type = "sensitivity", n = 800, power = 0.8))), "isn't available yet")
  spec <- binary_spec("multisite_binary", list(type = "power", n = 400))
  spec$population$icc <- 0.1
  expect_error(validate_spec(spec), class = "powerkit_spec_error")
  spec <- binary_spec("multisite_binary", list(type = "power", n = 400))
  spec$variables$Y$type <- "continuous"
  expect_error(validate_spec(spec), class = "powerkit_spec_error")
})

test_that("the exported yes/no scripts reproduce the result with powertools alone", {
  specs <- list(
    binary_spec("cluster_randomised_binary", list(type = "power", n = 800)),
    binary_spec("multisite_binary", list(type = "sample_size", power = 0.8))
  )
  for (spec in specs) {
    result <- run_spec(spec)
    out <- run_exported_script(spec, result)
    expect_equal(out$reproduced, out$powerkit, tolerance = 1e-10, info = spec$template)
  }
})
