# Joint power for several outcomes of one randomised comparison
# (joint_power(), PUMP's pump_power()).

jp_spec <- function(name, d) {
  spec <- example_spec(name)
  if (identical(name, "independent_t")) spec$target_test$method <- "student_t"
  spec$population$d <- d
  validate_spec(spec)
}

test_that("each outcome's power matches its own card, and uncorrelated outcomes multiply", {
  a <- jp_spec("independent_t", 0.4)
  b <- jp_spec("independent_t", 0.3)
  r0 <- joint_power(list(a, b), rho = 0, n = 266, tnum = 20000L)
  expect_equal(r0$each[[1]], pwr::pwr.t.test(n = 133, d = 0.4)$power, tolerance = 0.01)
  expect_equal(r0$each[[2]], pwr::pwr.t.test(n = 133, d = 0.3)$power, tolerance = 0.01)
  expect_equal(r0$complete, prod(r0$each), tolerance = 0.01)
  # Positively correlated outcomes are significant together more often.
  r5 <- joint_power(list(a, b), rho = 0.5, n = 266, tnum = 20000L)
  expect_gt(r5$complete, r0$complete)
  expect_lte(r5$complete, min(r5$each))
  expect_identical(r5$design, "d1.1_m1c")
  expect_identical(r5$provenance$backend, "PUMP")
  expect_identical(joint_power(list(a, b), rho = 0.5, n = 266, seed = 4L)$complete,
    joint_power(list(a, b), rho = 0.5, n = 266, seed = 4L)$complete)
})

test_that("a cluster-randomised trial matches powertools for each outcome", {
  c1 <- jp_spec("cluster_randomised", 0.3)
  r <- joint_power(list(c1, c1), rho = 0.5, n = 760, tnum = 20000L)
  at_n <- c1
  at_n$goal <- list(type = "power", n = 760)
  card <- run_spec(at_n)$curve$power
  expect_equal(r$each, rep(card, 2), tolerance = 0.01)
  expect_identical(r$design, "d2.2_m2rc")
  expect_error(joint_power(list(c1, c1), rho = 0.5, n = 765), "whole number of groups of 20", class = "powerkit_error")
})

test_that("designs PUMP doesn't cover are refused in plain English", {
  t1 <- jp_spec("independent_t", 0.4)
  expect_error(joint_power(list(t1, example_spec("correlation")), rho = 0.3, n = 200), "same two randomised groups", class = "powerkit_error")
  expect_error(joint_power(list(t1, jp_spec("cluster_randomised", 0.3)), rho = 0.3, n = 200), "same design", class = "powerkit_error")
  expect_error(joint_power(list(t1), rho = 0.3, n = 200), "two or more", class = "powerkit_error")
  expect_error(joint_power(list(t1, t1), rho = 1, n = 200), "between -1 and 1", class = "powerkit_error")
})

test_that("a multisite trial matches powertools for each outcome, with PUMP's shifted t", {
  ms <- jp_spec("multisite", 0.4)
  ms$population$icc <- 0.1
  ms$population$icc_effect <- 0.05
  at_n <- function(spec, n) {
    spec$goal <- list(type = "power", n = n)
    run_spec(spec)$curve$power
  }
  m <- ms$population$cluster_size
  # With many groups the shifted and the noncentral t agree.
  r <- joint_power(list(ms, ms), rho = 0, n = 40 * m, tnum = 50000L)
  expect_identical(r$design, "d2.1_m2fr")
  expect_equal(r$each, rep(at_n(ms, 40 * m), 2), tolerance = 0.01)
  expect_equal(r$complete, prod(r$each), tolerance = 0.01)
  # The noncentrality is multisite.cont()'s: PUMP's power equals the shifted
  # central t at that noncentrality (Known difference 14), here with a
  # baseline score and with no variation in the group means.
  for (case in list(list(icc = 0.1, r2 = 0), list(icc = 0.1, r2 = 0.25), list(icc = 0, r2 = 0))) {
    s <- ms
    s$population$icc <- case$icc
    if (case$r2 > 0) s$population$baseline_r2_within <- case$r2
    groups <- 10
    ncp <- 0.4 / sqrt(1 - case$r2) / sqrt(4 * (1 - case$icc + (m - 1) * 0.05) / (groups * m))
    crit <- stats::qt(0.975, groups - 1)
    shifted <- stats::pt(crit - ncp, groups - 1, lower.tail = FALSE) + stats::pt(-crit - ncp, groups - 1)
    noncentral <- stats::pt(crit, groups - 1, ncp, lower.tail = FALSE) + stats::pt(-crit, groups - 1, ncp)
    expect_equal(at_n(s, groups * m), noncentral, tolerance = 1e-6)
    r10 <- joint_power(list(s, s), rho = 0.3, n = groups * m, tnum = 50000L)
    expect_equal(r10$each, rep(shifted, 2), tolerance = 0.01, info = paste(case, collapse = "/"))
  }
  expect_error(joint_power(list(ms, ms), rho = 0.5, n = 10 * m + 1), "multisite trial, the sample size should be a whole number of groups", class = "powerkit_error")
})

