# Joint power for several outcomes of one randomised comparison
# (joint_power(), PUMP's pump_power()).

jp_spec <- function(name, d) {
  spec <- example_spec(name)
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
