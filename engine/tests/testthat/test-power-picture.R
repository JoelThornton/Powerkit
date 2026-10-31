# The Labs picture of power: pwr's power for a two-group t-test, base R's
# t densities, the critical t and the smallest significant d.

test_that("the picture's numbers are pwr's and base R's", {
  picture <- power_picture(64, 0.5, alpha = 0.05)
  expect_equal(picture$power, pwr::pwr.t.test(n = 32, d = 0.5, sig.level = 0.05)$power)
  expect_equal(picture$power, stats::power.t.test(n = 32, delta = 0.5, sd = 1, sig.level = 0.05, strict = TRUE)$power, tolerance = 1e-6)
  expect_equal(picture$beta, 1 - picture$power)
  expect_equal(picture$df, 62)
  expect_equal(picture$ncp, 0.5 * sqrt(16))
  expect_equal(picture$t_crit, stats::qt(0.975, 62))
  # The smallest significant d gives an observed t exactly at the critical
  # value (t = d sqrt(n1 n2 / (n1 + n2))).
  expect_equal(picture$d_crit * sqrt(32 * 32 / 64), picture$t_crit)
  expect_identical(picture$package$name, "pwr")
})

test_that("the curves are the central and noncentral t densities over both critical values", {
  picture <- power_picture(40, 0.8, alpha = 0.01)
  curves <- picture$curves
  expect_equal(curves$null, stats::dt(curves$t, 38))
  expect_equal(curves$alternative, stats::dt(curves$t, 38, ncp = picture$ncp))
  expect_lt(min(curves$t), -picture$t_crit)
  expect_gt(max(curves$t), picture$ncp + 3)
  # Each curve holds nearly all of its distribution.
  step <- diff(curves$t)[1]
  expect_gt(sum(curves$null) * step, 0.99)
  expect_gt(sum(curves$alternative) * step, 0.99)
  # No effect: power is alpha.
  expect_equal(power_picture(40, 0, alpha = 0.01)$power, 0.01, tolerance = 1e-8)
})

test_that("impossible inputs are refused in plain words", {
  expect_error(power_picture(31, 0.5), "even number of participants", class = "powerkit_error")
  expect_error(power_picture(64, -0.2), "of 0 or more", class = "powerkit_error")
  expect_error(power_picture(64, 0.5, alpha = 0.7), "between 0 and 0.5", class = "powerkit_error")
})