test_that("Known difference 14: PUMP's power is a little below the card's with few groups", {
  ms <- jp_spec("multisite", 0.4)
  ms$population$icc <- 0.1
  ms$population$icc_effect <- 0.05
  m <- ms$population$cluster_size
  card <- function(groups) {
    spec <- ms
    spec$goal <- list(type = "power", n = groups * m)
    run_spec(spec)$curve$power
  }
  pump <- function(groups) joint_power(list(ms, ms), rho = 0, n = groups * m, tnum = 100000L)$each[[1]]
  gap_10 <- card(10) - pump(10)
  gap_20 <- card(20) - pump(20)
  expect_gt(gap_10, 0.015)
  expect_lt(gap_10, 0.04)
  expect_lt(abs(gap_20), 0.01)
})

test_that("joint power for nested designs refuses what PUMP's setup can't match", {
  ms <- jp_spec("multisite", 0.4)
  other <- ms
  other$population$icc_effect <- (ms$population$icc_effect %||% 0) + 0.02
  expect_error(joint_power(list(ms, other), rho = 0.3, n = 400), "same group size and intraclass correlations", class = "powerkit_error")
  base <- ms
  base$population$baseline_r2_within <- 0.3
  expect_error(joint_power(list(ms, base), rho = 0.3, n = 400), "baseline score's share", class = "powerkit_error")
  cr <- jp_spec("cluster_randomised", 0.3)
  cr$population$baseline_r2_within <- 0.3
  cr$population$baseline_r2_between <- 0.3
  expect_error(joint_power(list(cr, cr), rho = 0.3, n = 760), "without a baseline score", class = "powerkit_error")
})

test_that("groups of equal size given as an SD of 0 are accepted, and unequal sizes refused", {
  ms <- jp_spec("multisite", 0.4)
  ms$population$cluster_size_sd <- 0
  expect_identical(joint_power(list(ms, ms), rho = 0.3, n = 400, tnum = 2000L)$design, "d2.1_m2fr")
  ms$population$cluster_size_sd <- 5
  expect_error(joint_power(list(ms, ms), rho = 0.3, n = 400), "equal size only", class = "powerkit_error")
})

test_that("effects keep their signs: opposite effects of correlated outcomes are rarely significant together", {
  # Audit, 19 November 2026: +0.3 and -0.3 correlated 0.8 were given the
  # joint power of +0.3 and +0.3. A two-sided test of -0.3 is the test of
  # the reversed outcome at +0.3, whose correlation with the other is -0.8.
  a <- jp_spec("independent_t", 0.3)
  b <- jp_spec("independent_t", -0.3)
  opposite <- joint_power(list(a, b), rho = 0.8, n = 200, tnum = 50000L)
  same <- joint_power(list(a, a), rho = 0.8, n = 200, tnum = 50000L)
  reversed <- joint_power(list(a, a), rho = -0.8, n = 200, tnum = 50000L)
  expect_equal(opposite$each, same$each, tolerance = 0.01)
  expect_equal(opposite$complete, reversed$complete, tolerance = 0.005)
  expect_lt(opposite$complete, same$complete / 2)
  # Independent check: both statistics bivariate normal (large df, so the
  # t is near the normal), each test two-sided at 0.05.
  ncp <- 0.3 * sqrt(100 * 100 / 200)
  crit <- stats::qt(0.975, 198)
  both <- withr::with_seed(2, {
    z1 <- stats::rnorm(4e5)
    z2 <- 0.8 * z1 + sqrt(1 - 0.8^2) * stats::rnorm(4e5)
    function(m) mean(abs(z1 + m[1]) > crit & abs(z2 + m[2]) > crit)
  })
  expect_equal(opposite$complete, both(c(ncp, -ncp)), tolerance = 0.01)
  expect_equal(same$complete, both(c(ncp, ncp)), tolerance = 0.015)
})

test_that("an effect of 0 is kept, and one-sided tests face the tested direction", {
  a <- jp_spec("independent_t", 0.3)
  zero <- example_spec("independent_t")
  zero$target_test$method <- "student_t"
  zero$population$d <- 0
  zero$goal <- list(type = "power", n = 200)
  r <- joint_power(list(a, zero), rho = 0, n = 200, tnum = 50000L)
  expect_lt(abs(r$each[[2]] - 0.05), 0.005)
  expect_false(is.na(r$complete))
  expect_lt(abs(r$complete - prod(r$each)), 0.005)
  lower <- function(d) {
    s <- jp_spec("independent_t", d)
    s$target_test$alternative <- "less"
    s
  }
  down <- joint_power(list(lower(-0.3), lower(-0.4)), rho = 0.5, n = 200, tnum = 20000L)
  up <- joint_power(list(a, jp_spec("independent_t", 0.4)) |> lapply(function(s) {
    s$target_test$alternative <- "greater"
    s
  }), rho = 0.5, n = 200, tnum = 20000L)
  expect_equal(down$each, up$each, tolerance = 0.01)
  expect_equal(down$each[[1]], pwr::pwr.t.test(n = 100, d = 0.3, alternative = "greater")$power, tolerance = 0.01)
  expect_error(joint_power(list(lower(-0.3), lower(0.2)), rho = 0.5, n = 200),
    "tested direction", class = "powerkit_error")
})
